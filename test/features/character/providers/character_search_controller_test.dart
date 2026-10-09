import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/models/character_model.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/models/location_model.dart';
import 'package:rickipedia/features/character/models/origin_model.dart';
import 'package:rickipedia/features/character/providers/character_providers.dart';
import 'package:rickipedia/features/character/providers/character_search_controller.dart';
import 'package:rickipedia/features/character/repositories/character_repository.dart';

class FakeCharacterRepository implements CharacterRepository {
  FakeCharacterRepository({required this.onFetch});

  final Future<CharacterResponse> Function(String? name) onFetch;
  final List<String?> searchedNames = [];

  @override
  Future<CharacterResponse> fetchCharacters({int page = 1, String? name}) {
    searchedNames.add(name);
    return onFetch(name);
  }
}

CharacterResponse responseWith(List<Character> characters) => CharacterResponse(
  count: characters.length,
  pages: characters.isEmpty ? 0 : 1,
  next: null,
  prev: null,
  characters: characters,
);

Character character({required int id, required String name}) => Character(
  id: id,
  name: name,
  status: 'Alive',
  species: 'Human',
  type: '',
  gender: 'Male',
  origin: Origin(name: 'Earth', url: ''),
  location: Location(name: 'Earth', url: ''),
  image: '',
  episode: const [],
  url: '',
  created: '2017-11-04T18:48:46.250Z',
);

void main() {
  group('CharacterSearchController', () {
    late FakeCharacterRepository repository;
    late ProviderContainer container;
    ProviderSubscription<AsyncValue<CharacterResponse?>>? subscription;

    void createContainer({
      Future<CharacterResponse> Function(String? name)? onFetch,
    }) {
      repository = FakeCharacterRepository(
        onFetch: onFetch ?? (_) async => responseWith([]),
      );
      container = ProviderContainer(
        overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      );
      subscription = container.listen(
        characterSearchControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
    }

    tearDown(() {
      subscription?.close();
      container.dispose();
    });

    testWidgets('initial state is AsyncData containing null', (tester) async {
      createContainer();
      await tester.pump(const Duration(milliseconds: 1));

      final state = container.read(characterSearchControllerProvider);

      expect(state, isA<AsyncData<CharacterResponse?>>());
      expect(state.value, isNull);
      expect(repository.searchedNames, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets(
      'query shorter than two trimmed characters does not call repository',
      (tester) async {
        createContainer();
        await tester.pump();

        container
            .read(characterSearchControllerProvider.notifier)
            .search(' r ');
        await tester.pump(const Duration(milliseconds: 500));

        expect(repository.searchedNames, isEmpty);
        expect(container.read(characterSearchControllerProvider).value, isNull);
      },
    );

    testWidgets(
      'valid query calls fetchCharacters with trimmed name after debounce',
      (tester) async {
        createContainer();
        await tester.pump();

        container
            .read(characterSearchControllerProvider.notifier)
            .search('  Rick  ');
        await tester.pump(const Duration(milliseconds: 499));
        expect(repository.searchedNames, isEmpty);

        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();

        expect(repository.searchedNames, ['Rick']);
      },
    );

    testWidgets('rapid query changes request only the latest query', (
      tester,
    ) async {
      createContainer();
      await tester.pump();

      container.read(characterSearchControllerProvider.notifier).search('Ri');
      await tester.pump(const Duration(milliseconds: 300));
      container.read(characterSearchControllerProvider.notifier).search('Rick');
      await tester.pump(const Duration(milliseconds: 499));
      expect(repository.searchedNames, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(repository.searchedNames, ['Rick']);
    });

    testWidgets(
      'successful request produces AsyncData with returned characters',
      (tester) async {
        final expected = responseWith([character(id: 1, name: 'Rick Sanchez')]);
        createContainer(onFetch: (_) async => expected);
        await tester.pump();

        container
            .read(characterSearchControllerProvider.notifier)
            .search('Rick');
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();

        final state = container.read(characterSearchControllerProvider);
        expect(state, isA<AsyncData<CharacterResponse?>>());
        expect(state.value, same(expected));
        expect(state.value!.characters.single.name, 'Rick Sanchez');
      },
    );

    testWidgets('repository exception produces AsyncError', (tester) async {
      final error = Exception('search failed');
      createContainer(onFetch: (_) async => throw error);
      await tester.pump();

      container.read(characterSearchControllerProvider.notifier).search('Rick');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      final state = container.read(characterSearchControllerProvider);
      expect(state, isA<AsyncError<CharacterResponse?>>());
      expect(state.error, same(error));
    });

    testWidgets('a stale response cannot replace results for a newer query', (
      tester,
    ) async {
      final rick = Completer<CharacterResponse>();
      final morty = Completer<CharacterResponse>();
      createContainer(
        onFetch: (name) => name == 'Rick' ? rick.future : morty.future,
      );
      await tester.pump();

      container.read(characterSearchControllerProvider.notifier).search('Rick');
      await tester.pump(const Duration(milliseconds: 500));
      container
          .read(characterSearchControllerProvider.notifier)
          .search('Morty');
      await tester.pump(const Duration(milliseconds: 500));

      morty.complete(responseWith([character(id: 2, name: 'Morty Smith')]));
      await tester.pump();
      rick.complete(responseWith([character(id: 1, name: 'Rick Sanchez')]));
      await tester.pump();

      expect(repository.searchedNames, ['Rick', 'Morty']);
      expect(
        container
            .read(characterSearchControllerProvider)
            .value!
            .characters
            .single
            .name,
        'Morty Smith',
      );
    });

    testWidgets(
      "search('') cancels pending debounce and resets state to AsyncData(null)",
      (tester) async {
        createContainer();
        await tester.pump();

        container
            .read(characterSearchControllerProvider.notifier)
            .search('Rick');
        await tester.pump(const Duration(milliseconds: 300));
        container.read(characterSearchControllerProvider.notifier).search('');

        final state = container.read(characterSearchControllerProvider);
        expect(state, isA<AsyncData<CharacterResponse?>>());
        expect(state.value, isNull);

        await tester.pump(const Duration(milliseconds: 500));
        expect(repository.searchedNames, isEmpty);
      },
    );

    testWidgets('disposing autoDispose provider cancels pending debounce', (
      tester,
    ) async {
      createContainer();
      await tester.pump();

      container.read(characterSearchControllerProvider.notifier).search('Rick');
      await tester.pump(const Duration(milliseconds: 300));
      subscription!.close();
      subscription = null;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.searchedNames, isEmpty);
    });
  });
}
