import 'character.dart';

class Episode {
  final int id;
  final String name;
  final String airDate;
  final Character characters;
  final String episodeUrl;

  const Episode({
    required this.id,
    required this.name,
    required this.airDate,
    required this.characters,
    required this.episodeUrl,
  });
}
