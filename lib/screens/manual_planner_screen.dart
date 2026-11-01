
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/planner_session_model.dart';
import '../providers/planner_provider.dart';

class ManualPlannerScreen extends StatefulWidget {
  const ManualPlannerScreen({super.key});

  @override
  State<ManualPlannerScreen> createState() =>
      _ManualPlannerScreenState();
}

class _ManualPlannerScreenState extends State<ManualPlannerScreen> {
  DateTime _selectedDate = _dateOnly(DateTime.now());

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _changeDay(int difference) {
    setState(() {
      _selectedDate = _selectedDate.add(
        Duration(days: difference),
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF818CF8),
            surface: Color(0xFF171717),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = _dateOnly(picked));
    }
  }

  String _formatTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final suffix = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;

    return '$displayHour:${minute.toString().padLeft(2, '0')} $suffix';
  }

  Future<void> _addSession() async {
    final titleController = TextEditingController();
    final subjectController = TextEditingController();
    final chapterController = TextEditingController();
    final topicController = TextEditingController();
    final durationController = TextEditingController(text: '60');
    final notesController = TextEditingController();

    DateTime plannedDate = _selectedDate;
    TimeOfDay startTime = TimeOfDay.now();

    try {
      final session = await showDialog<PlannerSessionModel>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF171717),
                title: const Text('Plan a study session'),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _field(
                          titleController,
                          'Session title (optional)',
                          Icons.edit_note_rounded,
                          required: false,
                        ),
                        _field(
                          subjectController,
                          'Subject',
                          Icons.menu_book_rounded,
                        ),
                        _field(
                          chapterController,
                          'Chapter',
                          Icons.library_books_rounded,
                        ),
                        _field(
                          topicController,
                          'Topic',
                          Icons.topic_rounded,
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_month),
                          title: const Text('Study date'),
                          subtitle: Text(_formatDate(plannedDate)),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: plannedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (picked != null) {
                              setDialogState(() {
                                plannedDate = _dateOnly(picked);
                              });
                            }
                          },
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule_rounded),
                          title: const Text('Start time'),
                          subtitle: Text(
                            startTime.format(context),
                          ),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                            );

                            if (picked != null) {
                              setDialogState(() {
                                startTime = picked;
                              });
                            }
                          },
                        ),
                        _field(
                          durationController,
                          'Duration in minutes',
                          Icons.timer_outlined,
                          numeric: true,
                        ),
                        _field(
                          notesController,
                          'Notes (optional)',
                          Icons.notes_rounded,
                          required: false,
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final subject = subjectController.text.trim();
                      final chapter = chapterController.text.trim();
                      final topic = topicController.text.trim();
                      final duration = int.tryParse(
                        durationController.text.trim(),
                      );

                      if (subject.isEmpty ||
                          chapter.isEmpty ||
                          topic.isEmpty ||
                          duration == null ||
                          duration <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enter a subject, chapter, topic and valid duration.',
                            ),
                          ),
                        );
                        return;
                      }

                      final title = titleController.text.trim();

                      Navigator.pop(
                        dialogContext,
                        PlannerSessionModel(
                          id: DateTime.now()
                              .microsecondsSinceEpoch
                              .toString(),
                          title: title.isEmpty ? topic : title,
                          subject: subject,
                          chapter: chapter,
                          topic: topic,
                          plannedDate: plannedDate,
                          startMinutes:
                              startTime.hour * 60 + startTime.minute,
                          durationMinutes: duration,
                          notes: notesController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Save session'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (session != null && mounted) {
        await context.read<PlannerProvider>().addSession(session);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Study session saved.'),
            ),
          );
        }
      }
    } finally {
      titleController.dispose();
      subjectController.dispose();
      chapterController.dispose();
      topicController.dispose();
      durationController.dispose();
      notesController.dispose();
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = true,
    bool numeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType:
            numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = context.watch<PlannerProvider>();
    final sessions = planner.sessionsForDate(_selectedDate);

    final pendingCount =
        sessions.where((session) => !session.isCompleted).length;

    final completedCount =
        sessions.where((session) => session.isCompleted).length;

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        title: const Text(
          'Manual Planner',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Choose date',
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSession,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Plan study'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF242044),
                    Color(0xFF15151D),
                  ],
                ),
                border: Border.all(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'YOUR STUDY PLAN',
                    style: TextStyle(
                      color: Color(0xFFB9B7FF),
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeDay(-1),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: Column(
                            children: [
                              Text(
                                _formatDate(_selectedDate),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap to choose another date',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeDay(1),
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _stat(
                          'Planned',
                          '${sessions.length}',
                          Icons.event_note_rounded,
                        ),
                      ),
                      Expanded(
                        child: _stat(
                          'Pending',
                          '$pendingCount',
                          Icons.pending_actions_rounded,
                        ),
                      ),
                      Expanded(
                        child: _stat(
                          'Completed',
                          '$completedCount',
                          Icons.check_circle_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Study sessions',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (sessions.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 34,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF151515),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 42,
                      color: Color(0xFF818CF8),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Nothing planned for this day',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Tap “Plan study” to add your first session.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...sessions.map(
                (session) => _sessionCard(session),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 19, color: const Color(0xFFB9B7FF)),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _sessionCard(PlannerSessionModel session) {
    final isCompleted = session.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isCompleted,
                onChanged: (_) async {
                  final provider = context.read<PlannerProvider>();

                  if (isCompleted) {
                    await provider.markIncomplete(session.id);
                  } else {
                    await provider.completeSession(session.id);
                  }
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: isCompleted
                            ? Colors.white54
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${session.subject} • ${session.chapter}',
                      style: const TextStyle(
                        color: Color(0xFFB9B7FF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.topic,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _tag(
                          Icons.schedule_rounded,
                          _formatTime(session.startMinutes),
                        ),
                        _tag(
                          Icons.timer_outlined,
                          '${session.durationMinutes} min',
                        ),
                      ],
                    ),
                    if (session.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        session.notes,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete session',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete session?'),
                      content: const Text(
                        'This study session will be removed from your plan.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && mounted) {
                    await context
                        .read<PlannerProvider>()
                        .deleteSession(session.id);
                  }
                },
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
