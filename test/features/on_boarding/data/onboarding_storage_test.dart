import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:rickipedia/features/on_boarding/data/onboarding_local_data_source.dart';
import 'package:rickipedia/features/on_boarding/providers/onboarding_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesAsyncPlatform? originalPlatform;
  late SharedPreferencesAsync preferences;
  late OnboardingLocalDataSource dataSource;

  setUp(() {
    originalPlatform = SharedPreferencesAsyncPlatform.instance;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    preferences = SharedPreferencesAsync();
    dataSource = OnboardingLocalDataSource(preferences);
  });

  tearDown(() {
    SharedPreferencesAsyncPlatform.instance = originalPlatform;
  });

  test('missing preference means onboarding is incomplete', () async {
    expect(await dataSource.isCompleted(), isFalse);
    expect(await preferences.containsKey('onboarding_completed'), isFalse);
  });

  test('saved false remains incomplete', () async {
    await preferences.setBool('onboarding_completed', false);
    expect(await dataSource.isCompleted(), isFalse);
  });

  test('saved true means onboarding is complete', () async {
    await preferences.setBool('onboarding_completed', true);
    expect(await dataSource.isCompleted(), isTrue);
  });

  test(
    'completion writes the expected key and preserves other preferences',
    () async {
      await preferences.setString('theme', 'dark');
      await dataSource.complete();

      expect(await preferences.getBool('onboarding_completed'), isTrue);
      expect(await preferences.getString('theme'), 'dark');
    },
  );

  test('a fresh data source reads completion from the same store', () async {
    await dataSource.complete();
    final freshSource = OnboardingLocalDataSource(SharedPreferencesAsync());

    expect(await freshSource.isCompleted(), isTrue);
  });

  test('clearing app preferences restores first-launch behaviour', () async {
    await dataSource.complete();
    await preferences.clear();

    final freshSource = OnboardingLocalDataSource(SharedPreferencesAsync());
    expect(await freshSource.isCompleted(), isFalse);
  });

  test(
    'corrupt preference type is surfaced instead of silently accepted',
    () async {
      await preferences.setString('onboarding_completed', 'true');
      await expectLater(dataSource.isCompleted(), throwsA(isA<TypeError>()));
    },
  );

  test(
    'real provider and repository wiring survives container recreation',
    () async {
      final firstContainer = ProviderContainer();
      try {
        expect(await firstContainer.read(onboardingProvider.future), isFalse);
        await firstContainer
            .read(onboardingProvider.notifier)
            .completeOnboarding();
        expect(await preferences.getBool('onboarding_completed'), isTrue);
      } finally {
        firstContainer.dispose();
      }

      final secondContainer = ProviderContainer();
      addTearDown(secondContainer.dispose);
      expect(await secondContainer.read(onboardingProvider.future), isTrue);
    },
  );
}
