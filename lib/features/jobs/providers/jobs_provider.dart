import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sync/providers/sync_provider.dart';
import '../data/job_local_datasource.dart';
import '../data/job_repository.dart';
import '../models/job_model.dart';
import '../../../core/utils/date_formatter.dart';

final jobLocalDataSourceProvider = Provider<JobLocalDataSource>((ref) {
  return JobLocalDataSource();
});

final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final syncEngine = ref.watch(syncEngineProvider);
  return JobRepository(syncEngine: syncEngine);
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
      // Once completed, cancelled, or marked couldn't complete,
      // the job immediately moves to Job History and is removed from Today.
      if (j.isDone) return false;

      if (j.isOverdue) return true; // Past unfinished jobs must stay in Today until addressed
      try {
        final parsed = DateTime.parse(j.scheduledDate);
        return DateFormatter.isToday(parsed);
      } catch (_) {
        return false;
      }
    }).toList();

    // Sort: Overdue first, then active On Site/Travelling, then assigned, completed last
    list.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      return _statusPriority(a.status).compareTo(_statusPriority(b.status));
    });
    return list;
  }

  List<JobModel> get upcomingJobs {
    final list = allJobs.where((j) {
      if (j.isDone) return false;
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

  List<JobModel> get historyJobs {
    final list = allJobs.where((j) => j.isDone).toList();
    // Sort most recently completed or updated first
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  List<JobModel> get overdueJobs => todayJobs.where((j) => j.isOverdue).toList();

  List<JobModel> get activeTodayJobs => todayJobs.where((j) => !j.isOverdue).toList();

  int get overdueCount => overdueJobs.length;

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
  final JobRepository _repository;
  final Ref _ref;
  String? _currentUserEmail;

  JobsNotifier(this._repository, this._ref) : super(const JobsState(isLoading: true)) {
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
      if (SupabaseConfig.isInitialized) {
        // Fetch live jobs directly from Supabase remote backend
        final remoteJobs = await _repository.fetchRemoteJobs(_currentUserEmail!);
        if (remoteJobs.isNotEmpty) {
          await _repository.saveRemoteJobs(_currentUserEmail!, remoteJobs);
        }
      } else {
        await _repository.ensureDemoDataSeeded(_currentUserEmail!);
      }
      final jobs = await _repository.getJobsForTechnician(_currentUserEmail!);
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
    await _repository.updateJobStatus(jobId, status, reason: reason);
    await _reloadSingleJob(jobId);
  }

  Future<void> toggleChecklistItem(String itemId, String jobId, bool isCompleted) async {
    await _repository.toggleChecklistItem(itemId, jobId, isCompleted);
    await _reloadSingleJob(jobId);
  }

  Future<void> saveNotes(String jobId, String notes) async {
    await _repository.saveNotes(jobId, notes);
    await _reloadSingleJob(jobId);
  }

  Future<bool> attachPhoto(String jobId, String localPath) async {
    final success = await _repository.attachPhoto(jobId, localPath);
    if (success) {
      await _reloadSingleJob(jobId);
    }
    return success;
  }

  Future<void> _reloadSingleJob(String jobId) async {
    final updatedJob = await _repository.getJobById(jobId);
    if (updatedJob == null) return;

    final updatedList = state.allJobs.map((j) {
      return (j.id == jobId) ? updatedJob : j;
    }).toList();

    state = state.copyWith(allJobs: updatedList);
  }
}

final jobsProvider = StateNotifierProvider<JobsNotifier, JobsState>((ref) {
  final repo = ref.watch(jobRepositoryProvider);
  return JobsNotifier(repo, ref);
});
