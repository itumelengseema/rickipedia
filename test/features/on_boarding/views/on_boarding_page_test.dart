import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/on_boarding/views/on_boarding_page.dart';
import 'package:rickipedia/theme/app_theme.dart';

void main() {
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    required VoidCallback onCompleted,
  }) async {
    // Use a portrait phone-sized viewport.
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: OnboardingPage(onCompleted: onCompleted),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('starts on the first slide', (tester) async {
    await pumpOnboarding(tester, onCompleted: () {});

    expect(find.text('Explore the multiverse').hitTestable(), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
  });

  testWidgets('Next advances to the second slide', (tester) async {
    var completionCalls = 0;

    await pumpOnboarding(tester, onCompleted: () => completionCalls++);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Explore episodes').hitTestable(), findsOneWidget);
    expect(completionCalls, 0);
  });

  testWidgets('swiping moves forward and backward', (tester) async {
    await pumpOnboarding(tester, onCompleted: () {});

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Explore episodes').hitTestable(), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Explore the multiverse').hitTestable(), findsOneWidget);
  });

  testWidgets('Skip calls onCompleted', (tester) async {
    var completionCalls = 0;

    await pumpOnboarding(tester, onCompleted: () => completionCalls++);

    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(completionCalls, 1);
  });

  testWidgets('Get started completes onboarding from the last slide', (
    tester,
  ) async {
    var completionCalls = 0;

    await pumpOnboarding(tester, onCompleted: () => completionCalls++);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Find your favourites').hitTestable(), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Skip'), findsNothing);
    expect(find.text('Get started'), findsOneWidget);
    expect(completionCalls, 0);

    await tester.tap(find.text('Get started'));
    await tester.pump();

    expect(completionCalls, 1);
  });
}
