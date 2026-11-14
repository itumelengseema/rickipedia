import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/on_boarding/providers/onboarding_provider.dart';
import 'package:rickipedia/features/on_boarding/repositories/onboarding_repository.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  bool completed;
  bool failOnSave;
  int saveCalls = 0;

  FakeOnboardingRepository({this.completed = false, this.failOnSave = false});

  @override
  Future<bool> isCompleted() async {
    return completed;
  }

  @override
  Future<void> complete() async {
    saveCalls++;

    if (failOnSave) {
      throw Exception('Could not save completion');
    }

    completed = true;
  }
}

void main() {
  late FakeOnboardingRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeOnboardingRepository();

    container = ProviderContainer(
      overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('new user starts with onboarding incomplete', () async {
    final completed = await container.read(onboardingProvider.future);

    expect(completed, isFalse);
  });

  test('returning user starts with onboarding complete', () async {
    repository.completed = true;

    final completed = await container.read(onboardingProvider.future);

    expect(completed, isTrue);
  });

  test('completion saves through the repository and updates state', () async {
    await container.read(onboardingProvider.future);

    await container.read(onboardingProvider.notifier).completeOnboarding();

    expect(repository.saveCalls, 1);
    expect(repository.completed, isTrue);
    expect(container.read(onboardingProvider).requireValue, isTrue);
  });

  test('failed save keeps onboarding incomplete and allows retry', () async {
    await container.read(onboardingProvider.future);
    repository.failOnSave = true;

    await expectLater(
      container.read(onboardingProvider.notifier).completeOnboarding(),
      throwsA(isA<Exception>()),
    );

    expect(repository.completed, isFalse);
    expect(container.read(onboardingProvider).requireValue, isFalse);

    repository.failOnSave = false;

    await container.read(onboardingProvider.notifier).completeOnboarding();

    expect(repository.saveCalls, 2);
    expect(container.read(onboardingProvider).requireValue, isTrue);
  });

  test('a fresh container reads previously saved completion', () async {
    await container.read(onboardingProvider.future);

    await container.read(onboardingProvider.notifier).completeOnboarding();

    final freshContainer = ProviderContainer(
      overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(freshContainer.dispose);

    expect(await freshContainer.read(onboardingProvider.future), isTrue);
  });
}
