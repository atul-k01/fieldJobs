import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sync/providers/sync_provider.dart';
import '../data/job_local_datasource.dart';
import '../models/job_model.dart';
import '../../../core/utils/date_formatter.dart';

final jobLocalDataSourceProvider = Provider<JobLocalDataSource>((ref) {
  return JobLocalDataSource();
});

class JobsState {
  final List<JobModel> allJobs;
  final bool isLoading;
  final String? errorMessage;

  const JobsState({
    this.allJobs = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  List<JobModel> get todayJobs {
    final list = allJobs.where((j) {
      try {
        final parsed = DateTime.parse(j.scheduledDate);
        return DateFormatter.isToday(parsed);
      } catch (_) {
        return false;
      }
    }).toList();

    // Sort: In progress/Travelling first, then assigned, completed last
    list.sort((a, b) => _statusPriority(a.status).compareTo(_statusPriority(b.status)));
    return list;
  }

  List<JobModel> get upcomingJobs {
    final list = allJobs.where((j) {
      try {
        final parsed = DateTime.parse(j.scheduledDate);
        return DateFormatter.isUpcoming(parsed);
      } catch (_) {
        return false;
      }
    }).toList();

    list.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    return list;
  }

  int _statusPriority(String status) {
    switch (status) {
      case 'on_site':
        return 1;
      case 'travelling':
        return 2;
      case 'assigned':
        return 3;
      case 'completed':
        return 4;
      case 'could_not_complete':
        return 5;
      case 'cancelled':
        return 6;
      default:
        return 7;
    }
  }

  JobsState copyWith({
    List<JobModel>? allJobs,
    bool? isLoading,
    String? errorMessage,
  }) {
    return JobsState(
      allJobs: allJobs ?? this.allJobs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class JobsNotifier extends StateNotifier<JobsState> {
  final JobLocalDataSource _localDataSource;
  final Ref _ref;
  String? _currentUserEmail;

  JobsNotifier(this._localDataSource, this._ref) : super(const JobsState(isLoading: true)) {
    _init();
  }

  void _init() {
    final authState = _ref.watch(authStateProvider);
    if (authState.user != null) {
      _currentUserEmail = authState.user!.email;
      loadJobs();
    } else {
      state = const JobsState(allJobs: [], isLoading: false);
    }
  }

  Future<void> loadJobs() async {
    if (_currentUserEmail == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _localDataSource.ensureDemoDataSeeded(_currentUserEmail!);
      final jobs = await _localDataSource.getJobsForTechnician(_currentUserEmail!);
      state = JobsState(allJobs: jobs, isLoading: false);
      _ref.read(syncEngineProvider).refreshPendingCount();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load jobs: $e',
      );
    }
  }

  Future<void> updateJobStatus(String jobId, String status, {String? reason}) async {
    await _localDataSource.updateJobStatus(jobId, status, reason: reason);
    await _reloadSingleJob(jobId);
    _ref.read(syncEngineProvider).refreshPendingCount();
    // Try to sync in background if online
    _ref.read(syncEngineProvider).processQueue();
  }

  Future<void> toggleChecklistItem(String itemId, String jobId, bool isCompleted) async {
    await _localDataSource.toggleChecklistItem(itemId, jobId, isCompleted);
    await _reloadSingleJob(jobId);
    _ref.read(syncEngineProvider).refreshPendingCount();
    _ref.read(syncEngineProvider).processQueue();
  }

  Future<void> saveNotes(String jobId, String notes) async {
    await _localDataSource.saveNotes(jobId, notes);
    await _reloadSingleJob(jobId);
    _ref.read(syncEngineProvider).refreshPendingCount();
    _ref.read(syncEngineProvider).processQueue();
  }

  Future<bool> attachPhoto(String jobId, String localPath) async {
    final success = await _localDataSource.attachPhoto(jobId, localPath);
    if (success) {
      await _reloadSingleJob(jobId);
      _ref.read(syncEngineProvider).refreshPendingCount();
      _ref.read(syncEngineProvider).processQueue();
    }
    return success;
  }

  Future<void> _reloadSingleJob(String jobId) async {
    final updatedJob = await _localDataSource.getJobById(jobId);
    if (updatedJob == null) return;

    final updatedList = state.allJobs.map((j) {
      return (j.id == jobId) ? updatedJob : j;
    }).toList();

    state = state.copyWith(allJobs: updatedList);
  }
}

final jobsProvider = StateNotifierProvider<JobsNotifier, JobsState>((ref) {
  final localDs = ref.watch(jobLocalDataSourceProvider);
  return JobsNotifier(localDs, ref);
});
