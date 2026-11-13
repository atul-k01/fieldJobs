import 'package:flutter/material.dart';
import '../utils/app_log.dart';
import '../../features/jobs/presentation/job_detail_screen.dart';
import '../../features/jobs/presentation/jobs_list_screen.dart';
import '../../features/auth/presentation/login_screen.dart';

/// Centralized navigation service for FieldJobs.
/// Handles route transitions, back navigation, and logging across the app.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Pushes a new screen with smooth transition and debug logging
  static Future<T?> push<T>(
    BuildContext context,
    Widget screen, {
    String? screenName,
  }) {
    final name = screenName ?? screen.runtimeType.toString();
    AppLog.d('AppNavigator', 'Navigating to: $name');

    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => screen,
        settings: RouteSettings(name: name),
      ),
    );
  }

  /// Replaces current screen
  static Future<T?> pushReplacement<T, TO>(
    BuildContext context,
    Widget screen, {
    String? screenName,
  }) {
    final name = screenName ?? screen.runtimeType.toString();
    AppLog.d('AppNavigator', 'Replacing screen with: $name');

    return Navigator.of(context).pushReplacement<T, TO>(
      MaterialPageRoute(
        builder: (_) => screen,
        settings: RouteSettings(name: name),
      ),
    );
  }

  /// Clears navigation stack and navigates to target root screen
  static Future<T?> pushAndRemoveUntil<T>(
    BuildContext context,
    Widget screen, {
    String? screenName,
  }) {
    final name = screenName ?? screen.runtimeType.toString();
    AppLog.d('AppNavigator', 'Clearing stack and navigating to: $name');

    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute(
        builder: (_) => screen,
        settings: RouteSettings(name: name),
      ),
      (route) => false,
    );
  }

  /// Safe pop
  static void pop<T>(BuildContext context, [T? result]) {
    if (Navigator.of(context).canPop()) {
      AppLog.d('AppNavigator', 'Popping current screen');
      Navigator.of(context).pop<T>(result);
    } else {
      AppLog.w('AppNavigator', 'Cannot pop: stack is at root');
    }
  }

  // --- Specific Feature Routes ---

  /// Navigate to Job Detail Screen
  static Future<void> goToJobDetail(BuildContext context, String jobId) {
    return push(
      context,
      JobDetailScreen(jobId: jobId),
      screenName: 'JobDetailScreen($jobId)',
    );
  }

  /// Navigate to Jobs List Screen
  static Future<void> goToJobsList(BuildContext context) {
    return pushReplacement(
      context,
      const JobsListScreen(),
      screenName: 'JobsListScreen',
    );
  }

  /// Navigate to Login Screen (clearing session navigation history)
  static Future<void> goToLogin(BuildContext context) {
    return pushAndRemoveUntil(
      context,
      const LoginScreen(),
      screenName: 'LoginScreen',
    );
  }
}
