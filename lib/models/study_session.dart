import 'dart:convert';

class StudySession {
  final String id;
  final DateTime date;
  final double studyHours;
  final int studyMinutes;
  final String subject;
  final String chapter;
  final bool completed;

  const StudySession({
    required this.id,
    required this.date,
    required this.studyHours,
    required this.studyMinutes,
    required this.subject,
    required this.chapter,
    required this.completed,
  });

  factory StudySession.create({
    required double studyHours,
    required int studyMinutes,
    String subject = 'General',
    String chapter = '',
  }) {
    final now = DateTime.now();

    return StudySession(
      id: now.microsecondsSinceEpoch.toString(),
      date: now,
      studyHours: studyHours,
      studyMinutes: studyMinutes,
      subject: subject,
      chapter: chapter,
      completed: true,
    );
  }

  StudySession copyWith({
    String? id,
    DateTime? date,
    double? studyHours,
    int? studyMinutes,
    String? subject,
    String? chapter,
    bool? completed,
  }) {
    return StudySession(
      id: id ?? this.id,
      date: date ?? this.date,
      studyHours: studyHours ?? this.studyHours,
      studyMinutes: studyMinutes ?? this.studyMinutes,
      subject: subject ?? this.subject,
      chapter: chapter ?? this.chapter,
      completed: completed ?? this.completed,
    );
  }

  int get durationInSeconds {
    return (studyHours * 3600).round() + (studyMinutes * 60);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'studyHours': studyHours,
      'studyMinutes': studyMinutes,
      'subject': subject,
      'chapter': chapter,
      'completed': completed,
    };
  }

  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id']?.toString() ?? '',
      date: DateTime.parse(map['date'].toString()),
      studyHours: (map['studyHours'] as num?)?.toDouble() ?? 0.0,
      studyMinutes: (map['studyMinutes'] as num?)?.toInt() ?? 0,
      subject: map['subject']?.toString() ?? 'General',
      chapter: map['chapter']?.toString() ?? '',
      completed: map['completed'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory StudySession.fromJson(String source) {
    return StudySession.fromMap(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  @override
  String toString() {
    return 'StudySession(id: $id, date: $date, hours: $studyHours)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is StudySession && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}