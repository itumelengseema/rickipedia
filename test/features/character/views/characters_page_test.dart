import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/models/character_model.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/models/location_model.dart';
import 'package:rickipedia/features/character/models/origin_model.dart';
import 'package:rickipedia/features/character/providers/character_providers.dart';
import 'package:rickipedia/features/character/repositories/character_repository.dart';
import 'package:rickipedia/features/character/views/characters_page.dart';

class FakeCharacterRepository implements CharacterRepository {
  FakeCharacterRepository(this._responses);

  final List<Future<CharacterResponse> Function()> _responses;
  int fetchCalls = 0;
  final List<int> requestedPages = [];

  @override
  Future<CharacterResponse> fetchCharacters({int page = 1, String? name}) {
    requestedPages.add(page);
    return _responses[fetchCalls++]();
  }
}

CharacterResponse responseWith(
  List<Character> characters, {
  String? next,
  String? prev,
  int? count,
  int pages = 1,
}) => CharacterResponse(
  count: count ?? characters.length,
  pages: pages,
  next: next,
  prev: prev,
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

Future<void> pumpPage(
  WidgetTester tester,
  CharacterRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: CharactersPage()),
    ),
  );
}

void main() {
  group('CharactersPage', () {
    testWidgets('shows a loading indicator while characters are requested', (
      tester,
    ) async {
      final request = Completer<CharacterResponse>();
      final repository = FakeCharacterRepository([() => request.future]);

      await pumpPage(tester, repository);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repository.fetchCalls, 1);
    });

    testWidgets('shows character cards when the request succeeds', (
      tester,
    ) async {
      final repository = FakeCharacterRepository([
        () async => responseWith([
          character(id: 1, name: 'Rick Sanchez'),
          character(id: 2, name: 'Morty Smith'),
        ]),
      ]);

      await pumpPage(tester, repository);
      await tester.pump();

      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Morty Smith'), findsOneWidget);
      expect(find.text('Human'), findsNWidgets(2));
      expect(find.text('No characters found'), findsNothing);
    });

    testWidgets('shows the empty state when no characters are returned', (
      tester,
    ) async {
      final repository = FakeCharacterRepository([
        () async => responseWith([]),
      ]);

      await pumpPage(tester, repository);
      await tester.pump();

      expect(find.text('No characters found'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows an error state when the request fails', (tester) async {
      final repository = FakeCharacterRepository([
        () async => throw Exception('request failed'),
      ]);

      await pumpPage(tester, repository);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load characters'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('tapping Retry requests again and displays recovered data', (
      tester,
    ) async {
      final retryRequest = Completer<CharacterResponse>();
      final repository = FakeCharacterRepository([
        () => Future<CharacterResponse>.error(Exception('request failed')),
        () => retryRequest.future,
      ]);

      await pumpPage(tester, repository);
      await tester.pumpAndSettle();
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(repository.fetchCalls, 2);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Failed to load characters'), findsNothing);

      retryRequest.complete(
        responseWith([character(id: 1, name: 'Summer Smith')]),
      );
      await tester.pump();

      expect(find.text('Summer Smith'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('scrolling near the end loads and appends the next page', (
      tester,
    ) async {
      final nextPage = Completer<CharacterResponse>();
      final firstPageCharacters = List.generate(
        10,
        (index) => character(id: index + 1, name: 'Character ${index + 1}'),
      );
      final repository = FakeCharacterRepository([
        () async => responseWith(
          firstPageCharacters,
          count: 11,
          pages: 2,
          next: 'https://rickandmortyapi.com/api/character?page=2',
        ),
        () => nextPage.future,
      ]);

      await pumpPage(tester, repository);
      await tester.pump();
      expect(repository.requestedPages, [1]);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pump();

      expect(repository.requestedPages, [1, 2]);

      nextPage.complete(
        responseWith(
          [character(id: 11, name: 'Last Character')],
          count: 11,
          pages: 2,
          prev: 'https://rickandmortyapi.com/api/character?page=1',
        ),
      );
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Last Character'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Last Character'), findsOneWidget);
      expect(repository.requestedPages, [1, 2]);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
