import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/core/network/http_client.dart';
import 'package:rickipedia/features/character/data/character_api_data_source.dart';
import 'package:rickipedia/features/character/data/character_data_source.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/providers/character_providers.dart';
import 'package:rickipedia/features/character/repositories/character_repository_impl.dart';

class FakeHttpClient implements HttpClient {
  String? requestedUrl;

  @override
  void close() {}

  @override
  Future<HttpResponse> get(String url) async {
    requestedUrl = url;
    return HttpResponse(
      statusCode: 200,
      body: jsonEncode({
        'info': {'count': 0, 'pages': 0, 'next': null, 'prev': null},
        'results': <Object>[],
      }),
    );
  }
}

class FakeCharacterDataSource implements CharacterDataSource {
  FakeCharacterDataSource(this.response);

  final CharacterResponse response;
  int calls = 0;

  @override
  Future<CharacterResponse> fetchCharacters({
    int page = 1,
    String? name,
  }) async {
    calls++;
    return response;
  }
}

void main() {
  test(
    'characterDataSourceProvider builds an API data source with the client',
    () async {
      final client = FakeHttpClient();
      final container = ProviderContainer(
        overrides: [httpClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      final dataSource = container.read(characterDataSourceProvider);

      expect(dataSource, isA<CharacterApiDataSource>());
      await dataSource.fetchCharacters(page: 2);
      expect(Uri.parse(client.requestedUrl!).queryParameters['page'], '2');
    },
  );

  test(
    'characterRepositoryProvider builds a repository with the data source',
    () async {
      final expected = CharacterResponse(
        count: 4,
        pages: 1,
        next: null,
        prev: null,
        characters: [],
      );
      final dataSource = FakeCharacterDataSource(expected);
      final container = ProviderContainer(
        overrides: [characterDataSourceProvider.overrideWithValue(dataSource)],
      );
      addTearDown(container.dispose);

      final repository = container.read(characterRepositoryProvider);
      final result = await repository.fetchCharacters();

      expect(repository, isA<CharacterRepositoryImpl>());
      expect(result, same(expected));
      expect(dataSource.calls, 1);
    },
  );
}
