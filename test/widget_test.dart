import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_jobs/core/constants/app_strings.dart';
import 'package:field_jobs/main.dart';

void main() {
  testWidgets('App root smoke test renders login or loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FieldJobsApp(),
      ),
    );

    // Initial frame shows either progress indicator or login
    expect(find.byType(MaterialApp), findsOneWidget);

    // Pump frames to resolve future
    await tester.pump(const Duration(milliseconds: 500));

    // Should find either CircularProgressIndicator or App Name
    final hasLoader = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final hasLogin = find.text(AppStrings.appName).evaluate().isNotEmpty;

    expect(hasLoader || hasLogin, true);
  });
}
