import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../../core/widgets/sync_badge.dart';
import '../../models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimens.space12),
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        side: BorderSide(
          color: job.hasConflict
              ? AppColors.error.withValues(alpha: 0.5)
              : (job.isPendingSync
                  ? AppColors.warning.withValues(alpha: 0.5)
                  : AppColors.divider),
          width: (job.hasConflict || job.isPendingSync) ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left color indicator stripe based on status
              Container(
                width: 5,
                color: _getStatusStripeColor(job),
              ),

              // Card Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.cardPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Time Window, Status Chip, Sync Badge (Zero-overflow responsive layout)
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppDimens.space8,
                        runSpacing: AppDimens.space6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimens.space8,
                              vertical: AppDimens.space4,
                            ),
                            decoration: BoxDecoration(
                              color: job.isOverdue
                                  ? const Color(0xFFFEE2E2)
                                  : AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  job.isOverdue
                                      ? Icons.event_busy_rounded
                                      : Icons.access_time_rounded,
                                  size: 13,
                                  color: job.isOverdue
                                      ? const Color(0xFFDC2626)
                                      : AppColors.primaryDark,
                                ),
                                const SizedBox(width: AppDimens.space4),
                                Text(
                                  job.isOverdue
                                      ? '${job.scheduledDate} • ${job.timeWindow}'
                                      : job.timeWindow,
                                  style: AppTextStyles.badge.copyWith(
                                    color: job.isOverdue
                                        ? const Color(0xFFDC2626)
                                        : AppColors.primaryDark,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Wrap(
                            spacing: AppDimens.space6,
                            runSpacing: AppDimens.space4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (job.isOverdue)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                                    border: Border.all(color: const Color(0xFFDC2626), width: 1.0),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.alarm_on_rounded, size: 12, color: Color(0xFFDC2626)),
                                      SizedBox(width: 3),
                                      Text(
                                        AppStrings.overdueBadge,
                                        style: TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SyncBadge(syncStatus: job.syncStatus),
                                StatusChip(status: job.status),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.space12),

                      // Appliance Name & Customer Name
                      Text(
                        job.appliance,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space4),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppDimens.space4),
                          Expanded(
                            child: Text(
                              job.customerName,
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimens.space8),

                      // Problem Description
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppDimens.space8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Text(
                          job.problemDescription,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space10),

                      // Address Row & Action hint
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppDimens.space4),
                          Expanded(
                            child: Text(
                              job.address,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppDimens.space8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  job.isUpcoming ? AppStrings.viewSchedule : AppStrings.workJob,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 10,
                                  color: AppColors.primaryDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusStripeColor(JobModel job) {
    if (job.isOverdue) return const Color(0xFFDC2626);
    switch (job.status.toLowerCase()) {
      case 'on_site':
        return const Color(0xFFD97706);
      case 'travelling':
        return AppColors.primary;
      case 'completed':
        return const Color(0xFF059669);
      case 'could_not_complete':
      case 'cancelled':
        return AppColors.error;
      case 'assigned':
      default:
        return AppColors.border;
    }
  }
}
