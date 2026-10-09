import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/character_response_model.dart';
import '../repositories/character_repository.dart';
import 'character_providers.dart';

class CharacterController extends AsyncNotifier<CharacterResponse> {
  late final CharacterRepository _repository;
  bool _isLoadingMore = false;
  Object? _loadMoreError;

  bool get isLoadingMore => _isLoadingMore;
  Object? get loadMoreError => _loadMoreError;

  @override
  Future<CharacterResponse> build() async {
    _repository = ref.watch(characterRepositoryProvider);

    return _repository.fetchCharacters();
  }

  Future<void> retry() async {
    _isLoadingMore = false;
    _loadMoreError = null;
    state = const AsyncLoading();

    state = await AsyncValue.guard(() => _repository.fetchCharacters());
  }

  Future<void> loadNextPage() async {
    final current = state.value;
    if (current == null || current.next == null || _isLoadingMore) {
      return;
    }

    _isLoadingMore = true;
    _loadMoreError = null;
    state = AsyncData(current);

    try {
      final nextPage = await _repository.fetchCharacters(
        page: _pageFrom(current.next!),
      );
      if (!ref.mounted) return;

      state = AsyncData(
        CharacterResponse(
          count: nextPage.count,
          pages: nextPage.pages,
          next: nextPage.next,
          prev: nextPage.prev,
          characters: [...current.characters, ...nextPage.characters],
        ),
      );
    } catch (error) {
      if (!ref.mounted) return;
      _loadMoreError = error;
      state = AsyncData(current);
    } finally {
      _isLoadingMore = false;
      if (ref.mounted) {
        state = AsyncData(state.value ?? current);
      }
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
