import 'dart:convert';

import 'package:rickipedia/core/network/http_client.dart';

import '../models/character_response_model.dart';
import 'character_data_source.dart';

class CharacterApiDataSource implements CharacterDataSource {
  final HttpClient client;

  CharacterApiDataSource({required this.client});

  @override
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

    if (response.statusCode == 404 &&
        page == 1 &&
        searchName != null &&
        searchName.isNotEmpty) {
      final errorBody = jsonDecode(response.body);

      if (errorBody is Map<String, dynamic> &&
          errorBody['error'] == "There is nothing here") {
        return CharacterResponse(
          count: 0,
          pages: 0,
          next: null,
          prev: null,
          characters: [],
        );
      }
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load characters: HTTP ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    return CharacterResponse.fromJson(decoded);
  }
}
