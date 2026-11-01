
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/chapter_model.dart';
import '../../models/exam_model.dart';
import '../../providers/exam_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../providers/user_provider.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFF07070A);
  static const Color _card = Color(0xFF101014);
  static const Color _violet = Color(0xFF7C5CFF);
  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _gold = Color(0xFFF2C66D);
  static const Color _green = Color(0xFF36D399);
  static const Color _red = Color(0xFFFF5C6C);

  static const String _savedExamKey = 'studyx_planner_exam_id_v1';
  static const String _savedHoursKey = 'studyx_planner_hours_v1';

  late final AnimationController _controller;

  String? _selectedExamId;
  double _dailyHours = 6;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    _restoreSettings();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _restoreSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _selectedExamId = prefs.getString(_savedExamKey);
      _dailyHours = (prefs.getDouble(_savedHoursKey) ?? 6).clamp(1, 14);
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    if (_selectedExamId == null) {
      await prefs.remove(_savedExamKey);
    } else {
      await prefs.setString(_savedExamKey, _selectedExamId!);
    }

    await prefs.setDouble(_savedHoursKey, _dailyHours);
  }

  int _daysLeft(DateTime examDate) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final examDay = DateTime(
      examDate.year,
      examDate.month,
      examDate.day,
    );

    return examDay.difference(today).inDays;
  }

  String _dateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isRevisionStep(ChapterStep step) {
    final title = step.title.trim().toLowerCase();

    return title == 'revision' ||
        title.contains('revision') ||
        title.contains('revise');
  }

  bool _chapterStudyComplete(ChapterModel chapter) {
    final studySteps = chapter.steps.where((step) {
      return !_isRevisionStep(step);
    }).toList();

    if (studySteps.isEmpty) return false;

    return studySteps.every((step) => step.completed);
  }

  List<_PlannerChapter> _collectChapters(
    ExamModel exam,
    SyllabusProvider syllabus,
  ) {
    final result = <_PlannerChapter>[];

    final selectedIds = exam.chapterIds.toSet();

    for (final subject in syllabus.subjects) {
      for (final chapter in subject.chapters) {
        // If the exam has selected chapters, use only those.
        // If none are selected, use the whole syllabus.
        if (selectedIds.isNotEmpty &&
            !selectedIds.contains(chapter.id)) {
          continue;
        }

        result.add(
          _PlannerChapter(
            subjectName: subject.name,
            chapter: chapter,
            completed: _chapterStudyComplete(chapter),
          ),
        );
      }
    }

    return result;
  }

  int _remainingChapterCount(
    List<_PlannerChapter> chapters,
  ) {
    return chapters.where((item) => !item.completed).length;
  }

  int _completedChapterCount(
    List<_PlannerChapter> chapters,
  ) {
    return chapters.where((item) => item.completed).length;
  }

  int _totalEstimatedMinutes(
    List<_PlannerChapter> chapters,
  ) {
    return chapters
        .where((item) => !item.completed)
        .fold<int>(0, (sum, item) {
      final minutes = item.chapter.estimatedMinutes;

      return sum + (minutes <= 0 ? 45 : minutes);
    });
  }

  List<_PlannerChapter> _dueRevisions(
    List<_PlannerChapter> chapters,
  ) {
    final now = DateTime.now();

    return chapters.where((item) {
      final next = item.chapter.nextRevisionAt;

      return next != null && !next.isAfter(now);
    }).toList();
  }

  List<_PlannerChapter> _todayNewChapters(
    List<_PlannerChapter> chapters,
  ) {
    final remaining = chapters
        .where((item) => !item.completed)
        .toList();

    remaining.sort((a, b) {
      final aProgress = a.chapter.steps.isEmpty
          ? 0
          : a.chapter.steps
              .where((step) => !_isRevisionStep(step))
              .where((step) => step.completed)
              .length;

      final bProgress = b.chapter.steps.isEmpty
          ? 0
          : b.chapter.steps
              .where((step) => !_isRevisionStep(step))
              .where((step) => step.completed)
              .length;

      return aProgress.compareTo(bProgress);
    });

    return remaining;
  }

  List<_PlannerSlot> _buildTodayPlan(
    List<_PlannerChapter> chapters,
  ) {
    final slots = <_PlannerSlot>[];

    var minutesLeft = (_dailyHours * 60).round();

    // Revision comes first.
    final due = _dueRevisions(chapters);

    for (final item in due.take(2)) {
      if (minutesLeft < 30) break;

      final duration = minutesLeft >= 45 ? 45 : 30;

      slots.add(
        _PlannerSlot(
          title: item.chapter.name,
          subtitle:
              '${item.subjectName} • Revision due',
          minutes: duration,
          icon: Icons.replay_rounded,
          color: _gold,
        ),
      );

      minutesLeft -= duration;
    }

    // Then unfinished chapters.
    final newChapters = _todayNewChapters(chapters);

    for (final item in newChapters) {
      if (minutesLeft < 35) break;

      final estimated =
          item.chapter.estimatedMinutes <= 0
              ? 45
              : item.chapter.estimatedMinutes;

      final duration = estimated.clamp(35, 90);

      slots.add(
        _PlannerSlot(
          title: item.chapter.name,
          subtitle:
              '${item.subjectName} • New chapter',
          minutes: duration,
          icon: Icons.menu_book_rounded,
          color: _violet,
        ),
      );

      minutesLeft -= duration;
    }

    // Practice.
    if (minutesLeft >= 25) {
      final duration =
          minutesLeft >= 45 ? 45 : minutesLeft;

      slots.add(
        _PlannerSlot(
          title: 'Practice questions',
          subtitle:
              'DPP / PYQs from today\'s topics',
          minutes: duration,
          icon: Icons.quiz_rounded,
          color: _green,
        ),
      );

      minutesLeft -= duration;
    }

    // Quick revision.
    if (minutesLeft >= 20) {
      slots.add(
        _PlannerSlot(
          title: 'Quick revision',
          subtitle:
              'Recall formulas, NCERT lines and mistakes',
          minutes: minutesLeft,
          icon: Icons.bolt_rounded,
          color: _gold,
        ),
      );
    }

    return slots;
  }

  List<_Phase> _buildPhases(
    int daysLeft,
    int remainingChapters,
  ) {
    if (daysLeft <= 0) {
      return const [
        _Phase(
          title: 'Exam date reached',
          subtitle:
              'Start a new planner for the next exam.',
          days: 0,
          icon: Icons.event_busy_rounded,
          color: _red,
        ),
      ];
    }

    // Last 7 days.
    if (daysLeft <= 7) {
      return [
        _Phase(
          title: 'Final revision',
          subtitle:
              'Focus on weak chapters, mistakes and rapid recall.',
          days: daysLeft,
          icon: Icons.local_fire_department_rounded,
          color: _red,
        ),
      ];
    }

    // 8–21 days.
    if (daysLeft <= 21) {
      final revisionDays =
          (daysLeft * 0.60)
              .round()
              .clamp(1, daysLeft);

      final testDays = daysLeft - revisionDays;

      return [
        _Phase(
          title: 'Revision sprint',
          subtitle:
              'Revise completed chapters and attack weak areas.',
          days: revisionDays,
          icon: Icons.replay_rounded,
          color: _gold,
        ),
        if (testDays > 0)
          _Phase(
            title: 'Tests + final review',
            subtitle:
                'Mock tests, error analysis and final revision.',
            days: testDays,
            icon: Icons.quiz_rounded,
            color: _green,
          ),
      ];
    }

    // More than 21 days.
    final bufferDays = daysLeft >= 60 ? 7 : 3;

    final usableDays =
        (daysLeft - bufferDays)
            .clamp(1, daysLeft);

    final syllabusDays =
        (usableDays * 0.58)
            .round()
            .clamp(1, usableDays);

    final revisionDays =
        (usableDays * 0.25)
            .round()
            .clamp(
              1,
              usableDays - syllabusDays,
            );

    final testDays =
        (usableDays -
                syllabusDays -
                revisionDays)
            .clamp(0, usableDays);

    return [
      _Phase(
        title: 'Syllabus completion',
        subtitle:
            'Finish $remainingChapters remaining chapters and clear backlog.',
        days: syllabusDays,
        icon: Icons.menu_book_rounded,
        color: _violet,
      ),
      _Phase(
        title: 'First revision',
        subtitle:
            'Revise, practise questions and strengthen weak chapters.',
        days: revisionDays,
        icon: Icons.replay_rounded,
        color: _gold,
      ),
      if (testDays > 0)
        _Phase(
          title: 'Tests + final revision',
          subtitle:
              'Mock tests, mistakes and exam-focused revision.',
          days: testDays,
          icon: Icons.emoji_events_rounded,
          color: _green,
        ),
      _Phase(
        title: 'Buffer',
        subtitle:
            'Catch up on unfinished work without destroying the plan.',
        days: bufferDays,
        icon: Icons.shield_rounded,
        color: Colors.white,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final exams = context.watch<ExamProvider>().exams;
    final syllabus = context.watch<SyllabusProvider>();
    final user = context.watch<UserProvider>();

    if (_loading) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(
          child: CircularProgressIndicator(
            color: _violet,
          ),
        ),
      );
    }

    ExamModel? selectedExam;

    for (final exam in exams) {
      if (exam.id == _selectedExamId) {
        selectedExam = exam;
        break;
      }
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Study Planner',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Turn your exam date into a daily roadmap',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.42),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            110,
          ),
          children: [
            _animated(
              0,
              _buildSetupCard(
                exams: exams,
                userDailyHours: user.dailyHours,
              ),
            ),
            if (selectedExam == null) ...[
              const SizedBox(height: 16),
              _animated(
                1,
                _buildNoExamCard(),
              ),
            ] else ...[
              const SizedBox(height: 16),
              _animated(
                1,
                _buildGeneratedPlan(
                  exam: selectedExam,
                  chapters: _collectChapters(
                    selectedExam,
                    syllabus,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _animated(
    int index,
    Widget child,
  ) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final start =
            (index * 0.10)
                .clamp(0.0, 0.65);

        final end =
            (start + 0.35)
                .clamp(0.0, 1.0);

        final progress =
            Curves.easeOutCubic.transform(
          ((_controller.value - start) /
                  (end - start))
              .clamp(0.0, 1.0),
        );

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(
              0,
              18 * (1 - progress),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildSetupCard({
    required List<ExamModel> exams,
    required double userDailyHours,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18142A),
            Color(0xFF0E0E13),
          ],
        ),
        border: Border.all(
          color: _violet.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: _violet.withOpacity(0.07),
            blurRadius: 28,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(15),
                  gradient:
                      const LinearGradient(
                    colors: [
                      _violet,
                      _indigo,
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build my plan',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'StudyX will read your syllabus and calculate the roadmap.',
                      style: GoogleFonts.inter(
                        color:
                            Colors.white.withOpacity(0.44),
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Text(
            'PREPARING FOR',
            style: GoogleFonts.inter(
              color: _gold,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            initialValue: exams.any(
              (exam) => exam.id == _selectedExamId,
            )
                ? _selectedExamId
                : null,
            dropdownColor:
                const Color(0xFF15151B),
            iconEnabledColor:
                Colors.white.withOpacity(0.55),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: exams.isEmpty
                  ? 'Create an exam first'
                  : 'Select an exam',
              hintStyle: GoogleFonts.inter(
                color:
                    Colors.white.withOpacity(0.34),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.event_rounded,
                color: _violet,
                size: 19,
              ),
              filled: true,
              fillColor:
                  Colors.white.withOpacity(0.035),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide(
                  color:
                      Colors.white.withOpacity(0.07),
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(15),
                borderSide: BorderSide(
                  color:
                      _violet.withOpacity(0.45),
                ),
              ),
            ),
            items: exams.map((exam) {
              final days =
                  _daysLeft(exam.examDate);

              return DropdownMenuItem<String>(
                value: exam.id,
                child: Text(
                  '${exam.name} • ${days < 0 ? 'completed' : '$days days'}',
                  overflow:
                      TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: exams.isEmpty
                ? null
                : (value) async {
                    setState(() {
                      _selectedExamId = value;
                    });

                    await _saveSettings();
                  },
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Text(
                  'Daily study time',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      _gold.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(11),
                  border: Border.all(
                    color:
                        _gold.withOpacity(0.14),
                  ),
                ),
                child: Text(
                  '${_dailyHours.toStringAsFixed(_dailyHours % 1 == 0 ? 0 : 1)} h',
                  style: GoogleFonts.inter(
                    color: _gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          Slider(
            value: _dailyHours,
            min: 1,
            max: 14,
            divisions: 26,
            activeColor: _violet,
            inactiveColor:
                Colors.white.withOpacity(0.08),
            onChanged: (value) {
              setState(() {
                _dailyHours =
                    double.parse(
                  value.toStringAsFixed(1),
                );
              });
            },
            onChangeEnd: (_) =>
                _saveSettings(),
          ),

          Text(
            'Your profile target is $userDailyHours h/day. You can override it here for this exam.',
            style: GoogleFonts.inter(
              color:
                  Colors.white.withOpacity(0.32),
              fontSize: 10,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: exams.isEmpty
                  ? null
                  : () async {
                      if (_selectedExamId ==
                          null) {
                        setState(() {
                          _selectedExamId =
                              exams.first.id;
                        });
                      }

                      setState(() {});

                      await _saveSettings();
                    },
              icon: const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
              ),
              label: Text(
                'GENERATE MY PLAN',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: _violet,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Colors.white.withOpacity(0.06),
                disabledForegroundColor:
                    Colors.white.withOpacity(0.25),
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoExamCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_note_rounded,
            color: _violet,
            size: 40,
          ),
          const SizedBox(height: 13),
          Text(
            'Create an exam first',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Planner needs an exam date so it can calculate the remaining days and build your roadmap.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color:
                  Colors.white.withOpacity(0.42),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedPlan({
    required ExamModel exam,
    required List<_PlannerChapter> chapters,
  }) {
    final daysLeft =
        _daysLeft(exam.examDate);

    final total = chapters.length;

    final completed =
        _completedChapterCount(chapters);

    final remaining =
        _remainingChapterCount(chapters);

    final estimatedMinutes =
        _totalEstimatedMinutes(chapters);

    final dueRevisions =
        _dueRevisions(chapters);

    final phases =
        _buildPhases(
      daysLeft,
      remaining,
    );

    final todayPlan =
        _buildTodayPlan(chapters);

    final selectedText =
        exam.chapterIds.isEmpty
            ? 'Full syllabus'
            : '${exam.chapterIds.length} selected chapters';

    final progress =
        total == 0
            ? 0.0
            : completed / total;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _card,
            borderRadius:
                BorderRadius.circular(24),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.07),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      exam.name,
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                  _daysBadge(daysLeft),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                _dateLabel(exam.examDate),
                style: GoogleFonts.inter(
                  color:
                      Colors.white.withOpacity(0.42),
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _metric(
                      '${daysLeft < 0 ? 0 : daysLeft}',
                      'Days left',
                      _gold,
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      '$total',
                      'Chapters',
                      _violet,
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      '$remaining',
                      'Remaining',
                      _red,
                    ),
                  ),
                  Expanded(
                    child: _metric(
                      '${(_dailyHours * 60).round()}m',
                      'Daily',
                      _green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Text(
                    'Syllabus progress',
                    style: GoogleFonts.inter(
                      color:
                          Colors.white.withOpacity(0.48),
                      fontSize: 10,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completed / $total',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius:
                    BorderRadius.circular(10),
                child:
                    LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  backgroundColor:
                      Colors.white.withOpacity(0.06),
                  valueColor:
                      const AlwaysStoppedAnimation(
                    _violet,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                '$selectedText • about ${_formatMinutes(estimatedMinutes)} of unfinished chapter time',
                style: GoogleFonts.inter(
                  color:
                      Colors.white.withOpacity(0.30),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        _sectionTitle(
          'TODAY',
          'What StudyX recommends you work on now',
        ),

        const SizedBox(height: 10),

        if (todayPlan.isEmpty)
          _smallMessage(
            'No new chapter work detected. Use today for revision, tests and weak topics.',
            Icons.check_circle_outline_rounded,
            _green,
          )
        else
          ...List.generate(
            todayPlan.length,
            (index) => Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 9,
              ),
              child: _todayPlanTile(
                todayPlan[index],
              ),
            ),
          ),

        const SizedBox(height: 18),

        _sectionTitle(
          'ROADMAP',
          'StudyX divides your remaining ${daysLeft < 0 ? 0 : daysLeft} days into phases',
        ),

        const SizedBox(height: 10),

        ...List.generate(
          phases.length,
          (index) => Padding(
            padding:
                const EdgeInsets.only(
              bottom: 10,
            ),
            child: _phaseCard(
              phase: phases[index],
              index: index,
            ),
          ),
        ),

        const SizedBox(height: 8),

        _buildPlannerLogicCard(
          daysLeft: daysLeft,
          remaining: remaining,
          dueRevisions:
              dueRevisions.length,
        ),
      ],
    );
  }

  Widget _daysBadge(int days) {
    final color = days < 0
        ? _red
        : days <= 7
            ? _gold
            : _green;

    final text = days < 0
        ? 'Completed'
        : days == 0
            ? 'Today'
            : '$days days';

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color:
              color.withOpacity(0.17),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _metric(
    String value,
    String label,
    Color color,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.inter(
            color:
                Colors.white.withOpacity(0.34),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: _gold,
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            color:
                Colors.white.withOpacity(0.42),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _todayPlanTile(
    _PlannerSlot slot,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.065),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  slot.color.withOpacity(0.10),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              slot.icon,
              color: slot.color,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  slot.title,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  slot.subtitle,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color:
                        Colors.white.withOpacity(0.36),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '${slot.minutes}m',
            style: GoogleFonts.inter(
              color: slot.color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _phaseCard({
    required _Phase phase,
    required int index,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _card,
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color:
              phase.color.withOpacity(0.11),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:
                  phase.color.withOpacity(0.09),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Icon(
              phase.icon,
              color: phase.color,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${phase.title}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phase.subtitle,
                  style: GoogleFonts.inter(
                    color:
                        Colors.white.withOpacity(0.36),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Text(
            '${phase.days}d',
            style: GoogleFonts.inter(
              color: phase.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerLogicCard({
    required int daysLeft,
    required int remaining,
    required int dueRevisions,
  }) {
    final safeDays =
        daysLeft <= 0 ? 0 : daysLeft;

    final chaptersPerDay =
        safeDays == 0
            ? 0.0
            : remaining / safeDays;

    final dailyMinutes =
        (_dailyHours * 60).round();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D12),
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              _gold.withOpacity(0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_rounded,
                color: _gold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'HOW THIS PLAN WAS CALCULATED',
                style: GoogleFonts.inter(
                  color: _gold,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          _logicLine(
            'Remaining chapters',
            '$remaining',
          ),

          _logicLine(
            'Days available',
            '$safeDays',
          ),

          _logicLine(
            'Average chapter pace',
            '${chaptersPerDay.toStringAsFixed(2)}/day',
          ),

          _logicLine(
            'Daily study capacity',
            '$dailyMinutes min',
          ),

          _logicLine(
            'Revision due now',
            '$dueRevisions',
          ),

          const SizedBox(height: 10),

          Text(
            'The planner prioritizes due revisions, unfinished chapters, practice and a buffer instead of simply dividing chapters equally across every day.',
            style: GoogleFonts.inter(
              color:
                  Colors.white.withOpacity(0.30),
              fontSize: 10,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _logicLine(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color:
                    Colors.white.withOpacity(0.40),
                fontSize: 10,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallMessage(
    String text,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            color.withOpacity(0.055),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color:
              color.withOpacity(0.11),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color:
                    Colors.white.withOpacity(0.48),
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (mins == 0) {
      return '$hours h';
    }

    return '$hours h $mins min';
  }
}

class _PlannerChapter {
  final String subjectName;
  final ChapterModel chapter;
  final bool completed;

  const _PlannerChapter({
    required this.subjectName,
    required this.chapter,
    required this.completed,
  });
}

class _PlannerSlot {
  final String title;
  final String subtitle;
  final int minutes;
  final IconData icon;
  final Color color;

  const _PlannerSlot({
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.icon,
    required this.color,
  });
}

class _Phase {
  final String title;
  final String subtitle;
  final int days;
  final IconData icon;
  final Color color;

  const _Phase({
    required this.title,
    required this.subtitle,
    required this.days,
    required this.icon,
    required this.color,
  });
}
