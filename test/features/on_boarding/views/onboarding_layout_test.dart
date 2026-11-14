import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/on_boarding/data/onboarding_items.dart';
import 'package:rickipedia/features/on_boarding/models/onboarding_items.dart';
import 'package:rickipedia/features/on_boarding/views/on_boarding_page.dart';
import 'package:rickipedia/shared/widgets/onboarding_slide.dart';
import 'package:rickipedia/theme/app_theme.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required VoidCallback onCompleted,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: OnboardingPage(onCompleted: onCompleted),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final scenario in [
    (name: 'small phone', size: const Size(320, 568), scale: 1.0),
    (name: 'large accessibility text', size: const Size(320, 568), scale: 2.0),
    (name: 'short landscape screen', size: const Size(640, 360), scale: 1.0),
  ]) {
    testWidgets('all slides work on ${scenario.name}', (tester) async {
      var completions = 0;
      await pumpPage(
        tester,
        size: scenario.size,
        textScale: scenario.scale,
        onCompleted: () => completions++,
      );

      for (var index = 0; index < onboardingItems.length; index++) {
        expect(tester.takeException(), isNull);
        final label = index == onboardingItems.length - 1
            ? 'Get started'
            : 'Next';
        expect(find.text(label).hitTestable(), findsOneWidget);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      expect(tester.takeException(), isNull);
      expect(completions, 1);
    });
  }

  testWidgets('page indicator announces the selected page after navigation', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    try {
      await pumpPage(
        tester,
        size: const Size(400, 800),
        textScale: 1,
        onCompleted: () {},
      );

      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Page 3 of 3'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('long slide content remains reachable by scrolling', (
    tester,
  ) async {
    final description = List.filled(
      20,
      'Discover characters and explore their stories.',
    ).join(' ');

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              height: 260,
              child: OnboardingSlide(
                item: OnboardingItem(
                  imageUrl: '',
                  title: 'A longer introduction to the Rickipedia multiverse',
                  description: description,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    final viewport = tester.getRect(find.byType(SingleChildScrollView));
    final textBottom = tester.getBottomRight(find.text(description)).dy;
    expect(textBottom, greaterThan(viewport.top));
    expect(textBottom, lessThanOrEqualTo(viewport.bottom + 0.1));
    expect(tester.takeException(), isNull);
  });
}
