import 'dart:convert';

import 'package:rickipedia/core/network/http_client.dart';

import '../models/character_response_model.dart';

class CharacterApiDataSource {
  final HttpClient client;

  CharacterApiDataSource({required this.client});

  Future<CharacterResponse> fetchCharacters({
    int page = 1,
    String? name,
  }) async {
    final searchName = name?.trim();

    final uri = Uri.https('rickandmortyapi.com', '/api/character/', {
      'page': page.toString(),
      if (searchName != null && searchName.isNotEmpty) 'name': searchName,
    });

    final response = await client.get(uri.toString());
    if (response.statusCode != 200) {
      throw Exception('Fail to load Characters: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    return CharacterResponse.fromJson(decoded);
  }
}
