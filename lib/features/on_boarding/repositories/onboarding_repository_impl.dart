import 'package:rickipedia/features/on_boarding/data/onboarding_local_data_source.dart';
import 'package:rickipedia/features/on_boarding/repositories/onboarding_repository.dart';

class OnboardingRepositoryImpl  implements OnboardingRepository{

  final OnboardingLocalDataSource _localDataSource;

  OnboardingRepositoryImpl( this._localDataSource);

  @override
  Future<void> complete() {
    return _localDataSource.complete();
  }

  @override
  Future<bool> isCompleted() {
   return _localDataSource.isCompleted();
  }
}