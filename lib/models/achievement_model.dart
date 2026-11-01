import 'dart:convert';

class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredValue;
  final int currentValue;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  /// Progress from 0.0 to 1.0.
  double get progress {
    if (requiredValue <= 0) {
      return isUnlocked ? 1.0 : 0.0;
    }

    final value =
        currentValue / requiredValue;

    return value.clamp(0.0, 1.0);
  }

  /// Progress percentage.
  int get percentage =>
      (progress * 100).round();

  /// Whether the achievement is ready to unlock.
  bool get canUnlock =>
      !isUnlocked &&
      currentValue >= requiredValue;

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? requiredValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description:
          description ?? this.description,
      icon: icon ?? this.icon,
      requiredValue:
          requiredValue ?? this.requiredValue,
      currentValue:
          currentValue ?? this.currentValue,
      isUnlocked:
          isUnlocked ?? this.isUnlocked,
      unlockedAt:
          unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'requiredValue': requiredValue,
      'currentValue': currentValue,
      'isUnlocked': isUnlocked,
      'unlockedAt':
          unlockedAt?.toIso8601String(),
    };
  }

  factory AchievementModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return AchievementModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description:
          map['description']?.toString() ?? '',
      icon: map['icon']?.toString() ?? '🏆',
      requiredValue:
          _parseInt(map['requiredValue']),
      currentValue:
          _parseInt(map['currentValue']),
      isUnlocked:
          map['isUnlocked'] == true,
      unlockedAt:
          map['unlockedAt'] != null &&
                  map['unlockedAt']
                      .toString()
                      .isNotEmpty
              ? DateTime.tryParse(
                  map['unlockedAt']
                      .toString(),
                )
              : null,
    );
  }

  String toJson() {
    return jsonEncode(toMap());
  }

  factory AchievementModel.fromJson(
    String source,
  ) {
    final decoded = jsonDecode(source);

    return AchievementModel.fromMap(
      Map<String, dynamic>.from(
        decoded as Map,
      ),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}