import 'package:rickipedia/core/network/http_client.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/repositories/character_repository.dart';

class FakeHttpClient implements HttpClient {
  FakeHttpClient(this.onGet);

  final Future<HttpResponse> Function(String url) onGet;
  final List<String> requestedUrls = [];

  @override
  Future<HttpResponse> get(String url) {
    requestedUrls.add(url);
    return onGet(url);
  }

  @override
  void close() {}
}

class FakeCharacterRepository implements CharacterRepository {
  FakeCharacterRepository(this.onFetch);

  final Future<CharacterResponse> Function(int page, String? name) onFetch;
  final List<({int page, String? name})> requests = [];

  @override
  Future<CharacterResponse> fetchCharacters({int page = 1, String? name}) {
    requests.add((page: page, name: name));
    return onFetch(page, name);
  }
}
