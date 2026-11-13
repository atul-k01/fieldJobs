import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_text_styles.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space12,
        vertical: AppDimens.space4,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusFull),
        border: Border.all(color: config.borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.textColor),
          const SizedBox(width: AppDimens.space4),
          Text(
            config.label,
            style: AppTextStyles.badge.copyWith(color: config.textColor),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      case 'travelling':
        return _StatusConfig(
          label: 'Travelling',
          textColor: AppColors.primary,
          backgroundColor: AppColors.primarySurface,
          borderColor: AppColors.primaryLight,
          icon: Icons.directions_car_filled_outlined,
        );
      case 'on_site':
        return _StatusConfig(
          label: 'On Site',
          textColor: const Color(0xFFD97706),
          backgroundColor: const Color(0xFFFEF3C7),
          borderColor: const Color(0xFFFDE68A),
          icon: Icons.build_circle_outlined,
        );
      case 'completed':
        return _StatusConfig(
          label: 'Completed',
          textColor: const Color(0xFF059669),
          backgroundColor: const Color(0xFFD1FAE5),
          borderColor: const Color(0xFFA7F3D0),
          icon: Icons.check_circle_outline,
        );
      case 'could_not_complete':
        return _StatusConfig(
          label: "Couldn't Complete",
          textColor: const Color(0xFFDC2626),
          backgroundColor: const Color(0xFFFEE2E2),
          borderColor: const Color(0xFFFECACA),
          icon: Icons.cancel_outlined,
        );
      case 'cancelled':
        return _StatusConfig(
          label: 'Cancelled',
          textColor: const Color(0xFF4B5563),
          backgroundColor: const Color(0xFFF3F4F6),
          borderColor: const Color(0xFFE5E7EB),
          icon: Icons.block_outlined,
        );
      case 'assigned':
      default:
        return _StatusConfig(
          label: 'Assigned',
          textColor: const Color(0xFF475569),
          backgroundColor: const Color(0xFFF1F5F9),
          borderColor: const Color(0xFFE2E8F0),
          icon: Icons.schedule_outlined,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;

  _StatusConfig({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
  });
}
