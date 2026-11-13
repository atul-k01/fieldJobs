import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../models/checklist_item_model.dart';

class ChecklistWidget extends StatelessWidget {
  final List<ChecklistItemModel> items;
  final Function(String itemId, bool isCompleted) onToggle;
  final bool isReadOnly;

  const ChecklistWidget({
    super.key,
    required this.items,
    required this.onToggle,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final completedCount = items.where((i) => i.isCompleted).length;
    final totalCount = items.length;
    final progress = totalCount > 0 ? (completedCount / totalCount) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.checklist_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: AppDimens.space8),
                Expanded(
                  child: Text(
                    AppStrings.checklistTitle,
                    style: AppTextStyles.h3,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space8,
                    vertical: AppDimens.space2,
                  ),
                  decoration: BoxDecoration(
                    color: completedCount == totalCount
                        ? const Color(0xFFD1FAE5)
                        : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                  ),
                  child: Text(
                    '$completedCount / $totalCount Done',
                    style: AppTextStyles.badge.copyWith(
                      color: completedCount == totalCount
                          ? const Color(0xFF059669)
                          : AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.space8),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusFull),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completedCount == totalCount
                      ? AppColors.success
                      : AppColors.primary,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: AppDimens.space12),

            Text(
              AppStrings.checklistSubtitle,
              style: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppDimens.space8),

            // Checklist Items
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  value: item.isCompleted,
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    item.title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: item.isCompleted
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      decoration: item.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  onChanged: isReadOnly
                      ? null
                      : (bool? val) {
                          if (val != null) {
                            onToggle(item.id, val);
                          }
                        },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
