import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/repositories/character_repository.dart';

import '../data/character_api_data_source.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final CharacterApiDataSource data;

  CharacterRepositoryImpl({required this.data});

  @override
  Future<CharacterResponse> fetchCharacters({int page = 1, String? name}) {
    return data.fetchCharacters(page: page, name: name);
  }
}
