import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/on_boarding/providers/onboarding_provider.dart';

import '../../../support/onboarding_test_fakes.dart';

void main() {
  late ControlledOnboardingRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = ControlledOnboardingRepository();
    container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  test('initial state stays loading until storage responds', () async {
    final pendingRead = Completer<bool>();
    repository.pendingRead = pendingRead;

    final result = container.read(onboardingProvider.future);
    expect(container.read(onboardingProvider).isLoading, isTrue);

    pendingRead.complete(false);
    expect(await result, isFalse);
  });

  test('failed initial read exposes an error and can be retried', () async {
    repository.failRead = true;

    await expectLater(
      container.read(onboardingProvider.future),
      throwsA(isA<StateError>()),
    );
    expect(container.read(onboardingProvider).hasError, isTrue);

    repository.failRead = false;
    container.invalidate(onboardingProvider);

    expect(await container.read(onboardingProvider.future), isFalse);
    expect(repository.readCalls, 2);
  });

  test('completion is not published before saving finishes', () async {
    await container.read(onboardingProvider.future);
    final pendingSave = Completer<void>();
    repository.pendingSave = pendingSave;

    final saving = container
        .read(onboardingProvider.notifier)
        .completeOnboarding();

    expect(repository.saveCalls, 1);
    expect(container.read(onboardingProvider).requireValue, isFalse);

    pendingSave.complete();
    await saving;

    expect(container.read(onboardingProvider).requireValue, isTrue);
  });

  test('disposing the provider during save does not update disposed state', () async {
    // Use a separate container here so tearDown only disposes the fixture once.
    final disposable = ProviderContainer(
      overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
    );
    await disposable.read(onboardingProvider.future);
    final pendingSave = Completer<void>();
    repository.pendingSave = pendingSave;

    final saving = disposable
        .read(onboardingProvider.notifier)
        .completeOnboarding();
    disposable.dispose();
    pendingSave.complete();

    await expectLater(saving, completes);
    expect(repository.completed, isTrue);
  });
}
