import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/core/network/http_client.dart';
import 'package:rickipedia/features/character/data/character_remote_data_source.dart';

import '../../../support/character_fixtures.dart';

class FakeHttpClient implements HttpClient {
  final HttpResponse response;
  String? lastUrl;

  FakeHttpClient({required this.response});

  @override
  void close() {}

  @override
  Future<HttpResponse> get(String url) async {
    lastUrl = url;
    return response;
  }
}

class FailingHttpClient implements HttpClient {
  FailingHttpClient(this.error);

  final Object error;

  @override
  void close() {}

  @override
  Future<HttpResponse> get(String url) => Future.error(error);
}

void main() {
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

  test('returns CharacterResponse when request is successful', () async {
    final fakeClient = FakeHttpClient(
      response: HttpResponse(statusCode: 200, body: jsonEncode(json)),
    );

    final dataSource = CharacterRemoteDataSource(client: fakeClient);

    final result = await dataSource.fetchCharacters(page: 2);

    expect(result.count, 826);
    expect(result.pages, 42);
    expect(result.characters, hasLength(1));
    expect(result.characters.first.name, 'Aqua Morty');

    final uri = Uri.parse(fakeClient.lastUrl!);

    expect(uri.queryParameters['page'], '2');
  });

  test('adds the character name to the request URL', () async {
    final fakeClient = FakeHttpClient(
      response: HttpResponse(statusCode: 200, body: jsonEncode(json)),
    );

    final dataSource = CharacterRemoteDataSource(client: fakeClient);

    await dataSource.fetchCharacters(name: 'Rick');

    final uri = Uri.parse(fakeClient.lastUrl!);

    expect(uri.queryParameters['page'], '1');
    expect(uri.queryParameters['name'], 'Rick');
  });

  test('trims the character name before adding it to the URL', () async {
    final fakeClient = FakeHttpClient(
      response: HttpResponse(statusCode: 200, body: jsonEncode(json)),
    );

    final dataSource = CharacterRemoteDataSource(client: fakeClient);

    await dataSource.fetchCharacters(name: '  Rick  ');

    final uri = Uri.parse(fakeClient.lastUrl!);

    expect(uri.queryParameters['name'], 'Rick');
  });

  test('does not add name parameter when name is blank', () async {
    final fakeClient = FakeHttpClient(
      response: HttpResponse(statusCode: 200, body: jsonEncode(json)),
    );

    final dataSource = CharacterRemoteDataSource(client: fakeClient);

    await dataSource.fetchCharacters(name: '   ');

    final uri = Uri.parse(fakeClient.lastUrl!);

    expect(uri.queryParameters['page'], '1');
    expect(uri.queryParameters.containsKey('name'), false);
  });

  test('returns empty response when no characters match the name', () async {
    final fakeClient = FakeHttpClient(
      response: HttpResponse(statusCode: 404, body: fixture('no_matches.json')),
    );

    final dataSource = CharacterRemoteDataSource(client: fakeClient);

    final result = await dataSource.fetchCharacters(
      name: 'DefinitelyNotACharacter',
    );

    expect(result.count, 0);
    expect(result.pages, 0);
    expect(result.characters, isEmpty);
    expect(result.next, isNull);
    expect(result.prev, isNull);
  });

  test('throws exception when response status is not 200', () async {
    final fakeClient = FakeHttpClient(
      response: HttpResponse(
        statusCode: 500,
        body: jsonEncode({"error": "Server error"}),
      ),
    );

    final dataSource = CharacterRemoteDataSource(client: fakeClient);

    expect(() => dataSource.fetchCharacters(), throwsA(isA<Exception>()));
  });

  test('reports malformed successful JSON as a format failure', () async {
    final dataSource = CharacterRemoteDataSource(
      client: FakeHttpClient(
        response: HttpResponse(
          statusCode: 200,
          body: fixture('malformed.json'),
        ),
      ),
    );

    await expectLater(dataSource.fetchCharacters(), throwsFormatException);
  });

  test('propagates timeout failures', () async {
    final timeout = TimeoutException('request timed out');
    final dataSource = CharacterRemoteDataSource(
      client: FailingHttpClient(timeout),
    );

    await expectLater(dataSource.fetchCharacters(), throwsA(same(timeout)));
  });

  test('propagates network failures', () async {
    final failure = const SocketException('offline');
    final dataSource = CharacterRemoteDataSource(
      client: FailingHttpClient(failure),
    );

    await expectLater(dataSource.fetchCharacters(), throwsA(same(failure)));
  });

  test(
    'returns empty response when search has no results on later page',
    () async {
      final fakeClient = FakeHttpClient(
        response: HttpResponse(
          statusCode: 404,
          body: fixture('no_matches.json'),
        ),
      );

      final dataSource = CharacterRemoteDataSource(client: fakeClient);

      final result = await dataSource.fetchCharacters(page: 2, name: 'Rick');

      expect(result.characters, isEmpty);
      expect(result.count, 0);
    },
  );
}
