import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/models/character_model.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/models/location_model.dart';
import 'package:rickipedia/features/character/models/origin_model.dart';
import 'package:rickipedia/features/character/providers/character_providers.dart';
import 'package:rickipedia/features/character/repositories/character_repository.dart';
import 'package:rickipedia/features/character/views/character_search_page.dart';

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
  image: 'https://example.test/character.png',
  episode: const [],
  url: '',
  created: '2017-11-04T18:48:46.250Z',
);

Future<void> cacheCharacterImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.transparent, BlendMode.src);
  final image = await recorder.endRecording().toImage(1, 1);
  final provider = NetworkImage('https://example.test/character.png');
  PaintingBinding.instance.imageCache.putIfAbsent(
    provider,
    () => OneFrameImageStreamCompleter(Future.value(ImageInfo(image: image))),
  );
}

Future<void> pumpSearchPage(
  WidgetTester tester,
  CharacterRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [characterRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: CharacterSearchPage()),
    ),
  );
  await tester.pump();
}

void main() {
  group('CharacterSearchPage', () {
    testWidgets('displays the initial search instruction', (tester) async {
      final repository = FakeCharacterRepository(
        onFetch: (_) async => responseWith([]),
      );

      await pumpSearchPage(tester, repository);

      expect(find.text('Search to find characters'), findsOneWidget);
      expect(find.text('No results found :('), findsNothing);
      expect(repository.searchedNames, isEmpty);
    });

    testWidgets('typing one character does not request the repository', (
      tester,
    ) async {
      final repository = FakeCharacterRepository(
        onFetch: (_) async => responseWith([]),
      );
      await pumpSearchPage(tester, repository);

      await tester.enterText(find.byType(TextField), 'R');
      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.searchedNames, isEmpty);
      expect(find.text('Search to find characters'), findsOneWidget);
    });

    testWidgets('shows loading while a search request is pending', (
      tester,
    ) async {
      final request = Completer<CharacterResponse>();
      final repository = FakeCharacterRepository(
        onFetch: (_) => request.future,
      );
      await pumpSearchPage(tester, repository);

      await tester.enterText(find.byType(TextField), 'Rick');
      await tester.pump(const Duration(milliseconds: 500));

      expect(repository.searchedNames, ['Rick']);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Search to find characters'), findsNothing);

      request.complete(responseWith([]));
      await tester.pump();
    });

    testWidgets('typing at least two characters displays matching results', (
      tester,
    ) async {
      await cacheCharacterImage();
      final repository = FakeCharacterRepository(
        onFetch: (_) async =>
            responseWith([character(id: 1, name: 'Rick Sanchez')]),
      );
      await pumpSearchPage(tester, repository);

      await tester.enterText(find.byType(TextField), 'Rick');
      await tester.pump(const Duration(milliseconds: 499));
      expect(repository.searchedNames, isEmpty);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(repository.searchedNames, ['Rick']);
      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Human • Alive'), findsOneWidget);
    });

    testWidgets('empty successful response displays no-results state', (
      tester,
    ) async {
      final repository = FakeCharacterRepository(
        onFetch: (_) async => responseWith([]),
      );
      await pumpSearchPage(tester, repository);

      await tester.enterText(find.byType(TextField), 'Nobody');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(repository.searchedNames, ['Nobody']);
      expect(find.text('No results found :('), findsOneWidget);
      expect(find.text('Search to find characters'), findsNothing);
    });

    testWidgets('repository failure displays the error state', (tester) async {
      final repository = FakeCharacterRepository(
        onFetch: (_) async => throw Exception('search failed'),
      );
      await pumpSearchPage(tester, repository);

      await tester.enterText(find.byType(TextField), 'Rick');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();

      expect(repository.searchedNames, ['Rick']);
      expect(find.text('Failed to search characters'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('clear icon appears when search text exists', (tester) async {
      final repository = FakeCharacterRepository(
        onFetch: (_) async => responseWith([]),
      );
      await pumpSearchPage(tester, repository);

      expect(find.byIcon(Icons.clear), findsNothing);
      await tester.enterText(find.byType(TextField), 'R');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('tapping clear empties field and restores initial state', (
      tester,
    ) async {
      final repository = FakeCharacterRepository(
        onFetch: (_) async => responseWith([]),
      );
      await pumpSearchPage(tester, repository);

      await tester.enterText(find.byType(TextField), 'Rick');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.text('No results found :('), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.byIcon(Icons.clear), findsNothing);
      expect(find.text('Search to find characters'), findsOneWidget);
      expect(repository.searchedNames, ['Rick']);
    });
  });
}
