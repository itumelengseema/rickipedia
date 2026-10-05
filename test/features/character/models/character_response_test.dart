import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';

void main() {
  test('parses pagination metadata and empty results', () {
    // Arrange
    final json = <String, dynamic>{
      'info': {
        'count': 826,
        'pages': 42,
        'next': 'https://rickandmortyapi.com/api/character?page=2',
        'prev': null,
      },
      'results': [],
    };

    // Act
    final response = CharacterResponse.fromJson(json);

    // Assert
    expect(response.count, 826);
    expect(response.pages, 42);
    expect(response.next, 'https://rickandmortyapi.com/api/character?page=2');
    expect(response.prev, isNull);
    expect(response.characters, isEmpty);
  });

  test('parses a character with nested data', () {
    // Arrange
    final json = <String, dynamic>{
      'info': {'count': 1, 'pages': 1, 'next': null, 'prev': null},
      'results': [
        {
          'id': 1,
          'name': 'Rick Sanchez',
          'status': 'Alive',
          'species': 'Human',
          'type': '',
          'gender': 'Male',
          'origin': {
            'name': 'Earth (C-137)',
            'url': 'https://rickandmortyapi.com/api/location/1',
          },
          'location': {
            'name': 'Citadel of Ricks',
            'url': 'https://rickandmortyapi.com/api/location/3',
          },
          'image': 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
          'episode': [
            'https://rickandmortyapi.com/api/episode/1',
            'https://rickandmortyapi.com/api/episode/2',
          ],
          'url': 'https://rickandmortyapi.com/api/character/1',
          'created': '2017-11-04T18:48:46.250Z',
        },
      ],
    };

    // Act
    final response = CharacterResponse.fromJson(json);

    // Assert
    expect(response.characters, hasLength(1));

    final character = response.characters.single;

    expect(character.id, 1);
    expect(character.name, 'Rick Sanchez');
    expect(character.origin.name, 'Earth (C-137)');
    expect(character.location.name, 'Citadel of Ricks');
    expect(character.episode, [
      'https://rickandmortyapi.com/api/episode/1',
      'https://rickandmortyapi.com/api/episode/2',
    ]);
    expect(response.next, isNull);
    expect(response.prev, isNull);
  });

  test('parses all characters in results and preserves their order', () {
    // Arrange
    final json = <String, dynamic>{
      'info': {'count': 2, 'pages': 1, 'next': null, 'prev': null},
      'results': [
        {
          'id': 1,
          'name': 'Rick Sanchez',
          'status': 'Alive',
          'species': 'Human',
          'type': '',
          'gender': 'Male',
          'origin': {
            'name': 'Earth (C-137)',
            'url': 'https://rickandmortyapi.com/api/location/1',
          },
          'location': {
            'name': 'Citadel of Ricks',
            'url': 'https://rickandmortyapi.com/api/location/3',
          },
          'image': 'https://rickandmortyapi.com/api/character/avatar/1.jpeg',
          'episode': [
            'https://rickandmortyapi.com/api/episode/1',
            'https://rickandmortyapi.com/api/episode/2',
          ],
          'url': 'https://rickandmortyapi.com/api/character/1',
          'created': '2017-11-04T18:48:46.250Z',
        },
        {
          'id': 2,
          'name': 'Morty Smith',
          'status': 'Alive',
          'species': 'Human',
          'type': '',
          'gender': 'Male',
          'origin': {'name': 'unknown', 'url': ''},
          'location': {
            'name': 'Citadel of Ricks',
            'url': 'https://rickandmortyapi.com/api/location/3',
          },
          'image': 'https://rickandmortyapi.com/api/character/avatar/2.jpeg',
          'episode': [
            'https://rickandmortyapi.com/api/episode/1',
            'https://rickandmortyapi.com/api/episode/2',
          ],
          'url': 'https://rickandmortyapi.com/api/character/2',
          'created': '2017-11-04T18:50:21.651Z',
        },
      ],
    };

    // Act
    final response = CharacterResponse.fromJson(json);

    // Assert
    expect(response.characters, hasLength(2));

    final first = response.characters[0];
    final second = response.characters[1];

    expect(first.id, 1);
    expect(first.name, 'Rick Sanchez');

    expect(second.id, 2);
    expect(second.name, 'Morty Smith');
    expect(second.origin.name, 'unknown');
  });
}
