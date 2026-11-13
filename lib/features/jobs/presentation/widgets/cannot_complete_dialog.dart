import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/custom_button.dart';

class CannotCompleteDialog extends StatefulWidget {
  final Function(String reason) onConfirm;

  const CannotCompleteDialog({super.key, required this.onConfirm});

  @override
  State<CannotCompleteDialog> createState() => _CannotCompleteDialogState();
}

class _CannotCompleteDialogState extends State<CannotCompleteDialog> {
  final _reasonController = TextEditingController();
  String? _selectedPreset;

  final List<String> _presets = [
    'Customer not home / no answer at door',
    'Spare parts unavailable on vehicle',
    'Access blocked / safety hazard on site',
    'Incorrect appliance model reported',
    'Specialist equipment required',
    'Customer requested reschedule',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    final custom = _reasonController.text.trim();
    String finalReason = '';

    if (_selectedPreset != null && custom.isNotEmpty) {
      finalReason = '$_selectedPreset - $custom';
    } else if (_selectedPreset != null) {
      finalReason = _selectedPreset!;
    } else if (custom.isNotEmpty) {
      finalReason = custom;
    } else {
      AppSnackBar.showError(context, AppStrings.cannotCompleteReasonRequired);
      return;
    }

    Navigator.pop(context);
    widget.onConfirm(finalReason);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      ),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimens.space8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.statusCouldNotComplete,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Text(
                      AppStrings.cannotCompleteReasonTitle,
                      style: AppTextStyles.h3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.space16),

              Text(
                'Select a reason or write detailed notes for dispatch:',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppDimens.space12),

              // Presets radio chips
              Wrap(
                spacing: AppDimens.space8,
                runSpacing: AppDimens.space8,
                children: _presets.map((preset) {
                  final isSelected = _selectedPreset == preset;
                  return ChoiceChip(
                    label: Text(preset),
                    selected: isSelected,
                    selectedColor: const Color(0xFFFEE2E2),
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.statusCouldNotComplete : AppColors.textPrimary,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedPreset = selected ? preset : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimens.space16),

              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: AppStrings.cannotCompleteHint,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textTertiary),
                ),
              ),
              const SizedBox(height: AppDimens.space24),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: AppStrings.cancel,
                      isOutlined: true,
                      backgroundColor: AppColors.textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: CustomButton(
                      text: AppStrings.submitReason,
                      backgroundColor: AppColors.statusCouldNotComplete,
                      onPressed: _submit,
                    ),
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
