import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rickipedia/features/on_boarding/data/onboarding_local_data_source.dart';
import 'package:rickipedia/features/on_boarding/repositories/onboarding_repository.dart';
import 'package:rickipedia/features/on_boarding/repositories/onboarding_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingLocalDataSourceProvider = Provider<OnboardingLocalDataSource>((
  ref,
) {
  return OnboardingLocalDataSource(SharedPreferencesAsync());
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepositoryImpl(ref.watch(onboardingLocalDataSourceProvider));
});

final onboardingProvider = AsyncNotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);

class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    final repository = ref.watch(onboardingRepositoryProvider);
    return repository.isCompleted();
  }

  Future<void> completeOnboarding() async {
    final dataSource = ref.read(onboardingLocalDataSourceProvider);

    await dataSource.complete();

    if (!ref.mounted) return;

    state = const AsyncData(true);
  }
}
