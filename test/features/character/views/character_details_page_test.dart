import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/models/character_model.dart';
import 'package:rickipedia/features/character/models/location_model.dart';
import 'package:rickipedia/features/character/models/origin_model.dart';
import 'package:rickipedia/features/character/views/character_details_page.dart';
import 'package:rickipedia/theme/app_colours.dart';

const _imageUrl = 'https://example.test/details.png';

Character _character() => Character(
  id: 1,
  name: 'Rick Sanchez',
  status: 'Alive',
  species: 'Human',
  type: 'Scientist',
  gender: 'Male',
  origin: Origin(name: 'Earth (C-137)', url: ''),
  location: Location(name: 'Citadel of Ricks', url: ''),
  image: _imageUrl,
  episode: ['episode/1', 'episode/2'],
  url: '',
  created: '',
);

Future<void> _pumpPage(WidgetTester tester, Character character) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(Colors.transparent, BlendMode.src);
  final image = await recorder.endRecording().toImage(1, 1);
  PaintingBinding.instance.imageCache.putIfAbsent(
    const CachedNetworkImageProvider(_imageUrl),
    () => OneFrameImageStreamCompleter(Future.value(ImageInfo(image: image))),
  );
  await tester.pumpWidget(
    MaterialApp(home: CharacterDetailsPage(character: character)),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('CharacterDetailsPage', () {
    testWidgets('shows the title, character summary, and all About fields', (
      tester,
    ) async {
      await _pumpPage(tester, _character());

      expect(find.widgetWithText(AppBar, 'Character details'), findsOneWidget);
      expect(find.text('Rick Sanchez'), findsOneWidget);
      expect(find.text('Alive'), findsOneWidget);
      expect(find.text('Human'), findsNWidgets(2));
      expect(find.text('About'), findsOneWidget);
      for (final entry in {
        'Species': 'Human',
        'Gender': 'Male',
        'Origin': 'Earth (C-137)',
        'Current location': 'Citadel of Ricks',
        'Type': 'Scientist',
      }.entries) {
        final row = find.ancestor(
          of: find.text('${entry.key}:'),
          matching: find.byType(Row),
        );
        expect(
          find.descendant(of: row, matching: find.text(entry.value)),
          findsOneWidget,
        );
      }
    });

    testWidgets('shows Not specified for empty and whitespace-only fields', (
      tester,
    ) async {
      final character = _character()
        ..species = ''
        ..gender = '   '
        ..origin = Origin(name: '\t', url: '')
        ..location = Location(name: '', url: '')
        ..type = '\n ';

      await _pumpPage(tester, character);

      expect(find.text('Not specified'), findsNWidgets(5));
    });

    for (final count in [0, 1, 2]) {
      testWidgets('shows the count and correct wording for $count episodes', (
        tester,
      ) async {
        final character = _character()
          ..episode = List.generate(count, (index) => 'episode/$index');

        await _pumpPage(tester, character);
        await tester.ensureVisible(find.text('Episodes'));
        await tester.pumpAndSettle();

        expect(find.text('$count'), findsOneWidget);
        expect(
          find.text(count == 1 ? 'appearance' : 'appearances'),
          findsOneWidget,
        );
        expect(
          find.text(count == 1 ? 'appearances' : 'appearance'),
          findsNothing,
        );
      });
    }

    for (final entry in {
      'ALIVE': Colors.green,
      'dEaD': AppColors.error,
      'unknown': AppColors.textSecondary,
      'Unrecognized': AppColors.textSecondary,
    }.entries) {
      testWidgets('renders the correct status indicator for ${entry.key}', (
        tester,
      ) async {
        await _pumpPage(tester, _character()..status = entry.key);

        final indicator = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        expect((indicator.decoration as BoxDecoration).color, entry.value);
        expect(find.text(entry.key), findsOneWidget);
      });
    }

    testWidgets(
      'long details fit a narrow screen and episodes remain reachable',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(280, 400));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final longValue = List.filled(12, 'Long character detail').join(' ');
        final character = _character()
          ..name = longValue
          ..status = longValue
          ..species = longValue
          ..gender = longValue
          ..origin = Origin(name: longValue, url: '')
          ..location = Location(name: longValue, url: '')
          ..type = longValue;

        await _pumpPage(tester, character);
        expect(tester.takeException(), isNull);
        expect(find.text('appearances').hitTestable(), findsNothing);

        await tester.ensureVisible(find.text('appearances'));
        await tester.pumpAndSettle();

        expect(find.text('appearances').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        final imageSize = tester.getSize(find.byType(CachedNetworkImage));
        expect(imageSize.width, lessThanOrEqualTo(280));
        expect(imageSize.height, imageSize.width);
      },
    );

    testWidgets('limits the portrait and centers the content on wide screens', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpPage(tester, _character());

      expect(
        tester.getSize(find.byType(CachedNetworkImage)),
        const Size(330, 330),
      );
      expect(tester.getCenter(find.byType(CachedNetworkImage)).dx, 600);
      final aboutRow = find.ancestor(
        of: find.text('Species:'),
        matching: find.byType(Row),
      );
      expect(tester.getSize(aboutRow).width, lessThanOrEqualTo(600));
      expect(tester.takeException(), isNull);
    });

    testWidgets('details remain readable and scrollable with enlarged text', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 480));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpPage(tester, _character());
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: CharacterDetailsPage(character: _character()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Citadel of Ricks'));
      await tester.pumpAndSettle();
      expect(find.text('Citadel of Ricks').hitTestable(), findsOneWidget);

      await tester.ensureVisible(find.text('appearances'));
      await tester.pumpAndSettle();
      expect(find.text('appearances').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the app bar returns to the previous page', (tester) async {
      await _pumpPage(tester, _character());
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        CharacterDetailsPage(character: _character()),
                  ),
                ),
                child: const Text('Open character'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open character'));
      await tester.pumpAndSettle();

      expect(find.text('Character details'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Open character'), findsOneWidget);
      expect(find.byType(CharacterDetailsPage), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
