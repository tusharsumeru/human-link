import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daivajna_census/app.dart';

void main() {
  testWidgets('App boots to a MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const DaivajnaApp());
    expect(find.byType(MaterialApp), findsWidgets);
  });
}
