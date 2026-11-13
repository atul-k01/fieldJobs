import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';

/// Centralized SnackBar manager for consistent, beautiful floating toasts across the app.
class AppSnackBar {
  AppSnackBar._();

  /// Displays a success toast (Green)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFF047857), // Emerald Green
      icon: Icons.check_circle_rounded,
      duration: duration,
    );
  }

  /// Displays an error toast (Red)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFFDC2626), // Danger Red
      icon: Icons.error_outline_rounded,
      duration: duration,
    );
  }

  /// Displays a warning toast (Amber)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: const Color(0xFFD97706), // Amber Warning
      icon: Icons.warning_amber_rounded,
      duration: duration,
    );
  }

  /// Displays an informational toast (Sky Blue)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.primaryDark,
      icon: Icons.info_outline_rounded,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        elevation: 4,
        margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
        ),
        duration: duration,
      ),
    );
  }
}
