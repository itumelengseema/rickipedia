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
}
