import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/shared/widgets/primary_button.dart';

void main() {
  Widget buildButton({
    String label = 'Continue',
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PrimaryButton(
          label: label,
          onPressed: onPressed,
          isLoading: isLoading,
        ),
      ),
    );
  }

  testWidgets('shows its label and invokes the callback when tapped', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(buildButton(onPressed: () => presses++));

    expect(find.text('Continue'), findsOneWidget);
    await tester.tap(find.byType(PrimaryButton));

    expect(presses, 1);
  });

  testWidgets('is disabled when no callback is supplied', (tester) async {
    await tester.pumpWidget(buildButton());

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('shows progress and prevents taps while loading', (tester) async {
    var presses = 0;
    await tester.pumpWidget(
      buildButton(onPressed: () => presses++, isLoading: true),
    );

    expect(find.text('Continue'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(PrimaryButton));
    expect(presses, 0);
  });
}
