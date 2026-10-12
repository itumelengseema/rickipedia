import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/models/character_model.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/models/location_model.dart';
import 'package:rickipedia/features/character/models/origin_model.dart';
import 'package:rickipedia/features/character/providers/character_providers.dart';
import 'package:rickipedia/features/character/providers/character_controller.dart';
import 'package:rickipedia/features/character/repositories/character_repository.dart';
import 'package:rickipedia/features/character/views/characters_page.dart';
import 'package:rickipedia/features/character/views/character_details_page.dart';

const testCharacterImageUrl = 'https://example.test/character.png';
const pageLoadingIndicatorKey = Key('characters-page-loading-indicator');
const paginationLoadingIndicatorKey = Key(
  'characters-pagination-loading-indicator',
);

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
  image: testCharacterImageUrl,
  episode: const [],
  url: '',
  created: '2017-11-04T18:48:46.250Z',
);

Future<void> cacheCharacterImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawColor(Colors.transparent, BlendMode.src);
  final image = await recorder.endRecording().toImage(1, 1);
  const provider = CachedNetworkImageProvider(testCharacterImageUrl);
  PaintingBinding.instance.imageCache.putIfAbsent(
    provider,
    () => OneFrameImageStreamCompleter(Future.value(ImageInfo(image: image))),
  );
}

