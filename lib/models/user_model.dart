class UserModel {
  String name;
  String goal;
  int dailyHours;

  UserModel({
    required this.name,
    required this.goal,
    required this.dailyHours,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'goal': goal,
      'dailyHours': dailyHours,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      goal: map['goal'] ?? '',
      dailyHours: map['dailyHours'] ?? 0,
    );
  }
}