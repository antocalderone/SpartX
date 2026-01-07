// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:smx/main.dart';
import 'package:smx/metronome_service.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => MetronomeService(),
        child: const SheetMusicApp(),
      ),
    );

    // At this point, the app should have rendered successfully.
    // We can add more specific tests here in the future.
    expect(find.byType(SheetMusicApp), findsOneWidget);
  });
}
