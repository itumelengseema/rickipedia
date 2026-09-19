import 'package:rickipedia/core/models/character.dart';

class CharacterModel extends Character {
  const CharacterModel({
    required super.id,
    required super.name,
    required super.status,
    required super.gender,
    required super.origin,
    required super.episodesAppearedOn,
    required super.imageUrl,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    final originData = json['origin'] as Map<String, dynamic>;
    final episodeData = json['episode'] as List<dynamic>;
    return CharacterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      status: json['status'] as String,
      gender: json['gender'] as String,
      origin: originData['name'] as String,
      episodesAppearedOn: episodeData.length,
      imageUrl: json['image'] as String,
    );
  }
}
