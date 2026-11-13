import '../../../core/network/supabase_config.dart';
import '../../sync/models/sync_queue_item.dart';
import '../models/checklist_item_model.dart';
import '../models/job_model.dart';

class RemoteSyncResult {
  final bool isSuccess;
  final int newVersion;
  final bool isConflict;
  final JobModel? serverJob;
  final String? errorMessage;

  RemoteSyncResult({
    required this.isSuccess,
    this.newVersion = 1,
    this.isConflict = false,
    this.serverJob,
    this.errorMessage,
  });
}

class JobRemoteDataSource {
  JobRemoteDataSource();

  /// Fetch jobs from Supabase
  Future<List<JobModel>> fetchJobsForTechnician(String email) async {
    if (!SupabaseConfig.isInitialized) {
      return [];
    }

    final client = SupabaseConfig.client!;
    final response = await client
        .from('jobs')
        .select('*, job_checklists(*)')
        .eq('assigned_to', email.toLowerCase());

    final List<JobModel> results = [];
    for (final row in response) {
      final jobMap = Map<String, dynamic>.from(row);
      final checklistsRaw = (jobMap['job_checklists'] as List<dynamic>? ?? []);
      final List<ChecklistItemModel> checklists = checklistsRaw
          .map((c) => ChecklistItemModel.fromMap(Map<String, dynamic>.from(c as Map)))
          .toList();

      final job = JobModel.fromMap(
        jobMap,
        checklists: checklists,
      );
      results.add(job);
    }
    return results;
  }

  /// Process an individual mutation item against Supabase backend
  Future<RemoteSyncResult> pushMutation(SyncQueueItem item) async {
    if (!SupabaseConfig.isInitialized) {
      // In offline / local mock evaluation mode:
      // Automatically succeed with version increment
      return RemoteSyncResult(
        isSuccess: true,
        newVersion: item.baseVersion + 1,
      );
    }

    final client = SupabaseConfig.client!;

    try {
      // 1. Fetch current server job state to detect conflict
      final serverRow = await client
          .from('jobs')
          .select()
          .eq('id', item.jobId)
          .maybeSingle();

      if (serverRow == null) {
        return RemoteSyncResult(
          isSuccess: false,
          errorMessage: 'Job not found on server',
        );
      }

      final serverVersion = serverRow['version'] as int? ?? 1;

      // 2. Conflict detection: Server version changed since technician was offline
      if (serverVersion > item.baseVersion) {
        final serverJob = JobModel.fromMap(Map<String, dynamic>.from(serverRow));
        return RemoteSyncResult(
          isSuccess: false,
          isConflict: true,
          newVersion: serverVersion,
          serverJob: serverJob,
        );
      }

      // 3. Apply mutation based on action type
      final newVersion = serverVersion + 1;
      final Map<String, dynamic> updateData = {
        'version': newVersion,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (item.actionType == 'update_status') {
        updateData['status'] = item.payload['status'];
      } else if (item.actionType == 'cannot_complete') {
        updateData['status'] = 'could_not_complete';
        updateData['cannot_complete_reason'] = item.payload['cannot_complete_reason'];
      } else if (item.actionType == 'save_notes') {
        updateData['technician_notes'] = item.payload['technician_notes'];
      } else if (item.actionType == 'update_checklist') {
        final chkId = item.payload['checklist_id'] as String;
        final isCompleted = item.payload['is_completed'] as bool;
        await client.from('job_checklists').update({
          'is_completed': isCompleted,
        }).eq('id', chkId);
      }

      await client.from('jobs').update(updateData).eq('id', item.jobId);

      return RemoteSyncResult(
        isSuccess: true,
        newVersion: newVersion,
      );
    } catch (e) {
      return RemoteSyncResult(
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }
}
