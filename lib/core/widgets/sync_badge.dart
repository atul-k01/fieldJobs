import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

class SyncBadge extends StatelessWidget {
  final String syncStatus;

  const SyncBadge({super.key, required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    if (syncStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space8,
          vertical: AppDimens.space2,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 12, color: Color(0xFFD97706)),
            const SizedBox(width: AppDimens.space4),
            Text(
              AppStrings.syncBadgePending,
              style: AppTextStyles.badge.copyWith(
                fontSize: 10,
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
      );
    }

    if (syncStatus == 'conflict') {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.space8,
          vertical: AppDimens.space2,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
          border: Border.all(color: AppColors.error, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 12, color: AppColors.error),
            const SizedBox(width: AppDimens.space4),
            Text(
              AppStrings.syncBadgeConflict,
              style: AppTextStyles.badge.copyWith(
                fontSize: 10,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    // Synced status (compact checkmark or hidden)
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space8,
        vertical: AppDimens.space2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: Border.all(color: const Color(0xFFA7F3D0), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_done, size: 12, color: Color(0xFF059669)),
          const SizedBox(width: AppDimens.space4),
          Text(
            AppStrings.syncBadgeSynced,
            style: AppTextStyles.badge.copyWith(
              fontSize: 10,
              color: const Color(0xFF059669),
            ),
          ),
        ],
      ),
    );
  }
}
