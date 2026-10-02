import 'character_model.dart';

class CharacterResponse {
  final int count;
  final int pages;
  final String? next;
  final String? prev;
  final List<Character> character;

  CharacterResponse({
    required this.count,
    required this.pages,
    required this.next,
    required this.prev,
    required this.character,
  });

  factory CharacterResponse.fromJson(Map<String, dynamic> json) {
    final info = json['info'] as Map<String, dynamic>;
    final result = json['results'] as List<dynamic>;
    return CharacterResponse(
      count: info['count'] as int,
      pages: info['pages'] as int,
      next: info['next'] as String?,
      prev: info['prev'] as String?,
      character: result.map((item) {
        return Character.fromJson(item as Map<String, dynamic>);
      }).toList(),
    );
  }
}
