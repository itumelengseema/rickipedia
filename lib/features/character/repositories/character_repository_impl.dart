import 'package:rickipedia/core/models/character_page.dart';
import 'package:rickipedia/features/character/data/datasources/character_remote_data_source.dart';

import 'character_repository.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final CharacterRemoteDataSource remoteDataSource;
  CharacterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<CharacterPage> getCharacters({int page = 1, String? name}) async {
    return remoteDataSource.getCharacters(page: page, name: name);
  }
}
