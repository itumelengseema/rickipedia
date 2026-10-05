import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/app_http.dart';
import '../../../core/network/http_client.dart' as network;
import '../data/character_api_data_source.dart';
import '../data/character_data_source.dart';
import '../repositories/character_repository.dart';
import '../repositories/character_repository_impl.dart';

final httpClientProvider = Provider<network.HttpClient>((ref) {
  final client = AppHttp();

  ref.onDispose(client.close);

  return client;
});

final characterDataSourceProvider = Provider<CharacterDataSource>((ref) {
  final client = ref.watch(httpClientProvider);

  return CharacterApiDataSource(client: client);
});

final characterRepositoryProvider = Provider<CharacterRepository>((ref) {
  final dataSource = ref.watch(characterDataSourceProvider);

  return CharacterRepositoryImpl(data: dataSource);
});
