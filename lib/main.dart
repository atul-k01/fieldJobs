import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_strings.dart';
import 'core/navigation/app_navigator.dart';
import 'core/network/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/jobs/presentation/jobs_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safely initialize Supabase if credentials are provided in environment or config
  await SupabaseConfig.init();

  runApp(
    const ProviderScope(
      child: FieldJobsApp(),
    ),
  );
}

class FieldJobsApp extends ConsumerWidget {
  const FieldJobsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      navigatorKey: AppNavigator.navigatorKey,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: authState.isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : (authState.isAuthenticated
              ? const JobsListScreen()
              : const LoginScreen()),
    );
  }
}
