import 'location_model.dart';
import 'origin_model.dart';

class Character {
  final int id;
  String name;
  String status;
  String species;
  String type;
  String gender;
  Origin origin;
  Location location;
  String image;
  List<String> episode;
  String url;
  String created;

  Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.type,
    required this.gender,
    required this.origin,
    required this.location,
    required this.image,
    required this.episode,
    required this.url,
    required this.created,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'],
      name: json['name'],
      status: json['status'],
      species: json['species'],
      type: json['type'],
      gender: json['gender'],
      origin: Origin.fromJson(json['origin'] as Map<String, dynamic>),
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
      image: json['image'],
      episode: json['episode'].cast<String>(),
      url: json['url'],
      created: json['created'],
    );
  }
}
