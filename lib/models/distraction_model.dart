
class DistractionApp {
  final String id;
  final String name;
  final String emoji;
  final int minutesUsed;
  final bool enabled;

  const DistractionApp({
    required this.id,
    required this.name,
    required this.emoji,
    this.minutesUsed = 0,
    this.enabled = true,
  });

  DistractionApp copyWith({
    String? id,
    String? name,
    String? emoji,
    int? minutesUsed,
    bool? enabled,
  }) {
    return DistractionApp(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      minutesUsed: minutesUsed ?? this.minutesUsed,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'minutesUsed': minutesUsed,
      'enabled': enabled,
    };
  }

  factory DistractionApp.fromJson(Map<String, dynamic> json) {
    return DistractionApp(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      emoji: json['emoji'] ?? '📱',
      minutesUsed: json['minutesUsed'] ?? 0,
      enabled: json['enabled'] ?? true,
    );
  }
}
