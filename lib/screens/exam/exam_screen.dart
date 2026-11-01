
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/exam_model.dart';
import '../../providers/exam_provider.dart';

import 'create_exam_screen.dart';
import 'exam_dashboard_screen.dart';
import 'planner_screen.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Color _background = Color(0xFF07070A);
  static const Color _card = Color(0xFF101014);
  static const Color _card2 = Color(0xFF14141A);
  static const Color _violet = Color(0xFF7C5CFF);
  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _gold = Color(0xFFF2C66D);
  static const Color _green = Color(0xFF36D399);
  static const Color _red = Color(0xFFFF5C6C);
  static const Color _blue = Color(0xFF4F8CFF);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openCreateExam() {
    Navigator.push(
      context,
      _premiumRoute(
        CreateExamScreen(),
      ),
    );
  }

  void _openDashboard(String examId) {
    Navigator.push(
      context,
      _premiumRoute(
        ExamDashboardScreen(
          examId: examId,
        ),
      ),
    );
  }

  void _openPlanner() {
    // Deliberately NOT const.
    // This also works if PlannerScreen does not have a const
    // constructor.
    Navigator.push(
      context,
      _premiumRoute(
        PlannerScreen(),
      ),
    );
  }

  PageRouteBuilder _premiumRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration:
          const Duration(milliseconds: 420),
      reverseTransitionDuration:
          const Duration(milliseconds: 320),
      pageBuilder: (
        context,
        animation,
        secondaryAnimation,
      ) {
        return page;
      },
      transitionsBuilder: (
        context,
        animation,
        secondaryAnimation,
        child,
      ) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.025, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // DATE
  // ============================================================

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

  String _daysLabel(int days) {
    if (days < 0) {
      final passed = days.abs();

      return passed == 1
          ? '1 day ago'
          : '$passed days ago';
    }

    if (days == 0) {
      return 'Today';
    }

    if (days == 1) {
      return '1 day left';
    }

    return '$days days left';
  }

  // ============================================================
  // STATUS
  // ============================================================

  Color _statusColor(int daysLeft) {
    if (daysLeft < 0) {
      return _red;
    }

    if (daysLeft == 0) {
      return _gold;
    }

    if (daysLeft <= 7) {
      return _gold;
    }

    return _green;
  }

  String _statusText(int daysLeft) {
    if (daysLeft < 0) {
      return 'Past exam';
    }

    if (daysLeft == 0) {
      return 'Today';
    }

    if (daysLeft <= 7) {
      return 'Coming soon';
    }

    return 'Upcoming';
  }

  IconData _statusIcon(int daysLeft) {
    if (daysLeft < 0) {
      return Icons.history_rounded;
    }

    if (daysLeft == 0) {
      return Icons.bolt_rounded;
    }

    if (daysLeft <= 7) {
      return Icons.priority_high_rounded;
    }

    return Icons.event_available_rounded;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteExam(ExamModel exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card2,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: _red.withOpacity(0.18),
            ),
          ),
          title: Text(
            'Delete exam?',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This will permanently remove "${exam.name}" '
            'from your exam list.',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.55),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _red.withOpacity(0.12),
                foregroundColor: _red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    await context.read<ExamProvider>().deleteExam(
          exam.id,
        );

    if (!mounted) return;

    _showMessage(
      'Exam deleted.',
      success: true,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<ExamProvider>(
      builder: (
        context,
        provider,
        child,
      ) {
        final exams = provider.exams;

        final upcoming = exams
            .where(
              (exam) => _daysLeft(exam.examDate) >= 0,
            )
            .toList();

        final past = exams
            .where(
              (exam) => _daysLeft(exam.examDate) < 0,
            )
            .toList();

        upcoming.sort(
          (a, b) => _daysLeft(a.examDate)
              .compareTo(
                _daysLeft(b.examDate),
              ),
        );

        final nearestExam =
            upcoming.isEmpty
                ? null
                : upcoming.first;

        return Scaffold(
          backgroundColor: _background,
          appBar: _buildAppBar(),
          floatingActionButton:
              _buildFloatingActionButton(),
          body: SafeArea(
            child: exams.isEmpty
                ? _buildEmptyState()
                : _buildContent(
                    exams,
                    upcoming,
                    past,
                    nearestExam,
                  ),
          ),
        );
      },
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _background,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 20,
      title: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'My Exams',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Stay ahead of every deadline',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.40),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        _appBarButton(
          icon: Icons.auto_awesome_rounded,
          color: _violet,
          tooltip: 'Study Planner',
          onTap: _openPlanner,
        ),
        const SizedBox(width: 5),
        Container(
          margin:
              const EdgeInsets.only(right: 17),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.035),
            border: Border.all(
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            color: _gold,
            size: 18,
          ),
        ),
      ],
    );
  }

  Widget _appBarButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.17),
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 18,
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(
    List<ExamModel> exams,
    List<ExamModel> upcoming,
    List<ExamModel> past,
    ExamModel? nearestExam,
  ) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ListView(
          physics:
              const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            115,
          ),
          children: [
            _animatedItem(
              index: 0,
              child: _buildHeroHeader(
                total: exams.length,
                upcoming: upcoming.length,
              ),
            ),

            const SizedBox(height: 15),

            _animatedItem(
              index: 1,
              child: _buildStatsRow(
                total: exams.length,
                upcoming: upcoming.length,
                past: past.length,
              ),
            ),

            if (nearestExam != null) ...[
              const SizedBox(height: 17),
              _animatedItem(
                index: 2,
                child: _buildNextExamCard(
                  nearestExam,
                ),
              ),
            ],

            const SizedBox(height: 27),

            _animatedItem(
              index: 3,
              child: Row(
                children: [
                  Text(
                    'All exams',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${exams.length} total',
                    style: GoogleFonts.inter(
                      color:
                          Colors.white.withOpacity(0.35),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            ...List.generate(
              exams.length,
              (index) {
                final exam = exams[index];

                return _animatedItem(
                  index: 4 + index,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _buildExamCard(
                      exam,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHeroHeader({
    required int total,
    required int upcoming,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(25),
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18152D),
            Color(0xFF0D0D13),
          ],
        ),
        border: Border.all(
          color: _violet.withOpacity(0.17),
        ),
        boxShadow: [
          BoxShadow(
            color:
                _violet.withOpacity(0.07),
            blurRadius: 30,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -42,
            child: Container(
              width: 145,
              height: 145,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _violet.withOpacity(0.055),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -60,
            child: Container(
              width: 90,
              height: 90,
              decoration:
                  BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _gold.withOpacity(0.025),
              ),
            ),
          ),
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 49,
                    height: 49,
                    decoration:
                        BoxDecoration(
                      gradient:
                          const LinearGradient(
                        colors: [
                          _violet,
                          _indigo,
                        ],
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _violet
                              .withOpacity(
                            0.24,
                          ),
                          blurRadius: 18,
                          offset:
                              const Offset(
                            0,
                            6,
                          ),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration:
                        BoxDecoration(
                      color: _gold
                          .withOpacity(0.07),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                      border: Border.all(
                        color: _gold
                            .withOpacity(
                          0.13,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          color: _gold,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$upcoming upcoming',
                          style:
                              GoogleFonts.inter(
                            color: _gold,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Your exam journey',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                total == 1
                    ? '1 exam is currently saved.'
                    : '$total exams are currently saved.',
                style: GoogleFonts.inter(
                  color:
                      Colors.white.withOpacity(0.45),
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStatsRow({
    required int total,
    required int upcoming,
    required int past,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            icon: Icons.layers_rounded,
            value: '$total',
            label: 'Total',
            accent: _violet,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _buildMiniStat(
            icon: Icons.schedule_rounded,
            value: '$upcoming',
            label: 'Upcoming',
            accent: _gold,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _buildMiniStat(
            icon:
                Icons.history_rounded,
            value: '$past',
            label: 'Past',
            accent: _blue,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 15,
      ),
      decoration:
          BoxDecoration(
        color: _card,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.055),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: accent,
            size: 18,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color:
                  Colors.white.withOpacity(0.35),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEXT EXAM
  // ============================================================

  Widget _buildNextExamCard(
    ExamModel exam,
  ) {
    final days = _daysLeft(
      exam.examDate,
    );

    final accent =
        _statusColor(days);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            _openDashboard(exam.id),
        borderRadius:
            BorderRadius.circular(23),
        splashColor:
            _violet.withOpacity(0.08),
        child: Ink(
          padding:
              const EdgeInsets.all(20),
          decoration:
              BoxDecoration(
            color: _card,
            borderRadius:
                BorderRadius.circular(23),
            border: Border.all(
              color:
                  accent.withOpacity(0.18),
            ),
            boxShadow: [
              BoxShadow(
                color:
                    accent.withOpacity(0.055),
                blurRadius: 25,
                spreadRadius: -8,
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
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          accent.withOpacity(
                        0.08,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        9,
                      ),
                    ),
                    child: Text(
                      'NEXT EXAM',
                      style:
                          GoogleFonts.inter(
                        color: accent,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white
                        .withOpacity(0.30),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                exam.name,
                maxLines: 2,
                overflow:
                    TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    color: Colors.white
                        .withOpacity(0.38),
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _dateLabel(
                      exam.examDate,
                    ),
                    style:
                        GoogleFonts.inter(
                      color: Colors.white
                          .withOpacity(0.45),
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 4,
                    height: 4,
                    decoration:
                        BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white
                          .withOpacity(0.18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _daysLabel(days),
                    style:
                        GoogleFonts.inter(
                      color: accent,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EXAM CARD
  // ============================================================

  Widget _buildExamCard(
    ExamModel exam,
  ) {
    final days =
        _daysLeft(exam.examDate);

    final accent =
        _statusColor(days);

    final provider =
        context.read<ExamProvider>();

    double progress = 0;

    try {
      progress =
          provider.getExamProgress(exam);
    } catch (_) {
      progress = 0;
    }

    final chapters =
        provider.getExamChapters(exam);

    final selectedChapters =
        chapters.length;

    final topicCount =
        exam.topics.length;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () =>
            _openDashboard(exam.id),
        onLongPress: () =>
            _deleteExam(exam),
        borderRadius:
            BorderRadius.circular(22),
        splashColor:
            _violet.withOpacity(0.07),
        highlightColor:
            Colors.white.withOpacity(0.018),
        child: Ink(
          padding:
              const EdgeInsets.all(17),
          decoration:
              BoxDecoration(
            color: _card,
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color:
                  Colors.white.withOpacity(0.055),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _buildDateBox(
                    exam.examDate,
                    accent,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.name,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons
                                  .event_rounded,
                              color: Colors.white
                                  .withOpacity(
                                0.32,
                              ),
                              size: 13,
                            ),
                            const SizedBox(
                                width: 5),
                            Flexible(
                              child: Text(
                                _dateLabel(
                                  exam.examDate,
                                ),
                                overflow:
                                    TextOverflow
                                        .ellipsis,
                                style:
                                    GoogleFonts
                                        .inter(
                                  color: Colors.white
                                      .withOpacity(
                                    0.38,
                                  ),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildStatusChip(
                          days,
                          accent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    color: _card2,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    onSelected: (value) {
                      if (value == 'open') {
                        _openDashboard(
                          exam.id,
                        );
                      } else if (value ==
                          'delete') {
                        _deleteExam(exam);
                      }
                    },
                    itemBuilder:
                        (context) => [
                      PopupMenuItem(
                        value: 'open',
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .dashboard_rounded,
                              color: _violet,
                              size: 18,
                            ),
                            const SizedBox(
                                width: 9),
                            Text(
                              'Open dashboard',
                              style:
                                  GoogleFonts
                                      .inter(
                                color:
                                    Colors.white,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .delete_outline_rounded,
                              color: _red,
                              size: 18,
                            ),
                            const SizedBox(
                                width: 9),
                            Text(
                              'Delete exam',
                              style:
                                  GoogleFonts
                                      .inter(
                                color:
                                    Colors.white,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration:
                          BoxDecoration(
                        color: Colors.white
                            .withOpacity(
                          0.035,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          11,
                        ),
                      ),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.white
                            .withOpacity(0.42),
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Preparation
              Container(
                padding:
                    const EdgeInsets.all(13),
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.025),
                  borderRadius:
                      BorderRadius.circular(
                    15,
                  ),
                  border: Border.all(
                    color: Colors.white
                        .withOpacity(0.04),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Preparation',
                          style:
                              GoogleFonts.inter(
                            color: Colors.white
                                .withOpacity(
                              0.50,
                            ),
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${(progress * 100).round()}%',
                          style:
                              GoogleFonts.inter(
                            color: progress >= 1
                                ? _green
                                : _violet,
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
                          BorderRadius.circular(
                        10,
                      ),
                      child:
                          LinearProgressIndicator(
                        value:
                            progress.clamp(
                          0.0,
                          1.0,
                        ),
                        minHeight: 6,
                        backgroundColor:
                            Colors.white
                                .withOpacity(
                          0.055,
                        ),
                        valueColor:
                            AlwaysStoppedAnimation(
                          progress >= 1
                              ? _green
                              : _violet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 11),

              // Exam information
              Row(
                children: [
                  Expanded(
                    child: _infoItem(
                      Icons.menu_book_rounded,
                      '$selectedChapters',
                      'Chapters',
                      _violet,
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.topic_rounded,
                      '$topicCount',
                      'Topics',
                      _gold,
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.flag_rounded,
                      '${exam.targetPercentage.round()}%',
                      'Target',
                      _green,
                    ),
                  ),
                  Expanded(
                    child: _infoItem(
                      Icons.score_rounded,
                      '${exam.totalMarks}',
                      'Marks',
                      _blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color.withOpacity(0.85),
          size: 15,
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            color:
                Colors.white.withOpacity(0.28),
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE BOX
  // ============================================================

  Widget _buildDateBox(
    DateTime date,
    Color accent,
  ) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return Container(
      width: 58,
      height: 68,
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(16),
        gradient:
            LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.14),
            accent.withOpacity(0.035),
          ],
        ),
        border: Border.all(
          color:
              accent.withOpacity(0.17),
        ),
      ),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Text(
            months[date.month - 1],
            style: GoogleFonts.inter(
              color: accent,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${date.day}',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${date.year}',
            style: GoogleFonts.inter(
              color:
                  Colors.white.withOpacity(0.30),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _buildStatusChip(
    int daysLeft,
    Color statusColor,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration:
          BoxDecoration(
        color:
            statusColor.withOpacity(0.075),
        borderRadius:
            BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(daysLeft),
            color: statusColor,
            size: 11,
          ),
          const SizedBox(width: 4),
          Text(
            _daysLabel(daysLeft),
            style: GoogleFonts.inter(
              color: statusColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 28,
          vertical: 40,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final value =
                Curves.easeOutCubic.transform(
              _controller.value,
            );

            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(
                  0,
                  22 * (1 - value),
                ),
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 105,
                height: 105,
                decoration:
                    BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      LinearGradient(
                    colors: [
                      _violet.withOpacity(0.16),
                      _indigo.withOpacity(0.055),
                    ],
                  ),
                  border: Border.all(
                    color:
                        _violet.withOpacity(0.14),
                  ),
                ),
                child: const Icon(
                  Icons.event_note_rounded,
                  color: _violet,
                  size: 44,
                ),
              ),
              const SizedBox(height: 25),
              Text(
                'No exams yet',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'Create your first exam and start\n'
                'planning your preparation.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color:
                      Colors.white.withOpacity(0.40),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              _gradientButton(
                icon: Icons.add_rounded,
                label: 'Create exam',
                onTap: _openCreateExam,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FAB
  // ============================================================

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value =
            Curves.easeOutBack.transform(
          _controller.value,
        );

        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child:
          FloatingActionButton.extended(
        onPressed: _openCreateExam,
        elevation: 8,
        backgroundColor: _violet,
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.add_rounded,
          size: 21,
        ),
        label: Text(
          'Add exam',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUTTON
  // ============================================================

  Widget _gradientButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Ink(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 13,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(16),
            gradient:
                const LinearGradient(
              colors: [
                _violet,
                _indigo,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    _violet.withOpacity(0.24),
                blurRadius: 18,
                offset:
                    const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ANIMATION
  // ============================================================

  Widget _animatedItem({
    required int index,
    required Widget child,
  }) {
    final start =
        (index * 0.065).clamp(0.0, 0.70);

    final end =
        (start + 0.30).clamp(0.0, 1.0);

    final animation =
        CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    required bool success,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor: _card2,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
          content: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: success
                    ? _green
                    : _red,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style:
                      GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

