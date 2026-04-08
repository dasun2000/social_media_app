// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:social_media_app/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ConnectApp());

    // Allow time for the widget to render and initial futures to complete
    await tester.pumpAndSettle();

    // Verify that our app renders (we can check for a common element or just ensure it pumps without crashing).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
