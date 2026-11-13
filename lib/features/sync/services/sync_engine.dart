import 'dart:async';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/utils/app_log.dart';
import '../../jobs/data/job_local_datasource.dart';
import '../../jobs/data/job_remote_datasource.dart';
import '../models/sync_queue_item.dart';
import 'conflict_resolver.dart';

class SyncStatusState {
  final bool isSyncing;
  final int pendingCount;
  final DateTime? lastSyncTime;
  final String? lastError;
  final String? conflictNotice;

  const SyncStatusState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.lastSyncTime,
    this.lastError,
    this.conflictNotice,
  });

  SyncStatusState copyWith({
    bool? isSyncing,
    int? pendingCount,
    DateTime? lastSyncTime,
    String? lastError,
    String? conflictNotice,
  }) {
    return SyncStatusState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError,
      conflictNotice: conflictNotice,
    );
  }
}

class SyncEngine {
  final AppDatabase _dbManager;
  final JobLocalDataSource _localDataSource;
  final JobRemoteDataSource _remoteDataSource;
  final ConflictResolver _conflictResolver;
  final ConnectivityService _connectivityService;

  final StreamController<SyncStatusState> _statusController =
      StreamController<SyncStatusState>.broadcast();

  SyncStatusState _currentState = const SyncStatusState();
  StreamSubscription? _connectivitySubscription;
  bool _isProcessing = false;

  SyncEngine({
    AppDatabase? dbManager,
    JobLocalDataSource? localDataSource,
    JobRemoteDataSource? remoteDataSource,
    ConflictResolver? conflictResolver,
    ConnectivityService? connectivityService,
  })  : _dbManager = dbManager ?? AppDatabase.instance,
        _localDataSource = localDataSource ?? JobLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? JobRemoteDataSource(),
        _conflictResolver = conflictResolver ?? ConflictResolver(),
        _connectivityService = connectivityService ?? ConnectivityService() {
    _init();
  }

  Stream<SyncStatusState> get statusStream => _statusController.stream;
  SyncStatusState get currentState => _currentState;

  void _init() {
    refreshPendingCount();

    // Auto-sync whenever network connectivity returns
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (isOnline) {
        processQueue();
      }
    });
  }

  Future<void> refreshPendingCount() async {
    final count = await _dbManager.getPendingSyncCount();
    _updateState(_currentState.copyWith(pendingCount: count));
  }

  void _updateState(SyncStatusState state) {
    _currentState = state;
    _statusController.add(_currentState);
  }

  /// Process the durable SQLite sync queue in FIFO order
  Future<void> processQueue() async {
    if (_isProcessing) {
      AppLog.d('SyncEngine', 'Sync already in progress, skipping duplicate cycle.');
      return;
    }
    _isProcessing = true;
    AppLog.i('SyncEngine', 'Starting durable queue processing...');
    _updateState(_currentState.copyWith(isSyncing: true, lastError: null));

    try {
      final db = await _dbManager.database;

      // 1. Fetch pending mutations in chronological order
      final List<Map<String, dynamic>> rows = await db.query(
        DbTables.syncQueue,
        where: '${SyncQueueColumns.status} = ?',
        whereArgs: ['pending'],
        orderBy: '${SyncQueueColumns.createdAt} ASC',
      );

      AppLog.d('SyncEngine', 'Found ${rows.length} pending mutations in queue.');

      for (final row in rows) {
        final item = SyncQueueItem.fromMap(row);
        AppLog.d('SyncEngine', 'Processing mutation: ${item.actionType} for job ${item.jobId}');

        // Mark item in_flight
        await db.update(
          DbTables.syncQueue,
          {SyncQueueColumns.status: 'in_flight'},
          where: '${SyncQueueColumns.id} = ?',
          whereArgs: [item.id],
        );

        final result = await _remoteDataSource.pushMutation(item);

        if (result.isSuccess) {
          // Mutation succeeded on server:
          // Remove from queue and mark job synced
          await db.delete(
            DbTables.syncQueue,
            where: '${SyncQueueColumns.id} = ?',
            whereArgs: [item.id],
          );

          await db.update(
            DbTables.jobs,
            {
              JobColumns.syncStatus: 'synced',
              JobColumns.version: result.newVersion,
            },
            where: '${JobColumns.id} = ?',
            whereArgs: [item.jobId],
          );
        } else if (result.isConflict && result.serverJob != null) {
          // Conflict detected: Office changed the job while technician was offline
          final localJob = await _localDataSource.getJobById(item.jobId);
          if (localJob != null) {
            final resolution = await _conflictResolver.resolveConflict(
              localJob: localJob,
              serverJob: result.serverJob!,
            );

            // Remove conflicted item from queue as it is now reconciled
            await db.delete(
              DbTables.syncQueue,
              where: '${SyncQueueColumns.id} = ?',
              whereArgs: [item.id],
            );

            _updateState(_currentState.copyWith(
              conflictNotice: resolution.explanation,
            ));
          }
        } else {
          // Transient failure (network dropped):
          // Increment retry count and revert status to pending
          await db.update(
            DbTables.syncQueue,
            {
              SyncQueueColumns.status: 'pending',
              SyncQueueColumns.retryCount: item.retryCount + 1,
            },
            where: '${SyncQueueColumns.id} = ?',
            whereArgs: [item.id],
          );
        }
      }

      final remaining = await _dbManager.getPendingSyncCount();
      _updateState(_currentState.copyWith(
        isSyncing: false,
        pendingCount: remaining,
        lastSyncTime: DateTime.now(),
      ));
    } catch (e) {
      _updateState(_currentState.copyWith(
        isSyncing: false,
        lastError: e.toString(),
      ));
    } finally {
      _isProcessing = false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
  }
}
