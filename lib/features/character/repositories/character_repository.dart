import 'package:rickipedia/features/character/models/character_response_model.dart';

abstract class CharacterRepository {
  Future<CharacterResponse> fetchCharacters({int page = 1, String? name});
}
