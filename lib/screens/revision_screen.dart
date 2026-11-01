import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/chapter_model.dart';
import '../providers/syllabus_provider.dart';
import '../theme/app_colors.dart';

class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key});

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SyllabusProvider>(
      builder: (context, provider, _) {
        final dueChapters = List<ChapterModel>.from(
          provider.getChaptersForRevision(),
        );

        // IMPORTANT:
        // Always show the chapter with the earliest actual
        // nextRevisionAt first. No random ordering.
        dueChapters.sort((a, b) {
          final aDate = a.nextRevisionAt;
          final bDate = b.nextRevisionAt;

          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return 1;
          if (bDate == null) return -1;

          return aDate.compareTo(bDate);
        });

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              _buildBackgroundGlow(),

              SafeArea(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.card,
                  onRefresh: () async {
                    setState(() {});
                    await Future<void>.delayed(
                      const Duration(milliseconds: 250),
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth >= 1100
                          ? 1000.0
                          : constraints.maxWidth >= 700
                              ? 760.0
                              : double.infinity;

                      return Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxWidth,
                          ),
                          child: ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              constraints.maxWidth < 600 ? 18 : 28,
                              24,
                              constraints.maxWidth < 600 ? 18 : 28,
                              120,
                            ),
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 24),
                              _buildHeroCard(dueChapters.length),
                              const SizedBox(height: 20),
                              _buildRevisionInfoCard(),
                              const SizedBox(height: 28),
                              _buildSectionHeader(dueChapters.length),
                              const SizedBox(height: 14),
                              if (dueChapters.isEmpty)
                                _buildEmptyState()
                              else
                                ...List.generate(
                                  dueChapters.length,
                                  (index) => _buildAnimatedRevisionCard(
                                    provider,
                                    dueChapters[index],
                                    index,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // BACKGROUND
  // ============================================================

  Widget _buildBackgroundGlow() {
    return Stack(
      children: [
        Positioned(
          top: -150,
          right: -120,
          child: IgnorePointer(
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -180,
          left: -130,
          child: IgnorePointer(
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.0,
          0.35,
          curve: Curves.easeOut,
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(
              0.0,
              0.35,
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(17),
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.28),
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_edu_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revision',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Keep what you learned fresh.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHeroCard(int dueCount) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.15,
          0.55,
          curve: Curves.easeOut,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withOpacity(0.18),
              AppColors.card.withOpacity(0.96),
            ],
          ),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.background.withOpacity(0.55),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.25),
                ),
              ),
              child: Center(
                child: Text(
                  '$dueCount',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 17),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dueCount == 0
                        ? 'You are all caught up'
                        : '$dueCount revision${dueCount == 1 ? '' : 's'} due',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dueCount == 0
                        ? 'No chapter revision is due right now.'
                        : 'These are the chapters whose scheduled revision date has arrived.',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REVISION INFO
  // ============================================================

  Widget _buildRevisionInfoCard() {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: const Interval(
          0.25,
          0.65,
          curve: Curves.easeOut,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground.withOpacity(0.82),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: AppColors.accent.withOpacity(0.10),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.accent,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 11),
                Text(
                  'Revision cycle',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildCycleStep(
                    number: '1',
                    title: 'First',
                    subtitle: '7 days',
                  ),
                ),
                _buildCycleLine(),
                Expanded(
                  child: _buildCycleStep(
                    number: '2',
                    title: 'Second',
                    subtitle: '21 days',
                  ),
                ),
                _buildCycleLine(),
                Expanded(
                  child: _buildCycleStep(
                    number: '∞',
                    title: 'Repeat',
                    subtitle: 'Every 21 days',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleStep({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.28),
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 8.5,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCycleLine() {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.only(
          left: 6,
          right: 6,
          bottom: 42,
        ),
        color: AppColors.cardBorder,
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(int count) {
    return Row(
      children: [
        Text(
          count == 0 ? 'Revision queue' : 'Due now',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        if (count > 0)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.danger.withOpacity(0.20),
              ),
            ),
            child: Text(
              '$count due',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.danger,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // REVISION CARD
  // ============================================================

  Widget _buildAnimatedRevisionCard(
    SyllabusProvider provider,
    ChapterModel chapter,
    int index,
  ) {
    final start =
        (0.32 + (index * 0.08)).clamp(0.0, 0.75).toDouble();
    final end =
        (start + 0.25).clamp(0.25, 1.0).toDouble();

    final animation = CurvedAnimation(
      parent: _animationController,
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
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: _buildRevisionCard(
          provider,
          chapter,
        ),
      ),
    );
  }

  Widget _buildRevisionCard(
    SyllabusProvider provider,
    ChapterModel chapter,
  ) {
    final nextRevision = chapter.nextRevisionAt;
    final lastRevision = chapter.lastRevisionAt;

    final subjectName =
        provider.getSubjectNameForChapter(chapter.id) ??
            'Syllabus';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.90),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.18),
                        AppColors.accent.withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.20),
                    ),
                  ),
                  child: const Icon(
                    Icons.replay_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildDueBadge(),
              ],
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateInfo(
                      icon: Icons.event_available_rounded,
                      title: 'Due',
                      value: _formatDate(nextRevision),
                      valueColor: AppColors.danger,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 34,
                    color: AppColors.cardBorder,
                  ),
                  Expanded(
                    child: _buildDateInfo(
                      icon: Icons.history_rounded,
                      title: 'Last revision',
                      value: _formatDate(lastRevision),
                      valueColor: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    _markRevisionDone(
                      provider,
                      chapter,
                    );
                  },
                  splashColor:
                      AppColors.primary.withOpacity(0.12),
                  highlightColor:
                      AppColors.primary.withOpacity(0.05),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.primary.withOpacity(0.20),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mark Revision Done',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AppColors.danger.withOpacity(0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.danger,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            'DUE',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: AppColors.danger,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateInfo({
    required IconData icon,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: valueColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                ),
              ],
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 42,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withOpacity(0.75),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withOpacity(0.10),
              border: Border.all(
                color: AppColors.success.withOpacity(0.18),
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 35,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Nothing to revise',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Complete a chapter and it will enter the revision cycle after 7 days.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MARK REVISION DONE
  // ============================================================

  Future<void> _markRevisionDone(
    SyllabusProvider provider,
    ChapterModel chapter,
  ) async {
    final subjectId = _findSubjectId(
      provider,
      chapter.id,
    );

    if (subjectId.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.card2,
          content: Text(
            'Could not find the subject for this chapter.',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );

      return;
    }

    await provider.markChapterRevisionDone(
      subjectId: subjectId,
      chapterId: chapter.id,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.card2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Revision completed. Next revision in 21 days.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

    setState(() {});
  }

  // ============================================================
  // FIND SUBJECT
  // ============================================================

  String _findSubjectId(
    SyllabusProvider provider,
    String chapterId,
  ) {
    for (final subject in provider.subjects) {
      for (final chapter in subject.chapters) {
        if (chapter.id == chapterId) {
          return subject.id;
        }
      }
    }

    return '';
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Not scheduled';
    }

    final local = date.toLocal();

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

    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }
}