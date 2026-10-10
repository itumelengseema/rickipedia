import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/character_response_model.dart';
import '../repositories/character_repository.dart';
import 'character_providers.dart';
import 'pagination_provider.dart';

class CharacterController extends AsyncNotifier<CharacterResponse> {
  late CharacterRepository _repository;

  int _requestVersion = 0;

  @override
  Future<CharacterResponse> build() async {
    _repository = ref.watch(characterRepositoryProvider);

    return _repository.fetchCharacters();
  }

  Future<void> retry() => refresh();

  Future<void> refresh() async {
    final requestVersion = ++_requestVersion;

    ref.read(paginationStateProvider.notifier).reset();

    state = const AsyncLoading();

    final result = await AsyncValue.guard(() => _repository.fetchCharacters());

    if (!ref.mounted || requestVersion != _requestVersion) {
      return;
    }

    state = result;
  }

  Future<void> loadNextPage() async {
    if (state.isLoading) return;

    final current = state.value;
    final pagination = ref.read(paginationStateProvider);

    // Don't request another page if there is no next page
    // or if a request is already in progress.
    if (current == null || current.next == null || pagination.isLoading) {
      return;
    }
    final requestVersion = _requestVersion;

    ref.read(paginationStateProvider.notifier).startLoading();

    try {
      final nextPage = await _repository.fetchCharacters(
        page: _pageFrom(current.next!),
      );

      if (!ref.mounted || requestVersion != _requestVersion) return;

      state = AsyncData(
        CharacterResponse(
          count: nextPage.count,
          pages: nextPage.pages,
          next: nextPage.next,
          prev: nextPage.prev,
          characters: [...current.characters, ...nextPage.characters],
        ),
      );

      ref.read(paginationStateProvider.notifier).reset();
    } catch (error) {
      if (!ref.mounted || requestVersion != _requestVersion) return;

      ref.read(paginationStateProvider.notifier).setError(error);
    }
  }

  int _pageFrom(String nextUrl) {
    return int.tryParse(Uri.parse(nextUrl).queryParameters['page'] ?? '') ?? 1;
  }
}

final characterControllerProvider =
    AsyncNotifierProvider<CharacterController, CharacterResponse>(
      CharacterController.new,
    );
