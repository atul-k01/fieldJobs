import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sync/providers/sync_provider.dart';
import '../models/job_model.dart';
import '../providers/jobs_provider.dart';
import 'job_detail_screen.dart';
import 'widgets/job_card.dart';

class JobsListScreen extends ConsumerStatefulWidget {
  const JobsListScreen({super.key});

  @override
  ConsumerState<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends ConsumerState<JobsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    final pendingCount = await ref.read(authStateProvider.notifier).getPendingSyncCount();

    if (!mounted) return;

    if (pendingCount > 0) {
      // Unsynced changes warning dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
              SizedBox(width: 8),
              Expanded(child: Text(AppStrings.unsyncedWarningTitle)),
            ],
          ),
          content: Text(
            'You have $pendingCount unsynced changes. ${AppStrings.unsyncedWarningMsg}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(authStateProvider.notifier).signOut();
              },
              child: const Text(AppStrings.proceedSignOut),
            ),
          ],
        ),
      );
    } else {
      // Safe sign out dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(AppStrings.signOutConfirmTitle),
          content: const Text(AppStrings.signOutConfirmMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(AppStrings.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(authStateProvider.notifier).signOut();
              },
              child: const Text(AppStrings.signOut),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final jobsState = ref.watch(jobsProvider);
    final syncStatus = ref.watch(syncStatusProvider).value;
    final isOnline = ref.watch(isOnlineProvider).value ?? true;

    final user = authState.user;
    final todayJobs = jobsState.todayJobs;
    final upcomingJobs = jobsState.upcomingJobs;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.myJobs,
              style: AppTextStyles.h2,
            ),
            if (user != null)
              Text(
                '${user.name} • ${user.email}',
                style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: AppStrings.signOut,
            onPressed: _handleSignOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(AppStrings.todayTab),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${todayJobs.length}',
                      style: AppTextStyles.badge.copyWith(
                        color: AppColors.primaryDark,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(AppStrings.upcomingTab),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${upcomingJobs.length}',
                      style: AppTextStyles.badge.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Dynamic Offline / Sync Banner
          OfflineBanner(
            isOnline: isOnline,
            pendingCount: syncStatus?.pendingCount ?? 0,
            isSyncing: syncStatus?.isSyncing ?? false,
            onSyncPressed: () {
              ref.read(syncEngineProvider).processQueue();
            },
          ),

          // Main Job Lists
          Expanded(
            child: jobsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Today's Jobs Tab
                      _buildJobList(
                        jobs: todayJobs,
                        emptyMessage: AppStrings.noJobsToday,
                        isToday: true,
                      ),

                      // Upcoming Jobs Tab
                      _buildJobList(
                        jobs: upcomingJobs,
                        emptyMessage: AppStrings.noUpcomingJobs,
                        isToday: false,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobList({
    required List<JobModel> jobs,
    required String emptyMessage,
    required bool isToday,
  }) {
    if (jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(jobsProvider.notifier).loadJobs(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 64,
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: AppDimens.space16),
                  Text(
                    emptyMessage,
                    style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppDimens.space8),
                  Text(
                    AppStrings.pullToRefresh,
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(jobsProvider.notifier).loadJobs();
        await ref.read(syncEngineProvider).processQueue();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.space16),
        itemCount: jobs.length,
        itemBuilder: (context, index) {
          final job = jobs[index];
          return JobCard(
            job: job,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(jobId: job.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
