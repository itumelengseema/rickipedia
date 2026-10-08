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

  @override
  Future<CharacterResponse> fetchCharacters({int page = 4, String? name}) {
    return _responses[fetchCalls++]();
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

Future<void> pumpPage(
  WidgetTester tester,
  CharacterRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
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
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Failed to load characters'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('tapping Retry requests again and displays recovered data', (
      tester,
    ) async {
      final retryRequest = Completer<CharacterResponse>();
      final repository = FakeCharacterRepository([
        () async => throw Exception('request failed'),
        () => retryRequest.future,
      ]);

      await pumpPage(tester, repository);
      await tester.pump();
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
  });
}
