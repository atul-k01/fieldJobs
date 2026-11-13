import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

/// Professional, reusable Sign Out Confirmation Dialog
/// Highlights data-loss warnings when unsynced changes are pending.
/// Features a side-by-side [Cancel] (Left) and [Sign Out] (Right) layout.
class SignOutDialog extends StatefulWidget {
  final int pendingSyncCount;
  final Future<void> Function() onConfirm;

  const SignOutDialog({
    super.key,
    required this.pendingSyncCount,
    required this.onConfirm,
  });

  /// Static helper to display the dialog
  static Future<void> show({
    required BuildContext context,
    required int pendingSyncCount,
    required Future<void> Function() onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SignOutDialog(
        pendingSyncCount: pendingSyncCount,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<SignOutDialog> createState() => _SignOutDialogState();
}

class _SignOutDialogState extends State<SignOutDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final hasUnsynced = widget.pendingSyncCount > 0;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimens.radiusLarge),
      ),
      elevation: 6,
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: hasUnsynced
                    ? const Color(0xFFFEF3C7) // Amber soft bg
                    : const Color(0xFFFEE2E2), // Red soft bg
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasUnsynced
                    ? Icons.warning_amber_rounded
                    : Icons.logout_rounded,
                color: hasUnsynced
                    ? const Color(0xFFD97706)
                    : const Color(0xFFDC2626),
                size: 28,
              ),
            ),
            const SizedBox(height: AppDimens.space16),

            // Dialog Title
            Text(
              hasUnsynced ? AppStrings.unsyncedWarningTitle : AppStrings.signOut,
              style: AppTextStyles.h2.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.space8),

            // Dialog Subtitle / Body
            if (hasUnsynced) ...[
              Container(
                padding: const EdgeInsets.all(AppDimens.space12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  children: [
                    Text(
                      'You have ${widget.pendingSyncCount} ${AppStrings.unsyncedChanges}.',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      AppStrings.unsyncedWarningMsg,
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 12,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                AppStrings.signOutConfirmMsg,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: AppDimens.space24),

            // Action Buttons: LEFT (Cancel) and RIGHT (Sign Out)
            Row(
              children: [
                // Left Option: Cancel / Stay
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
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

                // Right Option: Confirm Sign Out (Red Destructive)
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignOut,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626), // Danger Red
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            hasUnsynced ? AppStrings.proceedSignOut : AppStrings.signOut,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await widget.onConfirm();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
