import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/providers/character_controller.dart';
import 'package:rickipedia/features/character/views/characters_page.dart';
import 'package:rickipedia/features/on_boarding/providers/onboarding_provider.dart';
import 'package:rickipedia/features/on_boarding/views/on_boarding_page.dart';
import 'package:rickipedia/features/on_boarding/views/onboarding_gate.dart';
import 'package:rickipedia/theme/app_theme.dart';

import '../../../support/onboarding_test_fakes.dart';

void main() {
  Future<void> pumpGate(
    WidgetTester tester,
    ControlledOnboardingRepository repository,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        // Disable automatic retry so the explicit Retry button is tested.
        retry: (retryCount, error) => null,
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          characterControllerProvider.overrideWith(
            EmptyOnboardingCharacterController.new,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingGate(),
        ),
      ),
    );
  }

  testWidgets(
    'shows loading without flashing onboarding before a saved result',
    (tester) async {
      final repository = ControlledOnboardingRepository();
      final pendingRead = Completer<bool>();
      repository.pendingRead = pendingRead;
      await pumpGate(tester, repository);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.byType(CharactersPage), findsNothing);

      pendingRead.complete(true);
      await tester.pumpAndSettle();

      expect(find.byType(CharactersPage), findsOneWidget);
      expect(find.byType(OnboardingPage), findsNothing);
    },
  );

  testWidgets('failed read shows Retry and recovers after tapping it', (
    tester,
  ) async {
    final repository = ControlledOnboardingRepository()..failRead = true;
    await pumpGate(tester, repository);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not load your preferences'),
      findsOneWidget,
    );
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(CharactersPage), findsNothing);

    repository.failRead = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(repository.readCalls, 2);
  });

  testWidgets(
    'failed save keeps onboarding visible and allows another attempt',
    (tester) async {
      final repository = ControlledOnboardingRepository()..failSave = true;
      await pumpGate(tester, repository);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.byType(CharactersPage), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Could not save your progress'),
        findsOneWidget,
      );
      expect(repository.completed, isFalse);

      // Let the snackbar expire so it cannot cover the button on retry.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      repository.failSave = false;
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(repository.saveCalls, 2);
      expect(find.byType(CharactersPage), findsOneWidget);
    },
  );

  testWidgets('repeated Skip taps while saving issue only one write', (
    tester,
  ) async {
    final repository = ControlledOnboardingRepository();
    final pendingSave = Completer<void>();
    repository.pendingSave = pendingSave;
    await pumpGate(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.tap(find.text('Skip'));
    await tester.pump();

    expect(repository.saveCalls, 1);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(CharactersPage), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pendingSave.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CharactersPage), findsOneWidget);
  });

  testWidgets('removing the gate during save causes no widget exception', (
    tester,
  ) async {
    final repository = ControlledOnboardingRepository();
    final pendingSave = Completer<void>();
    repository.pendingSave = pendingSave;
    await pumpGate(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pendingSave.complete();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(repository.completed, isTrue);
  });
}
