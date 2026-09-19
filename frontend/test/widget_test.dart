// Widget tests for MPLADS Sanchalan.
// The auto-generated counter test is removed as it targets a generic
// counter app. Placeholder smoke test to ensure the app builds.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mplads_sanchalan/main.dart';

void main() {
  testWidgets('App starts without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const MpladsSanchalanApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
