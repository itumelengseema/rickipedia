import 'dart:convert';

import 'package:rickipedia/core/network/http_client.dart';
import 'package:rickipedia/features/character/models/character_page_model.dart';

import 'character_remote_data_source.dart';

class CharacterRemoteDataSourceImpl implements CharacterRemoteDataSource {
  final HttpClient httpClient;

  CharacterRemoteDataSourceImpl({required this.httpClient});

  @override
  Future<CharacterPageModel> getCharacters({int page = 1, String? name}) async {
    final quaryParemeters = <String, String>{'page': page.toString()};
    final trimmendName = name?.trim();

    if (trimmendName != null && trimmendName.isNotEmpty) {
      quaryParemeters['name'] = trimmendName;
    }

    final uri = Uri.https(
      'rickandmortyapi.com',
      'api/character',
      quaryParemeters,
    );

    final response = await httpClient.get(uri.toString());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to get characters. Status code: ${response.statusCode}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return CharacterPageModel.fromJson(json);
  }
}
