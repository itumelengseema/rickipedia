import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/character_response_model.dart';
import '../repositories/character_repository.dart';
import 'character_providers.dart';

class CharacterController extends AsyncNotifier<CharacterResponse> {
  late final CharacterRepository _repository;

  @override
  Future<CharacterResponse> build() async {
    _repository = ref.watch(characterRepositoryProvider);

    return _repository.fetchCharacters();
  }

  Future<void> retry() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() => _repository.fetchCharacters());
  }
}

final characterControllerProvider =
    AsyncNotifierProvider<CharacterController, CharacterResponse>(
      CharacterController.new,
    );
