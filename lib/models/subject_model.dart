import 'chapter_model.dart';

class SubjectModel {
  final String id;
  final String name;
  final List<ChapterModel> chapters;
  final DateTime createdAt;

  const SubjectModel({
    required this.id,
    required this.name,
    required this.chapters,
    required this.createdAt,
  });

  SubjectModel copyWith({
    String? id,
    String? name,
    List<ChapterModel>? chapters,
    DateTime? createdAt,
  }) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      chapters: chapters ?? this.chapters,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  double get progress {
    if (chapters.isEmpty) return 0;

    double total = 0;

    for (final chapter in chapters) {
      total += chapter.progress;
    }

    return total / chapters.length;
  }

  int get completedChapterCount {
    return chapters
        .where((chapter) => chapter.isCompleted)
        .length;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'chapters':
          chapters.map((chapter) => chapter.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    final rawChapters = json['chapters'];

    final chapters = rawChapters is List
        ? rawChapters
            .whereType<Map>()
            .map(
              (item) => ChapterModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <ChapterModel>[];

    return SubjectModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      chapters: chapters,
      createdAt: DateTime.tryParse(
            json['createdAt']?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }
}
