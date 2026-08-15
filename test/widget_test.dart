import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('VonoTalky test environment smoke test', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('VonoTalky'),
        ),
      ),
    );

    expect(find.text('VonoTalky'), findsOneWidget);
  });
}