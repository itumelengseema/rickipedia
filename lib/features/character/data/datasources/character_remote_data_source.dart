import 'package:rickipedia/features/character/models/character_page_model.dart';

abstract interface class CharacterRemoteDataSource {
  Future<CharacterPageModel> getCharacters({int page = 1, String? name});
}
