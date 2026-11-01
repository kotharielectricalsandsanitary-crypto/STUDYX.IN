import 'package:flutter/material.dart';

class ExamSetupScreen extends StatefulWidget {
  const ExamSetupScreen({super.key});

  @override
  State<ExamSetupScreen> createState() => _ExamSetupScreenState();
}

class _ExamSetupScreenState extends State<ExamSetupScreen> {
  int step = 0;

  final TextEditingController examNameController =
      TextEditingController();

  DateTime? examDate;

  String examType = 'School Exam';

  final Map<String, bool> subjects = {
    'Physics': false,
    'Chemistry': false,
    'Biology': false,
    'English': false,
    'Hindi': false,
  };

  final Map<String, bool> completedWork = {
    'Batch lectures': false,
    'Notes': false,
    'Questions': false,
    'Revision': false,
  };

  @override
  void dispose() {
    examNameController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (step < 3) {
      setState(() {
        step++;
      });
    }
  }

  void previousStep() {
    if (step > 0) {
      setState(() {
        step--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08090D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Create Exam',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildProgress(),

          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentStep(),
            ),
          ),

          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Row(
        children: List.generate(
          4,
          (index) {
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                height: 4,
                decoration: BoxDecoration(
                  color: index <= step
                      ? const Color(0xFF7C5CFF)
                      : const Color(0xFF252630),
                  borderRadius:
                      BorderRadius.circular(20),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (step) {
      case 0:
        return _buildExamDetails();

      case 1:
        return _buildSyllabusSelection();

      case 2:
        return _buildCompletedWork();

      case 3:
        return _buildExamTopics();

      default:
        return const SizedBox();
    }
  }

  Widget _buildExamDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          const Text(
            'Set up your exam',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tell StudyX what you are preparing for.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 30),

          _label('Exam name'),

          _textField(
            controller: examNameController,
            hint: 'Physics Unit Test',
          ),

          const SizedBox(height: 22),

          _label('Exam type'),

          _dropdown(),

          const SizedBox(height: 22),

          _label('Exam date'),

          GestureDetector(
            onTap: _selectDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: _boxDecoration(),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF8B70FF),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    examDate == null
                        ? 'Select exam date'
                        : '${examDate!.day}/${examDate!.month}/${examDate!.year}',
                    style: TextStyle(
                      color: examDate == null
                          ? Colors.grey.shade600
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllabusSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          const Text(
            'Select syllabus',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Choose the subjects included in this exam.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 25),

          ...subjects.keys.map(
            (subject) {
              return _subjectTile(subject);
            },
          ),
        ],
      ),
    );
  }

  Widget _subjectTile(String subject) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _boxDecoration(),
      child: CheckboxListTile(
        value: subjects[subject],
        onChanged: (value) {
          setState(() {
            subjects[subject] = value ?? false;
          });
        },
        title: Text(
          subject,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        activeColor: const Color(0xFF7C5CFF),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget _buildCompletedWork() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          const Text(
            'What have you completed?',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tell us what you have already finished.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 25),

          ...completedWork.keys.map(
            (item) {
              return Container(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),
                decoration: _boxDecoration(),
                child: CheckboxListTile(
                  value: completedWork[item],
                  onChanged: (value) {
                    setState(() {
                      completedWork[item] =
                          value ?? false;
                    });
                  },
                  title: Text(item),
                  activeColor:
                      const Color(0xFF7C5CFF),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExamTopics() {
    final selectedSubjects = subjects.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          const Text(
            'Exam topics',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'StudyX has divided your syllabus into exam-focused topics.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),

          const SizedBox(height: 25),

          if (selectedSubjects.isEmpty)
            _emptySubjects()
          else
            ...selectedSubjects.map(
              (subject) => _topicCard(subject),
            ),
        ],
      ),
    );
  }

  Widget _topicCard(String subject) {
    final topics = examType == 'School Exam'
        ? [
            'Concepts',
            'Definitions',
            'Formulas',
            'Derivations',
            'Numericals',
            'Diagrams',
            'NCERT Questions',
            'Important Questions',
          ]
        : [
            'NCERT Facts',
            'Concepts',
            'MCQs',
            'Previous Year Questions',
            'Weak Topics',
            'Revision',
          ];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            subject,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          ...topics.map(
            (topic) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF7C5CFF,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(topic),
                    ),
                    Text(
                      '0%',
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
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

  Widget _emptySubjects() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: _boxDecoration(),
      child: const Center(
        child: Text(
          'No subjects selected.',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        25,
      ),
      child: Row(
        children: [
          if (step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: previousStep,
                child: const Text('Back'),
              ),
            ),

          if (step > 0)
            const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF7C5CFF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
              child: Text(
                step == 3
                    ? 'Create Exam'
                    : 'Continue →',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade700,
        ),
        filled: true,
        fillColor: const Color(0xFF12141B),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 15),
      decoration: _boxDecoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: examType,
          isExpanded: true,
          dropdownColor:
              const Color(0xFF151720),
          items: const [
            DropdownMenuItem(
              value: 'School Exam',
              child: Text('School Exam'),
            ),
            DropdownMenuItem(
              value: 'NEET',
              child: Text('NEET'),
            ),
            DropdownMenuItem(
              value: 'Other',
              child: Text('Other'),
            ),
          ],
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              examType = value;
            });
          },
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: const Color(0xFF12141B),
      borderRadius: BorderRadius.circular(15),
      border: Border.all(
        color: const Color(0xFF222530),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().add(
        const Duration(days: 7),
      ),
      firstDate: DateTime.now(),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF7C5CFF),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        examDate = date;
      });
    }
  }
}