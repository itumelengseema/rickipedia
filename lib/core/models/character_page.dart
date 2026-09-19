import 'package:rickipedia/core/models/character.dart';

class CharacterPage {
  final List<Character> characters;
  final int count;
  final int totalPages;
  final String? nextPageUrl;
  final String? previousPageUrl;

  const CharacterPage({
    required this.characters,
    required this.count,
    required this.totalPages,
    required this.nextPageUrl,
    required this.previousPageUrl,
  });
}
