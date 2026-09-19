import 'package:rickipedia/core/models/character_page.dart';
import 'package:rickipedia/features/character/models/character_model.dart';

class CharacterPageModel extends CharacterPage {
  const CharacterPageModel({
    required super.characters,
    required super.count,
    required super.totalPages,
    required super.nextPageUrl,
    required super.previousPageUrl,
  });

  factory CharacterPageModel.fromJson(Map<String, dynamic> json) {
    final infoData = json['info'] as Map<String, dynamic>;
    final characterData = json['results'] as List<dynamic>;

    final characters = characterData.map((characterJson) {
      return CharacterModel.fromJson(characterJson as Map<String, dynamic>);
    }).toList();

    return CharacterPageModel(
      characters: characters,
      count: infoData['count'] as int,
      totalPages: infoData['pages'] as int,
      nextPageUrl: infoData['next'] as String?,
      previousPageUrl: infoData['prev'] as String,
    );
  }
}
