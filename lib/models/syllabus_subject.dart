class SyllabusSubject {
  final String id;
  final String name;

  SyllabusSubject({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory SyllabusSubject.fromJson(Map<String, dynamic> json) {
    return SyllabusSubject(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}