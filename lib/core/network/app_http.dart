import 'package:http/http.dart' as http;

import 'http_client.dart';

class AppHttp implements HttpClient {
  final http.Client client;

  AppHttp({http.Client? client}) : client = client ?? http.Client();

  @override
  Future<HttpResponse> get(String url) async {
    final response = await client
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));

    return HttpResponse(statusCode: response.statusCode, body: response.body);
  }
}
