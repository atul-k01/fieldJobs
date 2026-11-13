import '../../../core/data/base_repository.dart';
import '../../sync/services/sync_engine.dart';
import '../models/job_model.dart';
import 'job_local_datasource.dart';
import 'job_remote_datasource.dart';

/// Clean Architecture Repository for Jobs.
/// Extends [BaseRepository] for standardized error handling and logging.
class JobRepository extends BaseRepository {
  final JobLocalDataSource _localDataSource;
  final JobRemoteDataSource _remoteDataSource;
  final SyncEngine? _syncEngine;

  JobRepository({
    JobLocalDataSource? localDataSource,
    JobRemoteDataSource? remoteDataSource,
    SyncEngine? syncEngine,
  })  : _localDataSource = localDataSource ?? JobLocalDataSource(),
        _remoteDataSource = remoteDataSource ?? JobRemoteDataSource(),
        _syncEngine = syncEngine,
        super(tag: 'JobRepository');

  /// Seeds initial demo data if database is empty for technician
  Future<void> ensureDemoDataSeeded(String email) {
    return safeCall(
      () => _localDataSource.ensureDemoDataSeeded(email),
      operation: 'ensureDemoDataSeeded($email)',
    );
  }

  /// Get jobs assigned to technician (Local Single Source of Truth)
  Future<List<JobModel>> getJobsForTechnician(String email) {
    return safeCall(
      () => _localDataSource.getJobsForTechnician(email),
      operation: 'getJobsForTechnician($email)',
    );
  }

  /// Get individual job details
  Future<JobModel?> getJobById(String jobId) {
    return safeCall(
      () => _localDataSource.getJobById(jobId),
      operation: 'getJobById($jobId)',
    );
  }

  /// Transition job status (Travelling -> On site -> Completed / Couldn't complete)
  Future<void> updateJobStatus(String jobId, String status, {String? reason}) {
    return safeCall(
      () async {
        await _localDataSource.updateJobStatus(jobId, status, reason: reason);
        _syncEngine?.refreshPendingCount();
        await _syncEngine?.processQueue();
      },
      operation: 'updateJobStatus($jobId, $status)',
    );
  }

  /// Toggle checklist item
  Future<void> toggleChecklistItem(String itemId, String jobId, bool isCompleted) {
    return safeCall(
      () async {
        await _localDataSource.toggleChecklistItem(itemId, jobId, isCompleted);
        _syncEngine?.refreshPendingCount();
        await _syncEngine?.processQueue();
      },
      operation: 'toggleChecklistItem($itemId, isCompleted: $isCompleted)',
    );
  }

  /// Save technician notes
  Future<void> saveNotes(String jobId, String notes) {
    return safeCall(
      () async {
        await _localDataSource.saveNotes(jobId, notes);
        _syncEngine?.refreshPendingCount();
        await _syncEngine?.processQueue();
      },
      operation: 'saveNotes($jobId)',
    );
  }

  /// Attach photo (up to 3)
  Future<bool> attachPhoto(String jobId, String localPath) {
    return safeCall(
      () async {
        final success = await _localDataSource.attachPhoto(jobId, localPath);
        if (success) {
          _syncEngine?.refreshPendingCount();
          await _syncEngine?.processQueue();
        }
        return success;
      },
      operation: 'attachPhoto($jobId)',
    );
  }

  /// Pull jobs from remote server if connected
  Future<List<JobModel>> fetchRemoteJobs(String email) {
    return safeCall(
      () => _remoteDataSource.fetchJobsForTechnician(email),
      operation: 'fetchRemoteJobs($email)',
    );
  }

  /// Store remote jobs in local SQLite cache
  Future<void> saveRemoteJobs(String technicianEmail, List<JobModel> remoteJobs) {
    return safeCall(
      () => _localDataSource.saveRemoteJobs(technicianEmail, remoteJobs),
      operation: 'saveRemoteJobs($technicianEmail)',
    );
  }
}
