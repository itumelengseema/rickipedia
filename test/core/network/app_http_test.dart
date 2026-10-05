import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rickipedia/core/network/app_http.dart';

class FakeClient extends http.BaseClient {
  bool wasClosed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(const Stream.empty(), 200);
  }

  @override
  void close() {
    wasClosed = true;
    super.close();
  }
}

void main() {
  test('get sends request to correct URL and returns HttpResponse', () async {
    final mockClient = MockClient((request) async {
      expect(
        request.url.toString(),
        'https://rickandmortyapi.com/api/character',
      );

      return http.Response('{"message": "success"}', 200);
    });

    final appHttp = AppHttp(client: mockClient);

    final response = await appHttp.get(
      'https://rickandmortyapi.com/api/character',
    );

    expect(response.statusCode, 200);
    expect(response.body, '{"message": "success"}');
  });

  test('close does not close injected client', () {
    final fakeClient = FakeClient();

    final appHttp = AppHttp(client: fakeClient);

    appHttp.close();

    expect(fakeClient.wasClosed, false);
  });
}
