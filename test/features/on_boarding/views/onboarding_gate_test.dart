import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/providers/character_controller.dart';
import 'package:rickipedia/features/character/views/characters_page.dart';
import 'package:rickipedia/features/on_boarding/providers/onboarding_provider.dart';
import 'package:rickipedia/features/on_boarding/repositories/onboarding_repository.dart';
import 'package:rickipedia/features/on_boarding/views/on_boarding_page.dart';
import 'package:rickipedia/features/on_boarding/views/onboarding_gate.dart';
import 'package:rickipedia/theme/app_theme.dart';

class FakeGateRepository implements OnboardingRepository {
  bool completed;

  FakeGateRepository({this.completed = false});

  @override
  Future<bool> isCompleted() async => completed;

  @override
  Future<void> complete() async {
    completed = true;
  }
}

// Avoid network requests when CharactersPage opens.
class FakeCharacterController extends CharacterController {
  @override
  Future<CharacterResponse> build() async {
    return CharacterResponse(
      count: 0,
      pages: 1,
      next: null,
      prev: null,
      characters: [],
    );
  }
}

void main() {
  Future<void> pumpGate(
    WidgetTester tester,
    FakeGateRepository repository,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          onboardingRepositoryProvider.overrideWithValue(repository),
          characterControllerProvider.overrideWith(FakeCharacterController.new),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const OnboardingGate(),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  testWidgets('new users see onboarding', (tester) async {
    await pumpGate(tester, FakeGateRepository());

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(CharactersPage), findsNothing);
  });

  testWidgets('returning users bypass onboarding', (tester) async {
    await pumpGate(tester, FakeGateRepository(completed: true));

    expect(find.byType(CharactersPage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
  });

  testWidgets('Skip saves completion and opens Characters', (tester) async {
    final repository = FakeGateRepository();

    await pumpGate(tester, repository);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(repository.completed, isTrue);
    expect(find.byType(CharactersPage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);

    final context = tester.element(find.byType(CharactersPage));
    expect(Navigator.of(context).canPop(), isFalse);
  });

  testWidgets('Get started saves completion and opens Characters', (
    tester,
  ) async {
    final repository = FakeGateRepository();

    await pumpGate(tester, repository);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(repository.completed, isTrue);
    expect(find.byType(CharactersPage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);

    final context = tester.element(find.byType(CharactersPage));
    expect(Navigator.of(context).canPop(), isFalse);
  });
}
