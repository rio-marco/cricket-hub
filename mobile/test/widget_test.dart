import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/theme/app_theme.dart';

void main() {
  testWidgets('app light theme renders a basic screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: Text('Cricket Hub')),
        ),
      ),
    );

    expect(find.text('Cricket Hub'), findsOneWidget);
  });
}