Future<void> pumpPage(
  WidgetTester tester,
  CharacterRepository repository,
) async {
  await cacheCharacterImage();
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
    testWidgets('profile and menu placeholders are visibly disabled', (
      tester,
    ) async {
      final repository = FakeCharacterRepository([
        () async => responseWith([]),
      ]);
      await pumpPage(tester, repository);
      await tester.pumpAndSettle();

      for (final icon in [Icons.person, Icons.more_vert_rounded]) {
        final iconFinder = find.byIcon(icon);
        final button = tester.widget<IconButton>(
          find.ancestor(of: iconFinder, matching: find.byType(IconButton)),
        );
        expect(button.onPressed, isNull);
        expect(tester.widget<Icon>(iconFinder).color, isNull);
        expect(IconTheme.of(tester.element(iconFinder)).color!.a, lessThan(1));
      }
    });

    for (final fails in [false, true]) {
      testWidgets(
        'refresh shows loading with retained data, then ${fails ? 'shows error UI with retained controller data' : 'replaces cards on success'}',
        (tester) async {
          final initial = responseWith([
            character(id: 1, name: 'Rick Sanchez'),
          ]);
          final request = Completer<CharacterResponse>();
          final repository = FakeCharacterRepository([
            () async => initial,
            () => request.future,
          ]);
          await pumpPage(tester, repository);
          await tester.pumpAndSettle();
          final container = ProviderScope.containerOf(
            tester.element(find.byType(CharactersPage)),
          );

          final refresh = tester
              .widget<RefreshIndicator>(find.byType(RefreshIndicator))
              .onRefresh();
          await tester.pump();

          expect(container.read(characterControllerProvider).isLoading, isTrue);
          expect(
            container.read(characterControllerProvider).requireValue,
            same(initial),
          );
          expect(find.text('Rick Sanchez'), findsNothing);
          expect(find.byKey(pageLoadingIndicatorKey), findsOneWidget);

          if (fails) {
            request.completeError(Exception('refresh failed'));
          } else {
            request.complete(
              responseWith([character(id: 2, name: 'Morty Smith')]),
            );
          }
          await refresh;
          await tester.pumpAndSettle();

          expect(repository.requestedPages, [1, 1]);
          expect(find.text('Rick Sanchez'), findsNothing);
          if (fails) {
            final state = container.read(characterControllerProvider);
            expect(state.hasError, isTrue);
            expect(state.requireValue, same(initial));
            expect(find.text('Failed to load characters'), findsOneWidget);
            expect(
              find.widgetWithText(ElevatedButton, 'Retry'),
              findsOneWidget,
            );
            expect(find.byType(SnackBar), findsNothing);
          } else {
            expect(find.text('Morty Smith'), findsOneWidget);
            expect(find.text('Failed to load characters'), findsNothing);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'tapping a character opens its details and returns to the grid',
      (tester) async {
        final selected = character(id: 2, name: 'Morty Smith')
          ..origin = Origin(name: 'Earth (C-137)', url: '')
          ..type = 'Selected grid character';
        final repository = FakeCharacterRepository([
          () async =>
              responseWith([character(id: 1, name: 'Rick Sanchez'), selected]),
        ]);
        await pumpPage(tester, repository);
        await tester.pumpAndSettle();
        final originalState = tester.state(find.byType(CharactersPage));

        await tester.ensureVisible(find.text('Morty Smith'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Morty Smith'));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<CharacterDetailsPage>(find.byType(CharacterDetailsPage))
              .character,
          same(selected),
        );
        expect(find.text('Character details'), findsOneWidget);
        expect(find.text('Morty Smith'), findsOneWidget);
        expect(find.text('Rick Sanchez'), findsNothing);
        expect(find.text('Earth (C-137)'), findsOneWidget);
        expect(find.text('Selected grid character'), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(CharacterDetailsPage), findsNothing);
        expect(tester.state(find.byType(CharactersPage)), same(originalState));
        expect(find.text('Rick Sanchez').hitTestable(), findsOneWidget);
        expect(find.text('Morty Smith').hitTestable(), findsOneWidget);
        expect(repository.requestedPages, [1]);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('shows a loading indicator while characters are requested', (
      tester,
    ) async {
      final request = Completer<CharacterResponse>();
      final repository = FakeCharacterRepository([() => request.future]);

      await pumpPage(tester, repository);

      expect(find.byKey(pageLoadingIndicatorKey), findsOneWidget);
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
      expect(find.byKey(pageLoadingIndicatorKey), findsNothing);
    });

    testWidgets('pull to refresh works when content is too short to scroll', (
      tester,
    ) async {
      final repository = FakeCharacterRepository([
        () async => responseWith([]),
        () async => responseWith([character(id: 1, name: 'Rick Sanchez')]),
      ]);

      await pumpPage(tester, repository);
      await tester.pump();

      expect(find.text('No characters found'), findsOneWidget);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();

      expect(repository.requestedPages, [1, 1]);
      expect(find.text('Rick Sanchez'), findsOneWidget);
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
      expect(find.byKey(pageLoadingIndicatorKey), findsOneWidget);
      expect(find.text('Failed to load characters'), findsNothing);

      retryRequest.complete(
        responseWith([character(id: 1, name: 'Summer Smith')]),
      );
      await tester.pump();

      expect(find.text('Summer Smith'), findsOneWidget);
      expect(find.byKey(pageLoadingIndicatorKey), findsNothing);
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
      expect(find.byKey(paginationLoadingIndicatorKey), findsNothing);
    });

    testWidgets('pagination failure shows a snackbar whose Retry loads again', (
      tester,
    ) async {
      var pageTwoAttempts = 0;
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
        () async {
          pageTwoAttempts++;
          throw Exception('offline');
        },
        () async {
          pageTwoAttempts++;
          return responseWith(
            [character(id: 11, name: 'Recovered Character')],
            count: 11,
            pages: 2,
            prev: 'https://rickandmortyapi.com/api/character?page=1',
          );
        },
      ]);

      await pumpPage(tester, repository);
      await tester.pump();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't load more characters. Please try again."),
        findsOneWidget,
      );
      expect(find.widgetWithText(SnackBarAction, 'Retry'), findsOneWidget);
      expect(pageTwoAttempts, 1);

      await tester.tap(find.widgetWithText(SnackBarAction, 'Retry'));
      await tester.pumpAndSettle();

      expect(pageTwoAttempts, 2);
      await tester.scrollUntilVisible(
        find.text('Recovered Character'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Recovered Character'), findsOneWidget);
      expect(
        find.text("Couldn't load more characters. Please try again."),
        findsNothing,
      );
    });
  });
}
