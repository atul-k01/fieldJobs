import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';

class _ReasonOption {
  final String title;
  final IconData icon;

  const _ReasonOption(this.title, this.icon);
}

/// High-quality, modern confirmation dialog for marking a job as "Couldn't Complete"
/// Ensures mandatory reason collection with clean selectable options and notes.
class CannotCompleteDialog extends StatefulWidget {
  final Function(String reason) onConfirm;

  const CannotCompleteDialog({super.key, required this.onConfirm});

  @override
  State<CannotCompleteDialog> createState() => _CannotCompleteDialogState();
}

class _CannotCompleteDialogState extends State<CannotCompleteDialog> {
  final _reasonController = TextEditingController();
  String? _selectedPreset;

  static const List<_ReasonOption> _options = [
    _ReasonOption(AppStrings.reasonCustomerNotHome, Icons.door_front_door_outlined),
    _ReasonOption(AppStrings.reasonPartsUnavailable, Icons.build_circle_outlined),
    _ReasonOption(AppStrings.reasonAccessBlocked, Icons.warning_amber_rounded),
    _ReasonOption(AppStrings.reasonWrongAppliance, Icons.inventory_2_outlined),
    _ReasonOption(AppStrings.reasonSpecialistRequired, Icons.handyman_outlined),
    _ReasonOption(AppStrings.reasonRescheduleRequested, Icons.event_repeat_rounded),
    _ReasonOption(AppStrings.reasonOther, Icons.edit_note_rounded),
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
      if (_selectedPreset == AppStrings.reasonOther) {
        finalReason = custom;
      } else {
        finalReason = '$_selectedPreset - $custom';
      }
    } else if (_selectedPreset != null) {
      if (_selectedPreset == AppStrings.reasonOther && custom.isEmpty) {
        AppSnackBar.showError(context, AppStrings.cannotCompleteReasonRequired);
        return;
      }
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
      elevation: 6,
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Icon & Title Header
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEE2E2), // Soft danger red
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    color: Color(0xFFDC2626),
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space12),

              Text(
                AppStrings.cannotCompleteReasonTitle,
                style: AppTextStyles.h2.copyWith(fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              Text(
                AppStrings.cannotCompleteSubtitle,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimens.space16),

              // Scrollable Options List
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        AppStrings.selectReasonPrompt,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space8),

                      // Selectable Radio Cards
                      ..._options.map((option) {
                        final isSelected = _selectedPreset == option.title;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppDimens.space6),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedPreset = option.title;
                              });
                            },
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimens.space12,
                                vertical: AppDimens.space10,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFEF2F2)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFDC2626)
                                      : AppColors.divider,
                                  width: isSelected ? 1.4 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    option.icon,
                                    size: 18,
                                    color: isSelected
                                        ? const Color(0xFFDC2626)
                                        : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppDimens.space10),
                                  Expanded(
                                    child: Text(
                                      option.title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? const Color(0xFF991B1B)
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    size: 18,
                                    color: isSelected
                                        ? const Color(0xFFDC2626)
                                        : AppColors.textTertiary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: AppDimens.space12),

                      // Optional Custom Note Input
                      Text(
                        AppStrings.additionalNotesOptional,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimens.space6),

                      TextField(
                        controller: _reasonController,
                        maxLines: 2,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: AppStrings.cannotCompleteHint,
                          hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.all(AppDimens.space12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimens.space16),

              // Action Buttons: LEFT (Cancel) and RIGHT (Confirm Status)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                        ),
                      ),
                      child: const Text(
                        AppStrings.cancel,
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626), // Destructive Red
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                        ),
                      ),
                      child: const Text(
                        AppStrings.submitReason,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
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
