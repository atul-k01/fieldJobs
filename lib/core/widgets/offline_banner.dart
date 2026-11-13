import 'package:flutter/material.dart';
import '../constants/app_dimens.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOnline;
  final int pendingCount;
  final bool isSyncing;
  final VoidCallback onSyncPressed;

  const OfflineBanner({
    super.key,
    required this.isOnline,
    required this.pendingCount,
    required this.isSyncing,
    required this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline && pendingCount == 0 && !isSyncing) {
      return const SizedBox.shrink();
    }

    final isOffline = !isOnline;
    final bgColor = isOffline ? const Color(0xFF334155) : const Color(0xFF0369A1);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.space16,
        vertical: AppDimens.space8,
      ),
      child: SafeArea(
        bottom: false,
        top: false,
        child: Row(
          children: [
            Icon(
              isOffline ? Icons.wifi_off_rounded : Icons.sync_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Text(
                isOffline
                    ? (pendingCount > 0
                        ? 'Offline Mode • $pendingCount changes queued'
                        : 'Offline Mode • Working with local storage')
                    : (isSyncing
                        ? 'Syncing changes with office...'
                        : '$pendingCount pending change${pendingCount > 1 ? 's' : ''} to sync'),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isOnline && pendingCount > 0)
              TextButton(
                onPressed: isSyncing ? null : onSyncPressed,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimens.space12,
                    vertical: AppDimens.space4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: isSyncing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        AppStrings.syncNow,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
