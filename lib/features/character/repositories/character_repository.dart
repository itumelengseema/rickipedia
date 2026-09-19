import 'package:rickipedia/core/models/character_page.dart';

abstract interface class CharacterRepository {
  Future<CharacterPage> getCharacters({int page = 1, String? name});
}
