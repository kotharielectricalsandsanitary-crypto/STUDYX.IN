class SyllabusChapter {
  final String id;
  final String subjectId;
  final String name;

  bool watchLectures;
  bool makeNotes;
  bool understandNotes;
  bool solveDpps;
  bool revision;

  SyllabusChapter({
    required this.id,
    required this.subjectId,
    required this.name,
    this.watchLectures = false,
    this.makeNotes = false,
    this.understandNotes = false,
    this.solveDpps = false,
    this.revision = false,
  });

  double get progress {
    int completed = 0;

    if (watchLectures) completed++;
    if (makeNotes) completed++;
    if (understandNotes) completed++;
    if (solveDpps) completed++;
    if (revision) completed++;

    return completed / 5;
  }

  int get completedSteps {
    int completed = 0;

    if (watchLectures) completed++;
    if (makeNotes) completed++;
    if (understandNotes) completed++;
    if (solveDpps) completed++;
    if (revision) completed++;

    return completed;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'name': name,
      'watchLectures': watchLectures,
      'makeNotes': makeNotes,
      'understandNotes': understandNotes,
      'solveDpps': solveDpps,
      'revision': revision,
    };
  }

  factory SyllabusChapter.fromJson(Map<String, dynamic> json) {
    return SyllabusChapter(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      name: json['name'] as String,
      watchLectures: json['watchLectures'] ?? false,
      makeNotes: json['makeNotes'] ?? false,
      understandNotes: json['understandNotes'] ?? false,
      solveDpps: json['solveDpps'] ?? false,
      revision: json['revision'] ?? false,
    );
  }
}