import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/providers/character_controller.dart';
import 'package:rickipedia/features/character/providers/character_providers.dart';
import 'package:rickipedia/features/character/repositories/character_repository.dart';

class FakeCharacterRepository implements CharacterRepository {
  FakeCharacterRepository(this._responses);

  final List<Future<CharacterResponse> Function()> _responses;
  int fetchCalls = 0;

  @override
  Future<CharacterResponse> fetchCharacters({int page = 1, String? name}) {
    final response = _responses[fetchCalls];
    fetchCalls++;
    return response();
  }
}

CharacterResponse emptyResponse({int count = 0}) => CharacterResponse(
  count: count,
  pages: 0,
  next: null,
  prev: null,
  characters: [],
);

ProviderContainer createContainer(CharacterRepository repository) {
  final container = ProviderContainer(
    overrides: [characterRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('CharacterController', () {
    test('starts in loading while the initial request is pending', () async {
      final request = Completer<CharacterResponse>();
      final repository = FakeCharacterRepository([() => request.future]);
      final container = createContainer(repository);

      final subscription = container.listen(
        characterControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      expect(container.read(characterControllerProvider).isLoading, isTrue);
      expect(repository.fetchCalls, 1);

      request.complete(emptyResponse());
      await container.read(characterControllerProvider.future);
    });

    test('loads characters from the repository when built', () async {
      final expected = emptyResponse(count: 2);
      final repository = FakeCharacterRepository([() async => expected]);
      final container = createContainer(repository);

      final result = await container.read(characterControllerProvider.future);

      expect(result, same(expected));
      expect(repository.fetchCalls, 1);
      expect(container.read(characterControllerProvider).value, same(expected));
    });

    test('exposes an empty successful response as data', () async {
      final expected = emptyResponse();
      final repository = FakeCharacterRepository([() async => expected]);
      final container = createContainer(repository);

      await container.read(characterControllerProvider.future);

      final state = container.read(characterControllerProvider);
      expect(state, isA<AsyncData<CharacterResponse>>());
      expect(state.requireValue.characters, isEmpty);
      expect(state.hasError, isFalse);
    });

    test('exposes an error when the initial request fails', () async {
      final error = Exception('request failed');
      final repository = FakeCharacterRepository([() async => throw error]);
      final container = createContainer(repository);

      final errorState = Completer<AsyncValue<CharacterResponse>>();
      final subscription = container.listen(characterControllerProvider, (
        _,
        state,
      ) {
        if (state.hasError && !errorState.isCompleted) {
          errorState.complete(state);
        }
      }, fireImmediately: true);
      addTearDown(subscription.close);

      final state = await errorState.future;
      expect(state.hasError, isTrue);
      expect(state.error, same(error));
    });

    test('retry emits loading then replaces the state with new data', () async {
      final initial = emptyResponse(count: 1);
      final retried = emptyResponse(count: 3);
      final retryCompleter = Completer<CharacterResponse>();
      final repository = FakeCharacterRepository([
        () async => initial,
        () => retryCompleter.future,
      ]);
      final container = createContainer(repository);
      await container.read(characterControllerProvider.future);

      final retry = container
          .read(characterControllerProvider.notifier)
          .retry();

      expect(container.read(characterControllerProvider).isLoading, isTrue);
      retryCompleter.complete(retried);
      await retry;

      expect(repository.fetchCalls, 2);
      expect(container.read(characterControllerProvider).value, same(retried));
    });

    test('retry captures repository errors in state', () async {
      final error = Exception('retry failed');
      final repository = FakeCharacterRepository([
        () async => emptyResponse(),
        () async => throw error,
      ]);
      final container = createContainer(repository);
      await container.read(characterControllerProvider.future);

      await container.read(characterControllerProvider.notifier).retry();

      final state = container.read(characterControllerProvider);
      expect(repository.fetchCalls, 2);
      expect(state.hasError, isTrue);
      expect(state.error, same(error));
    });
  });
}
