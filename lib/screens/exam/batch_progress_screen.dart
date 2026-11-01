import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/exam_model.dart';
import '../../providers/exam_provider.dart';

class BatchProgressScreen extends StatelessWidget {
  final String examId;

  const BatchProgressScreen({
    super.key,
    required this.examId,
  });

  @override
  Widget build(BuildContext context) {
    final examProvider = context.watch<ExamProvider>();

    final exam = examProvider.getExamById(examId);

    if (exam == null) {
      return const Scaffold(
        body: Center(
          child: Text('Exam not found'),
        ),
      );
    }

    final chapters = examProvider.getExamChapters(exam);
    final progress = examProvider.getExamProgress(exam);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Progress'),
      ),
      body: chapters.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No chapters selected for this exam.\n\n'
                  'First select chapters from Exam Syllabus.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // =====================================================
                // PROGRESS CARD
                // =====================================================

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Progress',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 16),

                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                        ),

                        const SizedBox(height: 10),

                        Text(
                          '${(progress * 100).round()}% completed',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Selected Chapters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // =====================================================
                // CHAPTERS
                // =====================================================

                ...chapters.map(
                  (chapter) {
                    final steps = chapter.steps
                        .where(
                          (step) => !step.title
                              .toLowerCase()
                              .contains('revision'),
                        )
                        .toList();

                    final completed = steps
                        .where(
                          (step) => step.completed,
                        )
                        .length;

                    final chapterProgress =
                        steps.isEmpty
                            ? 0.0
                            : completed / steps.length;

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          child: Text(
                            '${(chapterProgress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        title: Text(
                          chapter.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        subtitle: Text(
                          '$completed / ${steps.length} completed',
                        ),

                        children: [
                          if (steps.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No study steps available.',
                              ),
                            ),

                          ...steps.map(
                            (step) {
                              return ListTile(
                                leading: Icon(
                                  step.completed
                                      ? Icons.check_circle
                                      : Icons
                                          .radio_button_unchecked,
                                  color: step.completed
                                      ? Colors.green
                                      : Colors.grey,
                                ),

                                title: Text(
                                  step.title,
                                ),

                                trailing:
                                    Checkbox(
                                  value:
                                      step.completed,
                                  onChanged: (_) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Use the main Syllabus screen to update chapter progress.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}