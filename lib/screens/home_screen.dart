
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../services/background_study_timer.dart';
import '../theme/app_colors.dart';

import '../providers/user_provider.dart';
import '../providers/study_session_provider.dart';
import '../providers/task_provider.dart';
import '../providers/syllabus_provider.dart';
import '../providers/exam_provider.dart';

const Color _bg = AppColors.background;
const Color _panel = AppColors.card;
const Color _purple = AppColors.primary;
const Color _blue = AppColors.accent;
const Color _green = AppColors.success;
const Color _orange = AppColors.warning;
const Color _muted = AppColors.textSecondary;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncBackgroundTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncBackgroundTimer();
    }
  }

  Future<void> _syncBackgroundTimer() async {
    // The foreground-task plugin is mobile-only. The web timer is managed
    // locally by this screen instead.
    if (kIsWeb) return;

    try {
      final serviceRunning = await FlutterForegroundTask.isRunningService;

      if (!serviceRunning) {
        final finishedSeconds =
            await BackgroundStudyTimer.takeFinishedSessionSeconds();

        if (finishedSeconds > 0 && mounted) {
          await context.read<StudySessionProvider>().addSession(finishedSeconds);
          if (!mounted) return;
          setState(() {
            _elapsedSeconds = 0;
            _isRunning = false;
          });
          _timer?.cancel();
          _timer = null;
          _showMessage('Completed background session saved!');
        }
        return;
      }

      final elapsed = await BackgroundStudyTimer.getElapsedSeconds();
      final running = await BackgroundStudyTimer.isTimerRunning();

      if (!mounted) return;
      setState(() {
        _elapsedSeconds = elapsed;
        _isRunning = running;
      });

      _timer?.cancel();
      _timer = null;
      if (running) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
          final latest = await BackgroundStudyTimer.getElapsedSeconds();
          if (!mounted) return;
          setState(() => _elapsedSeconds = latest);
        });
      }
    } catch (_) {
      // Keep the dashboard usable if Android denies a permission.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startTimer() async {
    if (_isRunning) return;

    // On web, use a local timer instead of the mobile foreground service.
    if (kIsWeb) {
      if (!mounted) return;
      setState(() => _isRunning = true);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !_isRunning) return;
        setState(() => _elapsedSeconds++);
      });
      return;
    }

    try {
      await BackgroundStudyTimer.resume();
      final elapsed = await BackgroundStudyTimer.getElapsedSeconds();
      if (!mounted) return;

      setState(() {
        _elapsedSeconds = elapsed;
        _isRunning = true;
      });

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
        final latest = await BackgroundStudyTimer.getElapsedSeconds();
        if (!mounted) return;
        setState(() => _elapsedSeconds = latest);
      });
    } catch (e) {
      if (mounted) {
        _showMessage('Could not start the background timer: $e');
      }
    }
  }

  Future<void> _pauseTimer() async {
    if (kIsWeb) {
      _timer?.cancel();
      _timer = null;
      if (!mounted) return;
      setState(() => _isRunning = false);
      return;
    }

    await BackgroundStudyTimer.pause();
    _timer?.cancel();
    _timer = null;

    final elapsed = await BackgroundStudyTimer.getElapsedSeconds();
    if (!mounted) return;
    setState(() {
      _elapsedSeconds = elapsed;
      _isRunning = false;
    });
  }

  Future<void> _resetTimer() async {
    _timer?.cancel();
    _timer = null;

    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds = 0;
        _isRunning = false;
      });
      return;
    }

    try {
      await BackgroundStudyTimer.reset();
      await BackgroundStudyTimer.takeFinishedSessionSeconds();
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _elapsedSeconds = 0;
      _isRunning = false;
    });
  }

  Future<void> _saveSession() async {
    final currentSeconds = kIsWeb
        ? _elapsedSeconds
        : await BackgroundStudyTimer.getElapsedSeconds();
    final seconds = currentSeconds > 0 ? currentSeconds : _elapsedSeconds;

    if (seconds <= 0) {
      _showMessage('Study for a little while before saving a session.');
      return;
    }

    if (!kIsWeb) {
      await BackgroundStudyTimer.pause();
    }
    _timer?.cancel();
    _timer = null;

    try {
      await context.read<StudySessionProvider>().addSession(seconds);
      if (!kIsWeb) {
        await BackgroundStudyTimer.reset();
        await BackgroundStudyTimer.takeFinishedSessionSeconds();
      }

      if (!mounted) return;

      setState(() {
        _elapsedSeconds = 0;
        _isRunning = false;
      });
      _showMessage('Study session saved successfully!');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Could not save the session. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _panel,
      ),
    );
  }

  String _timerText(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  String _durationText(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateText() {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, '
        '${months[now.month - 1]} ${now.day}';
  }

  // These helpers tolerate optional display fields on existing models.
  String _readText(dynamic object, List<String> fields,
      {String fallback = ''}) {
    for (final field in fields) {
      try {
        final value = switch (field) {
          'name' => object.name,
          'title' => object.title,
          'taskName' => object.taskName,
          'subject' => object.subject,
          'chapterName' => object.chapterName,
          _ => null,
        };

        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      } catch (_) {
        // Try the next possible display field.
      }
    }
    return fallback;
  }

  DateTime? _readDate(dynamic object) {
    try {
      final value = object.examDate;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
    } catch (_) {}
    return null;
  }

  bool _isCompleted(dynamic task) {
    try {
      return task.isCompleted == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<
        UserProvider,
        StudySessionProvider,
        TaskProvider,
        SyllabusProvider,
        ExamProvider>(
      builder: (context, user, study, tasks, syllabus, examProvider, child) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final int todaySeconds =
            study.secondsForDate(now).clamp(0, 1000000000);

        final double dailyGoalHours =
            (user.dailyHours as num?)?.toDouble() ?? 4.0;

        final int goalSeconds = (dailyGoalHours * 3600).round();
        final double goalProgress = goalSeconds <= 0
            ? 0.0
            : (todaySeconds / goalSeconds).clamp(0.0, 1.0);

        final subjects = syllabus.subjects;
        int totalChapters = 0;
        int completedChapters = 0;

        for (final subject in subjects) {
          for (final chapter in subject.chapters) {
            totalChapters++;
            if (chapter.isStudyCompleted == true) {
              completedChapters++;
            }
          }
        }

        final double syllabusProgress = totalChapters == 0
            ? 0.0
            : completedChapters / totalChapters;

        final List<dynamic> todayTaskList = [];
        try {
          for (final task in tasks.todayTasks as Iterable) {
            todayTaskList.add(task);
          }
        } catch (_) {}

        int completedTasks = 0;
        for (final task in todayTaskList) {
          if (_isCompleted(task)) completedTasks++;
        }

        final List<dynamic> upcomingExams = [];
        try {
          for (final exam in examProvider.exams as Iterable) {
            final date = _readDate(exam);
            if (date != null &&
                !date.isBefore(today)) {
              upcomingExams.add(exam);
            }
          }
        } catch (_) {}

        dynamic nextExam;
        DateTime? nextExamDate;

        for (final exam in upcomingExams) {
          final date = _readDate(exam);
          if (date != null &&
              (nextExamDate == null || date.isBefore(nextExamDate))) {
            nextExam = exam;
            nextExamDate = date;
          }
        }

        final List<dynamic> revisionChapters = [];
        try {
          for (final chapter
              in syllabus.getChaptersForRevision() as Iterable) {
            revisionChapters.add(chapter);
          }
        } catch (_) {}

        final name = user.name.toString().trim();
        final displayName = name.isEmpty ? 'Student' : name;

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: RefreshIndicator(
              color: _purple,
              onRefresh: () async {
                setState(() {});
                await Future<void>.delayed(
                  const Duration(milliseconds: 250),
                );
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                children: [
                  _buildHeader(displayName),
                  const SizedBox(height: 24),
                  _buildStudyTimer(),
                  const SizedBox(height: 22),
                  _buildSectionHeading(
                    'Your progress',
                    'A little progress every day',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.schedule_rounded,
                          color: _blue,
                          label: 'Study time',
                          value: _durationText(todaySeconds),
                          subtitle: 'Today',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          icon: Icons.task_alt_rounded,
                          color: _green,
                          label: 'Tasks done',
                          value: '$completedTasks/${todayTaskList.length}',
                          subtitle: 'Today',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          icon: Icons.menu_book_rounded,
                          color: _purple,
                          label: 'Chapters',
                          value: '$completedChapters',
                          subtitle: 'Completed',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeading(
                    'Daily study goal',
                    '${(dailyGoalHours * 60).round()} minutes planned',
                  ),
                  const SizedBox(height: 12),
                  _buildGoalCard(
                    progress: goalProgress,
                    studied: _durationText(todaySeconds),
                    target: _durationText(goalSeconds),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeading(
                    'Today’s tasks',
                    '${todayTaskList.length - completedTasks} remaining',
                  ),
                  const SizedBox(height: 12),
                  _buildTasksCard(todayTaskList),
                  const SizedBox(height: 24),
                  _buildSectionHeading(
                    'Syllabus progress',
                    '$completedChapters of $totalChapters chapters',
                  ),
                  const SizedBox(height: 12),
                  _buildSyllabusCard(
                    subjects: subjects,
                    completed: completedChapters,
                    total: totalChapters,
                    progress: syllabusProgress,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeading(
                    'Upcoming exam',
                    '${upcomingExams.length} upcoming',
                  ),
                  const SizedBox(height: 12),
                  _buildExamCard(nextExam, nextExamDate, today),
                  const SizedBox(height: 24),
                  _buildSectionHeading(
                    'Revision corner',
                    '${revisionChapters.length} chapters to review',
                  ),
                  const SizedBox(height: 12),
                  _buildRevisionCard(revisionChapters),
                  const SizedBox(height: 24),
                  _buildMotivationCard(goalProgress),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _dateText(),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [_purple, _blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ],
    );
  }

  Widget _buildStudyTimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF252044), Color(0xFF171B30)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: _purple.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: _orange, size: 20),
              SizedBox(width: 8),
              Text(
                'FOCUS SESSION',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Spacer(),
              Icon(Icons.circle, size: 8, color: _green),
              SizedBox(width: 6),
              Text(
                'Study mode',
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: Column(
              children: [
                Text(
                  _timerText(_elapsedSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 43,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [],
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _isRunning
                      ? 'Stay focused. You are doing great.'
                      : 'Your next productive session starts here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                  icon: Icon(
                    _isRunning
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  label: Text(_isRunning ? 'Pause' : 'Start studying'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _timerIconButton(
                icon: Icons.restart_alt_rounded,
                onTap: _resetTimer,
              ),
              const SizedBox(width: 10),
              _timerIconButton(
                icon: Icons.save_alt_rounded,
                onTap: _saveSession,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 47,
          height: 48,
          child: Icon(icon, color: Colors.white70, size: 21),
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            subtitle,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard({
    required double progress,
    required String studied,
    required String target,
  }) {
    final percentage = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _panel,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: _green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily target',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$studied studied • $target goal',
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: _green,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(_green),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              progress >= 1
                  ? 'Daily goal completed. Excellent work!'
                  : 'Keep going — every focused minute counts.',
              style: const TextStyle(color: _muted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksCard(List<dynamic> taskList) {
    if (taskList.isEmpty) {
      return _emptyCard(
        icon: Icons.checklist_rounded,
        title: 'No tasks scheduled for today',
        subtitle: 'Your day is ready for planning.',
      );
    }

    final visibleTasks = taskList.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < visibleTasks.length; i++) ...[
            if (i > 0)
              Divider(
                height: 18,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            Row(
              children: [
                Icon(
                  _isCompleted(visibleTasks[i])
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: _isCompleted(visibleTasks[i]) ? _green : _muted,
                  size: 21,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _readText(
                      visibleTasks[i],
                      ['title', 'name', 'taskName'],
                      fallback: 'Study task ${i + 1}',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isCompleted(visibleTasks[i])
                          ? _muted
                          : Colors.white,
                      fontSize: 13,
                      decoration: _isCompleted(visibleTasks[i])
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isCompleted(visibleTasks[i]) ? 'Done' : 'Pending',
                  style: TextStyle(
                    color: _isCompleted(visibleTasks[i])
                        ? _green
                        : _orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
          if (taskList.length > visibleTasks.length) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '+ ${taskList.length - visibleTasks.length} more tasks',
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSyllabusCard({
    required dynamic subjects,
    required int completed,
    required int total,
    required double progress,
  }) {
    if (subjects.isEmpty) {
      return _emptyCard(
        icon: Icons.menu_book_rounded,
        title: 'Your syllabus is waiting',
        subtitle: 'Add subjects and chapters to track progress.',
      );
    }

    final visibleSubjects = <dynamic>[];
    for (final subject in subjects) {
      visibleSubjects.add(subject);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${(progress * 100).round()}% overall completed',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completed/$total',
                style: const TextStyle(color: _purple, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(_purple),
            ),
          ),
          const SizedBox(height: 18),
          for (int i = 0; i < visibleSubjects.length; i++) ...[
            if (i > 0) const SizedBox(height: 15),
            _subjectProgress(visibleSubjects[i], i),
          ],
        ],
      ),
    );
  }

  Widget _subjectProgress(dynamic subject, int index) {
    int chapterCount = 0;
    int doneCount = 0;

    for (final chapter in subject.chapters) {
      chapterCount++;
      if (chapter.isStudyCompleted == true) doneCount++;
    }

    final double progress =
        chapterCount == 0 ? 0 : doneCount / chapterCount;

    const colors = [_blue, _purple, _green, _orange];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _readText(
                  subject,
                  ['name'],
                  fallback: 'Subject ${index + 1}',
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$doneCount/$chapterCount chapters',
              style: const TextStyle(color: _muted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.07),
            valueColor: AlwaysStoppedAnimation<Color>(
              colors[index % colors.length],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExamCard(
    dynamic nextExam,
    DateTime? examDate,
    DateTime today,
  ) {
    if (nextExam == null || examDate == null) {
      return _emptyCard(
        icon: Icons.event_available_rounded,
        title: 'No upcoming exam found',
        subtitle: 'Add your next exam to see its countdown here.',
      );
    }

    final days = DateTime(
      examDate.year,
      examDate.month,
      examDate.day,
    ).difference(today).inDays;

    final dateLabel =
        '${examDate.day.toString().padLeft(2, '0')}/'
        '${examDate.month.toString().padLeft(2, '0')}/'
        '${examDate.year}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF182A42), Color(0xFF151A2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _blue.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 58,
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.event_note_rounded,
              color: _blue,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _readText(
                    nextExam,
                    ['name', 'title'],
                    fallback: 'Upcoming exam',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  dateLabel,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                days == 0 ? 'TODAY' : '$days',
                style: const TextStyle(
                  color: _blue,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                days == 0 ? 'Exam day' : 'days left',
                style: const TextStyle(color: _muted, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevisionCard(List<dynamic> chapters) {
    if (chapters.isEmpty) {
      return _emptyCard(
        icon: Icons.history_edu_rounded,
        title: 'Revision list is clear',
        subtitle: 'Keep revisiting completed chapters to retain them.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          for (int i = 0; i < chapters.length && i < 4; i++) ...[
            if (i > 0)
              Divider(
                height: 18,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            Row(
              children: [
                Container(
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    color: _orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: _orange,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    _readText(
                      chapters[i],
                      ['name', 'chapterName', 'title'],
                      fallback: 'Revision chapter ${i + 1}',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  'Review',
                  style: TextStyle(
                    color: _orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMotivationCard(double progress) {
    final message = progress >= 1
        ? 'You reached your study goal today. Keep the habit going!'
        : progress >= 0.5
            ? 'You are making progress. Finish the next small task.'
            : 'Start small. One focused session can change your day.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF19172A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _purple.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: _purple,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your daily reminder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Icon(icon, color: _muted, size: 29),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: _panel,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
    );
  }
}
