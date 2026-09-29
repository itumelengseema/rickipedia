class Origin {
  String name;
  String url;

  Origin({required this.name, required this.url});

  factory Origin.fromJson(Map<String, dynamic> json) {
    return Origin(name: json['name'], url: json['url']);
  }
}
