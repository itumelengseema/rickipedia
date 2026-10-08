import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/providers/character_providers.dart';
import 'package:rickipedia/features/character/repositories/character_repository.dart';

class CharacterSearchController extends AsyncNotifier<CharacterResponse?> {
  late final CharacterRepository _repository;
  Timer? _debounceTimer;

  @override
  FutureOr<CharacterResponse?> build() {
    _repository = ref.watch(characterRepositoryProvider);
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return null;
  }

  void search(String value) {
    final query = value.trim();

    _debounceTimer?.cancel();

    if (query.length < 2) {
      state = const AsyncData(null);
      return;
    }
    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      state = const AsyncLoading();

      state = await AsyncValue.guard(() {
        return _repository.fetchCharacters(name: query);
      });
    });
  }
}

final characterSearchControllerProvider =
    AsyncNotifierProvider.autoDispose<
      CharacterSearchController,
      CharacterResponse?
    >(CharacterSearchController.new);
