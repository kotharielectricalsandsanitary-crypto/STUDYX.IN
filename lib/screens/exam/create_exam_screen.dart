import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/exam_provider.dart';

class CreateExamScreen extends StatefulWidget {
  const CreateExamScreen({super.key});

  @override
  State<CreateExamScreen> createState() =>
      _CreateExamScreenState();
}

class _CreateExamScreenState
    extends State<CreateExamScreen> {
  final nameController = TextEditingController();

  DateTime? examDate;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(
        now.year,
        now.month,
        now.day,
      ),
      lastDate: now.add(
        const Duration(days: 1000),
      ),
      initialDate: now,
    );

    if (picked == null) return;

    setState(() {
      examDate = picked;
    });
  }

  Future<void> createExam() async {
    final name = nameController.text.trim();

    if (name.isEmpty || examDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter exam name and select exam date.',
          ),
        ),
      );
      return;
    }

    await context.read<ExamProvider>().createExam(
          name: name,
          examDate: examDate!,
        );

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Exam'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Create your exam',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Set the exam first. You can select its syllabus next.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 28),

          TextField(
            controller: nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Exam name',
              hintText: 'School Exam - Physics',
              prefixIcon: const Icon(
                Icons.assignment_rounded,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          InkWell(
            onTap: pickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white24,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Exam date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          examDate == null
                              ? 'Select exam date'
                              : '${examDate!.day}/'
                                  '${examDate!.month}/'
                                  '${examDate!.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: createExam,
              icon: const Icon(
                Icons.add_task_rounded,
              ),
              label: const Text(
                'Create Exam',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}