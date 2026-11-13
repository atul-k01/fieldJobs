import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Time Window, Status Chip, Sync Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.space8,
                      vertical: AppDimens.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: AppColors.primaryDark,
                        ),
                        const SizedBox(width: AppDimens.space4),
                        Text(
                          job.timeWindow,
                          style: AppTextStyles.badge.copyWith(
                            color: AppColors.primaryDark,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (job.isPendingSync || job.hasConflict) ...[
                    SyncBadge(syncStatus: job.syncStatus),
                    const SizedBox(width: AppDimens.space8),
                  ],
                  StatusChip(status: job.status),
                ],
              ),
              const SizedBox(height: AppDimens.space12),

              // Appliance Name & Customer Name
              Text(
                job.appliance,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
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
                  Text(
                    job.customerName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
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
              const SizedBox(height: AppDimens.space8),

              // Address Row
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
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
