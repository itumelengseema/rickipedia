import 'dart:convert';
import 'dart:io';

import 'package:rickipedia/features/character/models/character_model.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/models/location_model.dart';
import 'package:rickipedia/features/character/models/origin_model.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

CharacterResponse responseFixture(String name) => CharacterResponse.fromJson(
  jsonDecode(fixture(name)) as Map<String, dynamic>,
);

Character characterFixture({required int id, required String name}) =>
    Character(
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

CharacterResponse characterResponse({
  List<Character> characters = const [],
  int? count,
  int pages = 1,
  String? next,
  String? prev,
}) => CharacterResponse(
  count: count ?? characters.length,
  pages: pages,
  next: next,
  prev: prev,
  characters: characters,
);
