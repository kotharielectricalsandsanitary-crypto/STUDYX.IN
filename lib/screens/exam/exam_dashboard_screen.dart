import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'batch_progress_screen.dart';
import '../../providers/exam_provider.dart';
import 'exam_syllabus_screen.dart';

class ExamDashboardScreen
    extends StatelessWidget {
  final String examId;

  const ExamDashboardScreen({
    super.key,
    required this.examId,
  });

  @override
  Widget build(BuildContext context) {
    final exam = context
        .watch<ExamProvider>()
        .getExamById(examId);

    if (exam == null) {
      return const Scaffold(
        body: Center(
          child: Text('Exam not found'),
        ),
      );
    }

    final daysLeft =
        exam.examDate
            .difference(DateTime.now())
            .inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(exam.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '$daysLeft',
            style:
                const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Text('Days remaining'),

          const SizedBox(height: 25),

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${exam.targetPercentage.toStringAsFixed(0)}%',
                    style:
                        const TextStyle(
                      fontSize: 30,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          ListTile(
            leading:
                const Icon(Icons.menu_book),
            title:
                const Text('Exam Syllabus'),
            subtitle: const Text(
              'Select chapters and topics',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ExamSyllabusScreen(
                    examId: examId,
                  ),
                ),
              );
            },
          ),

          ListTile(
            leading:
                const Icon(Icons.check_circle),
            title:
                const Text('Batch Progress'),
            subtitle: const Text(
              'Mark topics you already completed',
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchProgressScreen(
                    examId: examId,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'Today',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Card(
            child: Padding(
              padding:
                  EdgeInsets.all(18),
              child: Text(
                'Your exam topics will appear here after you set the syllabus.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}