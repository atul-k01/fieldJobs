import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/sign_out_dialog.dart';
import '../../auth/providers/auth_provider.dart';
import '../../sync/providers/sync_provider.dart';
import '../models/job_model.dart';
import '../providers/jobs_provider.dart';
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    AppLog.d('JobsListScreen', 'User initiated sign out check');
    final pendingCount = await ref.read(authStateProvider.notifier).getPendingSyncCount();

    if (!mounted) return;

    await SignOutDialog.show(
      context: context,
      pendingSyncCount: pendingCount,
      onConfirm: () async {
        AppLog.i('JobsListScreen', 'User confirmed sign out (pendingCount: $pendingCount)');
        await ref.read(authStateProvider.notifier).signOut();
      },
    );
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
    final historyJobs = jobsState.historyJobs;
    final overdueCount = jobsState.overdueCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'T',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? AppStrings.myJobs,
                    style: AppTextStyles.h3.copyWith(fontSize: 16),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOnline ? AppColors.success : AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOnline ? AppStrings.online : AppStrings.offline,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          color: isOnline ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(' • ', style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                      Flexible(
                        child: Text(
                          user?.email ?? '',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              tabs: [
                // Tab 1: Today + Overdue
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(AppStrings.todayTab),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: overdueCount > 0
                                ? const Color(0xFFFEE2E2)
                                : AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${todayJobs.length}',
                            style: AppTextStyles.badge.copyWith(
                              color: overdueCount > 0
                                  ? const Color(0xFFDC2626)
                                  : AppColors.primaryDark,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Tab 2: Upcoming
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(AppStrings.upcomingTab),
                        const SizedBox(width: 4),
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
                ),

                // Tab 3: History / Completed
                Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(AppStrings.historyTab),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${historyJobs.length}',
                            style: AppTextStyles.badge.copyWith(
                              color: const Color(0xFF059669),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
              AppLog.d('JobsListScreen', 'Manual sync triggered by technician');
              ref.read(syncEngineProvider).processQueue();
            },
          ),

          // Main Job Lists (3 Tabs)
          Expanded(
            child: jobsState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Today's Jobs Tab (Shows Overdue section + Today's section together)
                      _buildTodayJobList(
                        overdueJobs: jobsState.overdueJobs,
                        todayJobs: jobsState.activeTodayJobs,
                      ),

                      // Tab 2: Upcoming Jobs Tab (Future scheduled)
                      _buildJobList(
                        jobs: upcomingJobs,
                        emptyMessage: AppStrings.noUpcomingJobs,
                        isToday: false,
                      ),

                      // Tab 3: History / Completed Tab (All completed past & present jobs)
                      _buildJobList(
                        jobs: historyJobs,
                        emptyMessage: AppStrings.noHistoryJobs,
                        isToday: false,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Dedicated layout for Today's Tab showing both Overdue Jobs and Today's Active Schedule
  Widget _buildTodayJobList({
    required List<JobModel> overdueJobs,
    required List<JobModel> todayJobs,
  }) {
    if (overdueJobs.isEmpty && todayJobs.isEmpty) {
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
                    AppStrings.noJobsToday,
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
      child: ListView(
        padding: const EdgeInsets.all(AppDimens.space16),
        children: [
          // 1. Overdue Section (Missed/Incomplete past jobs prioritized at top)
          if (overdueJobs.isNotEmpty) ...[
            _buildOverdueBanner(overdueJobs.length),
            _buildSectionHeader(
              title: AppStrings.overdueJobsHeader,
              subtitle: AppStrings.actionRequired,
              icon: Icons.alarm_on_rounded,
              color: const Color(0xFFDC2626),
              badgeCount: overdueJobs.length,
              badgeBg: const Color(0xFFFEE2E2),
              badgeTextColor: const Color(0xFFDC2626),
            ),
            const SizedBox(height: AppDimens.space8),
            ...overdueJobs.map(
              (job) => JobCard(
                job: job,
                onTap: () => AppNavigator.goToJobDetail(context, job.id),
              ),
            ),
            const SizedBox(height: AppDimens.space16),
          ],

          // 2. Today's Active Schedule Section
          if (todayJobs.isNotEmpty) ...[
            _buildSectionHeader(
              title: AppStrings.todayScheduleHeader,
              subtitle: AppStrings.activeJobs,
              icon: Icons.calendar_today_rounded,
              color: AppColors.primaryDark,
              badgeCount: todayJobs.length,
              badgeBg: AppColors.primarySurface,
              badgeTextColor: AppColors.primaryDark,
            ),
            const SizedBox(height: AppDimens.space8),
            ...todayJobs.map(
              (job) => JobCard(
                job: job,
                onTap: () => AppNavigator.goToJobDetail(context, job.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int badgeCount,
    required Color badgeBg,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '• $subtitle',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$badgeCount',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: badgeTextColor,
              ),
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
              AppNavigator.goToJobDetail(context, job.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildOverdueBanner(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.alarm_on_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: AppDimens.space10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count == 1
                      ? AppStrings.overdueAttentionSingle
                      : '$count ${AppStrings.overdueAttentionPlural}',
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  AppStrings.overdueAttentionDesc,
                  style: TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
