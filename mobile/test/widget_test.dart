// This is a basic Flutter test file that comes with the project
// The actual tests are organized in separate files in the test/ directory

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:austin_food_club_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AustinFoodClubApp());

    // Verify that the app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}