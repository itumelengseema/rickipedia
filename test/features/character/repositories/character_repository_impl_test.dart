import 'package:flutter_test/flutter_test.dart';
import 'package:rickipedia/features/character/data/character_data_source.dart';
import 'package:rickipedia/features/character/models/character_response_model.dart';
import 'package:rickipedia/features/character/repositories/character_repository_impl.dart';

class FakeCharacterDataSource implements CharacterDataSource {
  final CharacterResponse response;

  int? receivedPage;
  String? receivedName;

  FakeCharacterDataSource({required this.response});

  @override
  Future<CharacterResponse> fetchCharacters({
    int page = 1,
    String? name,
  }) async {
    receivedPage = page;
    receivedName = name;

    return response;
  }
}

void main() {
  test('forwards page and name to data source and returns response', () async {
    final expectedResponse = CharacterResponse(
      count: 0,
      pages: 0,
      next: null,
      prev: null,
      characters: [],
    );

    final fakeDataSource = FakeCharacterDataSource(response: expectedResponse);

    final repository = CharacterRepositoryImpl(data: fakeDataSource);

    final result = await repository.fetchCharacters(page: 2, name: 'Rick');

    expect(fakeDataSource.receivedPage, 2);
    expect(fakeDataSource.receivedName, 'Rick');
    expect(result, same(expectedResponse));
  });
}
