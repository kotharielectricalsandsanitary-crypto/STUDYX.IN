import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/exam_provider.dart';
import '../../providers/syllabus_provider.dart';

class ExamSyllabusScreen extends StatelessWidget {
  final String examId;

  const ExamSyllabusScreen({
    super.key,
    required this.examId,
  });

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();
    final syllabusProvider = context.watch<SyllabusProvider>();

    final exam = examProvider.getExamById(examId);

    if (exam == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Exam Syllabus'),
        ),
        body: const Center(
          child: Text('Exam not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Select chapters for this exam',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Choose the chapters included in your exam.',
            style: TextStyle(
              color: Colors.white60,
            ),
          ),

          const SizedBox(height: 20),

          ...syllabusProvider.subjects.map(
            (subject) {
              if (subject.chapters.isEmpty) {
                return const SizedBox.shrink();
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ExpansionTile(
                  title: Text(
                    subject.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: subject.chapters.map(
                    (chapter) {
                      final selected =
                          exam.chapterIds.contains(chapter.id);

                      return CheckboxListTile(
                        value: selected,
                        title: Text(chapter.name),
                        subtitle: Text(
                          '${chapter.steps.length} study steps',
                        ),
                        onChanged: (_) async {
                          await context
                              .read<ExamProvider>()
                              .toggleChapter(
                                examId: exam.id,
                                chapterId: chapter.id,
                              );
                        },
                      );
                    },
                  ).toList(),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          if (exam.chapterIds.isEmpty)
            const Center(
              child: Text(
                'No chapters selected yet.',
                style: TextStyle(
                  color: Colors.white54,
                ),
              ),
            )
          else
            Text(
              '${exam.chapterIds.length} chapters selected',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}