import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/providers/character_controller.dart';
import 'package:rickipedia/features/character/providers/character_providers.dart';
import 'package:rickipedia/features/character/providers/pagination_provider.dart';

import '../../../support/character_fixtures.dart';
import '../../../support/fakes.dart';

void main() {
  ProviderContainer containerFor(FakeCharacterRepository repository) {
    final container = ProviderContainer(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('appends the next page to existing characters', () async {
    final first = responseFixture('characters_page_1.json');
    final second = responseFixture('characters_page_2.json');
    final repository = FakeCharacterRepository(
      (page, _) async => page == 1 ? first : second,
    );
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);

    await container.read(characterControllerProvider.notifier).loadNextPage();

    expect(repository.requests.map((request) => request.page), [1, 2]);
    expect(
      container
          .read(characterControllerProvider)
          .requireValue
          .characters
          .map((character) => character.name),
      ['Rick Sanchez', 'Morty Smith'],
    );
  });

  test('does not request another page after the last page', () async {
    final repository = FakeCharacterRepository(
      (_, _) async => responseFixture('characters_page_2.json'),
    );
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);

    await container.read(characterControllerProvider.notifier).loadNextPage();

    expect(repository.requests, hasLength(1));
  });

  test('prevents duplicate requests while a page is loading', () async {
    final nextPage = Completer<CharacterResponse>();
    final repository = FakeCharacterRepository((page, _) {
      if (page == 1) {
        return Future.value(responseFixture('characters_page_1.json'));
      }
      return nextPage.future.then((value) => value);
    });
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);

    final firstRequest = container
        .read(characterControllerProvider.notifier)
        .loadNextPage();
    final duplicate = container
        .read(characterControllerProvider.notifier)
        .loadNextPage();
    await duplicate;

    expect(repository.requests, hasLength(2));
    nextPage.complete(responseFixture('characters_page_2.json'));
    await firstRequest;
  });

  test('keeps loaded data and retries failed pagination explicitly', () async {
    var pageTwoAttempts = 0;
    final repository = FakeCharacterRepository((page, _) async {
      if (page == 1) return responseFixture('characters_page_1.json');
      pageTwoAttempts++;
      if (pageTwoAttempts == 1) throw Exception('offline');
      return responseFixture('characters_page_2.json');
    });
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);
    final controller = container.read(characterControllerProvider.notifier);

    await controller.loadNextPage();
    expect(
      container.read(characterControllerProvider).requireValue.characters,
      hasLength(1),
    );
    expect(container.read(paginationStateProvider).error, isNotNull);

    await controller.loadNextPage();
    expect(repository.requests, hasLength(2));
    expect(container.read(paginationStateProvider).error, isNotNull);

    await controller.retryNextPage();
    expect(
      container.read(characterControllerProvider).requireValue.characters,
      hasLength(2),
    );
    expect(container.read(paginationStateProvider).error, isNull);
  });

  test('ignores an old pagination success after refresh', () async {
    final nextPage = Completer<CharacterResponse>();
    final refreshed = Completer<CharacterResponse>();
    var pageOneRequests = 0;
    final repository = FakeCharacterRepository((page, _) {
      if (page == 2) return nextPage.future;

      pageOneRequests++;
      if (pageOneRequests == 1) {
        return Future.value(responseFixture('characters_page_1.json'));
      }
      return refreshed.future;
    });
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);
    final controller = container.read(characterControllerProvider.notifier);

    final paginationRequest = controller.loadNextPage();
    final refreshRequest = controller.refresh();
    final refreshedResponse = characterResponse(
      characters: [characterFixture(id: 3, name: 'Summer Smith')],
    );
    refreshed.complete(refreshedResponse);
    await refreshRequest;

    nextPage.complete(responseFixture('characters_page_2.json'));
    await paginationRequest;

    expect(
      container.read(characterControllerProvider).requireValue,
      same(refreshedResponse),
    );
    expect(container.read(paginationStateProvider).isLoading, isFalse);
    expect(container.read(paginationStateProvider).error, isNull);
  });

  test('ignores an old pagination error after refresh', () async {
    final nextPage = Completer<CharacterResponse>();
    final refreshed = Completer<CharacterResponse>();
    var pageOneRequests = 0;
    final repository = FakeCharacterRepository((page, _) {
      if (page == 2) return nextPage.future;

      pageOneRequests++;
      if (pageOneRequests == 1) {
        return Future.value(responseFixture('characters_page_1.json'));
      }
      return refreshed.future;
    });
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);
    final controller = container.read(characterControllerProvider.notifier);

    final paginationRequest = controller.loadNextPage();
    final refreshRequest = controller.refresh();
    final refreshedResponse = characterResponse(
      characters: [characterFixture(id: 3, name: 'Summer Smith')],
    );
    refreshed.complete(refreshedResponse);
    await refreshRequest;

    nextPage.completeError(Exception('stale pagination failure'));
    await paginationRequest;

    expect(
      container.read(characterControllerProvider).requireValue,
      same(refreshedResponse),
    );
    expect(container.read(paginationStateProvider).isLoading, isFalse);
    expect(container.read(paginationStateProvider).error, isNull);
  });

  test('preserves loaded characters while refresh is pending', () async {
    final initial = responseFixture('characters_page_1.json');
    final refresh = Completer<CharacterResponse>();
    var pageOneRequests = 0;
    final repository = FakeCharacterRepository((page, _) {
      pageOneRequests++;
      return pageOneRequests == 1 ? Future.value(initial) : refresh.future;
    });
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);

    final refreshRequest = container
        .read(characterControllerProvider.notifier)
        .refresh();

    final pendingState = container.read(characterControllerProvider);
    expect(pendingState.isLoading, isTrue);
    expect(pendingState.requireValue, same(initial));

    refresh.complete(responseFixture('characters_page_2.json'));
    await refreshRequest;
  });

  test('preserves loaded characters when refresh fails', () async {
    final initial = responseFixture('characters_page_1.json');
    final error = Exception('refresh failed');
    var pageOneRequests = 0;
    final repository = FakeCharacterRepository((page, _) async {
      pageOneRequests++;
      if (pageOneRequests == 1) return initial;
      throw error;
    });
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);

    await container.read(characterControllerProvider.notifier).refresh();

    final failedState = container.read(characterControllerProvider);
    expect(failedState.hasError, isTrue);
    expect(failedState.error, same(error));
    expect(failedState.requireValue, same(initial));
  });

  test('replaces loaded characters when refresh succeeds', () async {
    final initial = responseFixture('characters_page_1.json');
    final refreshed = responseFixture('characters_page_2.json');
    var pageOneRequests = 0;
    final repository = FakeCharacterRepository((page, _) async {
      pageOneRequests++;
      return pageOneRequests == 1 ? initial : refreshed;
    });
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);

    await container.read(characterControllerProvider.notifier).refresh();

    expect(
      container.read(characterControllerProvider).requireValue,
      same(refreshed),
    );
  });

  test('does not paginate while refresh is pending', () async {
    final initial = responseFixture('characters_page_1.json');
    final refresh = Completer<CharacterResponse>();
    var pageOneRequests = 0;
    final repository = FakeCharacterRepository((page, _) {
      pageOneRequests++;
      return pageOneRequests == 1 ? Future.value(initial) : refresh.future;
    });
    final container = containerFor(repository);
    await container.read(characterControllerProvider.future);
    final controller = container.read(characterControllerProvider.notifier);

    final refreshRequest = controller.refresh();
    await controller.loadNextPage();

    expect(repository.requests.map((request) => request.page), [1, 1]);

    refresh.complete(responseFixture('characters_page_2.json'));
    await refreshRequest;
  });

  test('appends only unique character IDs in order', () async {
    final first = characterResponse(
      characters: [
        characterFixture(id: 1, name: 'Rick Sanchez'),
        characterFixture(id: 2, name: 'Morty Smith'),
      ],
      pages: 2,
      next: 'https://rickandmortyapi.com/api/character?page=2',
    );
    final second = characterResponse(
      characters: [
        characterFixture(id: 2, name: 'Morty Smith'),
        characterFixture(id: 3, name: 'Summer Smith'),
        characterFixture(id: 3, name: 'Summer Smith'),
        characterFixture(id: 4, name: 'Beth Smith'),
      ],
      pages: 2,
      prev: 'https://rickandmortyapi.com/api/character?page=1',
    );
    final repository = FakeCharacterRepository(
      (page, _) async => page == 1 ? first : second,
    );
    final container = containerFor(repository);

    await container.read(characterControllerProvider.future);
    await container.read(characterControllerProvider.notifier).loadNextPage();

    expect(
      container
          .read(characterControllerProvider)
          .requireValue
          .characters
          .map((character) => character.id),
      [1, 2, 3, 4],
    );
  });
}
