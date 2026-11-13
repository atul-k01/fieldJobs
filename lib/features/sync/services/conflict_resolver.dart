import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/tables.dart';
import '../../jobs/models/job_model.dart';

enum ConflictResolutionStrategy {
  serverWinsWithFieldAudit, // Office cancelled/reassigned: keep cancel, preserve tech work
  clientWinsFieldExecution, // Tech did work: keep completion, update server
  fieldLevelMerge,          // Office edited description/time: merge fields
}

class ConflictResolutionResult {
  final JobModel resolvedJob;
  final String explanation;
  final ConflictResolutionStrategy strategy;

  ConflictResolutionResult({
    required this.resolvedJob,
    required this.explanation,
    required this.strategy,
  });
}

class ConflictResolver {
  final AppDatabase _dbManager;
  final bool _autoPersist;

  ConflictResolver({AppDatabase? dbManager, bool autoPersist = true})
      : _dbManager = dbManager ?? AppDatabase.instance,
        _autoPersist = autoPersist;

  /// Resolves conflicts between the local offline job state and incoming office server state.
  /// Guarantees: ZERO data loss of technician notes, checklists, or photos.
  Future<ConflictResolutionResult> resolveConflict({
    required JobModel localJob,
    required JobModel serverJob,
  }) async {
    final nowStr = DateTime.now().toIso8601String();

    // RULE 1: Office Cancelled Job while Technician worked offline
    if (serverJob.status == 'cancelled') {
      final mergedNotes = _mergeNotes(
        serverJob.technicianNotes,
        localJob.technicianNotes,
        extraPrefix: '[OFFICE CANCELLED WHILE TECH WORKED OFFLINE]: ',
      );

      final resolved = localJob.copyWith(
        status: 'cancelled',
        technicianNotes: mergedNotes,
        version: serverJob.version + 1,
        syncStatus: 'conflict',
        updatedAt: nowStr,
      );

      if (_autoPersist) await _persistResolvedJob(resolved);

      return ConflictResolutionResult(
        resolvedJob: resolved,
        explanation: 'Job was cancelled by office. Technician offline notes & photos preserved for dispatch review.',
        strategy: ConflictResolutionStrategy.serverWinsWithFieldAudit,
      );
    }

    // RULE 2: Office Reassigned Job to Another Technician
    if (serverJob.assignedTo.toLowerCase() != localJob.assignedTo.toLowerCase()) {
      final mergedNotes = _mergeNotes(
        serverJob.technicianNotes,
        localJob.technicianNotes,
        extraPrefix: '[TECH COMPLETED WORK PRIOR TO REASSIGNMENT]: ',
      );

      final resolved = localJob.copyWith(
        assignedTo: serverJob.assignedTo,
        technicianNotes: mergedNotes,
        version: serverJob.version + 1,
        syncStatus: 'conflict',
        updatedAt: nowStr,
      );

      if (_autoPersist) await _persistResolvedJob(resolved);

      return ConflictResolutionResult(
        resolvedJob: resolved,
        explanation: 'Office reassigned job to ${serverJob.assignedTo}. Offline field records attached.',
        strategy: ConflictResolutionStrategy.serverWinsWithFieldAudit,
      );
    }

    // RULE 3: Office edited Problem Description, Schedule or Address while Tech worked offline
    // Resolution: Merge office details (new address/problem description) with technician execution state
    final mergedProblem = (serverJob.problemDescription != localJob.problemDescription)
        ? '${serverJob.problemDescription} [Office Updated]'
        : localJob.problemDescription;

    final resolved = localJob.copyWith(
      address: serverJob.address,
      scheduledDate: serverJob.scheduledDate,
      timeWindow: serverJob.timeWindow,
      problemDescription: mergedProblem,
      // Keep technician's on-site execution status
      status: localJob.status,
      cannotCompleteReason: localJob.cannotCompleteReason,
      version: serverJob.version + 1,
      syncStatus: 'synced',
      updatedAt: nowStr,
    );

    if (_autoPersist) await _persistResolvedJob(resolved);

    return ConflictResolutionResult(
      resolvedJob: resolved,
      explanation: 'Office schedule/details updated and seamlessly merged with your field progress.',
      strategy: ConflictResolutionStrategy.fieldLevelMerge,
    );
  }

  String _mergeNotes(String? serverNotes, String? localNotes, {String extraPrefix = ''}) {
    final buffer = StringBuffer();
    if (extraPrefix.isNotEmpty) buffer.writeln(extraPrefix);
    if (localNotes != null && localNotes.trim().isNotEmpty) {
      buffer.writeln('Field Notes: $localNotes');
    }
    if (serverNotes != null && serverNotes.trim().isNotEmpty) {
      buffer.writeln('Office Dispatch Notes: $serverNotes');
    }
    return buffer.toString().trim();
  }

  Future<void> _persistResolvedJob(JobModel resolvedJob) async {
    final db = await _dbManager.database;
    await db.update(
      DbTables.jobs,
      resolvedJob.toMap(),
      where: '${JobColumns.id} = ?',
      whereArgs: [resolvedJob.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
