import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/core/network/http_client.dart';
import 'package:rickipedia/features/character/data/character_api_data_source.dart';

class FakeHttpClient implements HttpClient {
  final HttpResponse response;
  String? lasturl;

  FakeHttpClient({required this.response});

  @override
  void close() {}

  @override
  Future<HttpResponse> get(String url) async {
    lasturl = url;
    return response;
  }
}

void main() {
  test('returns CharacterResponse when request is successful', () async {
    final json = <String, dynamic>{
      "info": {
        "count": 826,
        "pages": 42,
        "next": "https://rickandmortyapi.com/api/character/?page=3",
        "prev": "https://rickandmortyapi.com/api/character/?page=1",
      },
      "results": [
        {
          "id": 21,
          "name": "Aqua Morty",
          "status": "unknown",
          "species": "Humanoid",
          "type": "Fish-Person",
          "gender": "Male",
          "origin": {"name": "unknown", "url": ""},
          "location": {
            "name": "Citadel of Ricks",
            "url": "https://rickandmortyapi.com/api/location/3",
          },
          "image": "https://rickandmortyapi.com/api/character/avatar/21.jpeg",
          "episode": [
            "https://rickandmortyapi.com/api/episode/10",
            "https://rickandmortyapi.com/api/episode/22",
          ],
          "url": "https://rickandmortyapi.com/api/character/21",
          "created": "2017-11-04T22:39:48.055Z",
        },
      ],
    };

    final fakeClient = FakeHttpClient(
      response: HttpResponse(statusCode: 200, body: jsonEncode(json)),
    );

    final dataSource = CharacterApiDataSource(client: fakeClient);

    final result = await dataSource.fetchCharacters(page: 2);

    expect(result.count, 826);
    expect(result.pages, 42);
    expect(result.characters, hasLength(1));
    expect(result.characters.first.name, 'Aqua Morty');
    expect(fakeClient.lasturl, contains('page=2'));
  });
}
