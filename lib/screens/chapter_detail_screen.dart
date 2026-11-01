import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/chapter_model.dart';
import '../providers/syllabus_provider.dart';
import '../theme/app_colors.dart';

class ChapterDetailScreen extends StatefulWidget {
  final String subjectId;
  final String chapterId;

  const ChapterDetailScreen({
    super.key,
    required this.subjectId,
    required this.chapterId,
  });

  @override
  State<ChapterDetailScreen> createState() =>
      _ChapterDetailScreenState();
}

class _ChapterDetailScreenState
    extends State<ChapterDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';

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

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Not available';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${_formatDate(date)} • $hour:$minute $period';
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;

    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _revisionText(ChapterModel chapter) {
    final next = chapter.nextRevisionAt;

    if (next == null) {
      return 'No revision scheduled';
    }

    if (chapter.isRevisionDue) {
      return 'Revision is due now';
    }

    final days = chapter.daysUntilRevision;

    if (days == null) {
      return _formatDate(next);
    }

    if (days == 0) {
      return 'Due today';
    }

    if (days == 1) {
      return 'Due tomorrow';
    }

    return 'Due in $days days';
  }

  IconData _stepIcon(String title) {
    final value = title.toLowerCase();

    if (value.contains('learn')) {
      return Icons.school_rounded;
    }

    if (value.contains('note')) {
      return Icons.edit_note_rounded;
    }

    if (value.contains('dpp')) {
      return Icons.assignment_rounded;
    }

    if (value.contains('practice') ||
        value.contains('question')) {
      return Icons.quiz_rounded;
    }

    if (value.contains('test')) {
      return Icons.fact_check_rounded;
    }

    if (value.contains('revision') ||
        value.contains('revise')) {
      return Icons.history_edu_rounded;
    }

    if (value.contains('understand')) {
      return Icons.psychology_rounded;
    }

    return Icons.check_circle_outline_rounded;
  }

  Color _stepColor(String title) {
    final value = title.toLowerCase();

    if (value.contains('revision') ||
        value.contains('revise')) {
      return AppColors.accent;
    }

    if (value.contains('test')) {
      return AppColors.warning;
    }

    if (value.contains('practice') ||
        value.contains('question') ||
        value.contains('dpp')) {
      return AppColors.info;
    }

    return AppColors.primary;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<SyllabusProvider>(
      builder: (context, provider, _) {
        final chapter = provider.findChapterById(
          subjectId: widget.subjectId,
          chapterId: widget.chapterId,
        );

        if (chapter == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              foregroundColor: AppColors.textPrimary,
              title: Text(
                'Chapter',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: Center(
              child: Text(
                'Chapter not found',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        final subjectName =
            provider.getSubjectNameForChapter(
                  chapter.id,
                ) ??
                'Subject';

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(subjectName, chapter),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    8,
                    18,
                    36,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        _animated(
                          0,
                          _buildHeroCard(chapter),
                        ),
                        const SizedBox(height: 18),

                        _animated(
                          1,
                          _buildLearningProgress(chapter),
                        ),
                        const SizedBox(height: 18),

                        _animated(
                          2,
                          _buildStudyChecklist(
                            provider,
                            chapter,
                          ),
                        ),
                        const SizedBox(height: 18),

                        _animated(
                          3,
                          _buildCompletionCard(chapter),
                        ),
                        const SizedBox(height: 18),

                        _animated(
                          4,
                          _buildRevisionCard(
                            provider,
                            chapter,
                          ),
                        ),
                        const SizedBox(height: 18),

                        _animated(
                          5,
                          _buildStatistics(chapter),
                        ),
                        const SizedBox(height: 18),

                        _animated(
                          6,
                          _buildRevisionTimeline(chapter),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar(
    String subjectName,
    ChapterModel chapter,
  ) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      pinned: true,
      expandedHeight: 88,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
        ),
      ),
      title: Text(
        'Chapter Details',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(
            60,
            58,
            18,
            8,
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              '$subjectName • ${chapter.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHeroCard(ChapterModel chapter) {
    final progress =
        (chapter.studyProgress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.28),
            AppColors.card,
            AppColors.card2,
          ],
        ),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 28,
            spreadRadius: 1,
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(16),
                  gradient:
                      AppColors.primaryGradient,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  chapter.name,
                  style: GoogleFonts.inter(
                   fontSize: 20,
fontWeight: FontWeight.w800,
height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                '$progress%',
                style: GoogleFonts.inter(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'study progress',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: chapter.isStudyCompleted
                      ? AppColors.success.withOpacity(
                          0.12,
                        )
                      : AppColors.surfaceLight,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Text(
                  chapter.isStudyCompleted
                      ? 'COMPLETED'
                      : 'IN PROGRESS',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color:
                        chapter.isStudyCompleted
                            ? AppColors.success
                            : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEARNING PROGRESS
  // ============================================================

  Widget _buildLearningProgress(
    ChapterModel chapter,
  ) {
    final studySteps = chapter.studySteps;
    final completed = studySteps
        .where((step) => step.completed)
        .length;

    final total = studySteps.length;

    final progress = total == 0
        ? 0.0
        : completed / total;

    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.auto_graph_rounded,
            'Learning Progress',
            'Only study steps count toward completion',
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius:
                BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor:
                  AppColors.surfaceLight,
              valueColor:
                  const AlwaysStoppedAnimation(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$completed of $total steps completed',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHECKLIST
  // ============================================================

  Widget _buildStudyChecklist(
    SyllabusProvider provider,
    ChapterModel chapter,
  ) {
    final studySteps = chapter.studySteps;

    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.checklist_rounded,
            'Study Checklist',
            'Complete every learning step',
          ),
          const SizedBox(height: 12),

          if (studySteps.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Text(
                'No learning steps added yet.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),

          ...studySteps.asMap().entries.map(
            (entry) {
              final index = entry.key;
              final step = entry.value;

              return _buildStepTile(
                provider,
                chapter,
                step,
                index,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(
    SyllabusProvider provider,
    ChapterModel chapter,
    ChapterStep step,
    int index,
  ) {
    final color = _stepColor(step.title);

    return Padding(
      padding:
          const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(16),
          onTap: () {
            provider.toggleStep(
              subjectId: widget.subjectId,
              chapterId: chapter.id,
              stepId: step.id,
              completed: !step.completed,
            );
          },
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: step.completed
                  ? color.withOpacity(0.09)
                  : AppColors.surfaceLight
                      .withOpacity(0.62),
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: step.completed
                    ? color.withOpacity(0.35)
                    : AppColors.glassBorder,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 220,
                  ),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: step.completed
                        ? color.withOpacity(0.16)
                        : AppColors.card,
                    borderRadius:
                        BorderRadius.circular(13),
                  ),
                  child: Icon(
                    _stepIcon(step.title),
                    color: step.completed
                        ? color
                        : AppColors.textSecondary,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.completed
                            ? 'Completed ${_formatDateTime(step.completedAt)}'
                            : 'Tap to mark complete',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color:
                              AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedContainer(
                  duration: const Duration(
                    milliseconds: 220,
                  ),
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.completed
                        ? color
                        : Colors.transparent,
                    border: Border.all(
                      width: 2,
                      color: step.completed
                          ? color
                          : AppColors.textMuted,
                    ),
                  ),
                  child: step.completed
                      ? const Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMPLETION CARD
  // ============================================================

  Widget _buildCompletionCard(
    ChapterModel chapter,
  ) {
    final completed = chapter.isStudyCompleted;

    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.verified_rounded,
            'Chapter Completion',
            completed
                ? 'Learning phase completed'
                : 'Finish all learning steps',
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: completed
                  ? AppColors.success.withOpacity(
                      0.08,
                    )
                  : AppColors.surfaceLight,
              borderRadius:
                  BorderRadius.circular(16),
              border: Border.all(
                color: completed
                    ? AppColors.success.withOpacity(
                        0.28,
                      )
                    : AppColors.glassBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: completed
                      ? AppColors.success
                      : AppColors.warning,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        completed
                            ? 'Completed'
                            : 'Not completed yet',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        completed
                            ? _formatDateTime(
                                chapter.studiedAt,
                              )
                            : 'Complete the remaining study steps.',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ],
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
  // REVISION CARD
  // ============================================================

  Widget _buildRevisionCard(
    SyllabusProvider provider,
    ChapterModel chapter,
  ) {
    final hasSchedule =
        chapter.nextRevisionAt != null;

    final due = chapter.isRevisionDue;

    final accent = due
        ? AppColors.warning
        : AppColors.accent;

    return _sectionCard(
      borderColor: due
          ? AppColors.warning.withOpacity(0.35)
          : null,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.history_edu_rounded,
            'Revision',
            '7 days first • 21 days after every revision',
          ),
          const SizedBox(height: 16),

          if (!hasSchedule)
            _revisionEmptyState(chapter)
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withOpacity(0.13),
                    AppColors.surfaceLight,
                  ],
                ),
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: accent.withOpacity(0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration:
                            BoxDecoration(
                          color:
                              accent.withOpacity(
                            0.15,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                        ),
                        child: Icon(
                          due
                              ? Icons.notifications_active_rounded
                              : Icons.event_available_rounded,
                          color: accent,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          due
                              ? 'Revision Due'
                              : 'Next Revision',
                          style:
                              GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        due
                            ? 'NOW'
                            : _revisionText(chapter),
                        style:
                            GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(
                    'Next revision',
                    _formatDateTime(
                      chapter.nextRevisionAt,
                    ),
                  ),
                  if (chapter.lastRevisionAt !=
                      null)
                    _infoRow(
                      'Last revision',
                      _formatDateTime(
                        chapter.lastRevisionAt,
                      ),
                    ),
                  if (chapter.studiedAt != null)
                    _infoRow(
                      'Chapter completed',
                      _formatDateTime(
                        chapter.studiedAt,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            if (due)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await provider
                        .markChapterRevisionDone(
                      subjectId:
                          widget.subjectId,
                      chapterId:
                          chapter.id,
                    );
                  },
                  icon: const Icon(
                    Icons.check_rounded,
                  ),
                  label: Text(
                    'Mark Revision Done',
                    style: GoogleFonts.inter(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius:
                      BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.glassBorder,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.accent,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Keep studying. Your next revision will appear automatically when it is due.',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color:
                              AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _revisionEmptyState(
    ChapterModel chapter,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_clock_rounded,
            color: AppColors.textMuted,
            size: 25,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              chapter.isStudyCompleted
                  ? 'Revision will be scheduled automatically.'
                  : 'Complete every learning step first. Then your first revision will be scheduled 7 days later.',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(
    ChapterModel chapter,
  ) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.insights_rounded,
            'Chapter Statistics',
            'Your current chapter status',
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  Icons.timer_outlined,
                  '${chapter.estimatedMinutes}m',
                  'Estimated',
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  Icons.school_rounded,
                  '${chapter.studySteps.length}',
                  'Study steps',
                  AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  Icons.history_edu_rounded,
                  chapter.hasRevisionHistory
                      ? 'Yes'
                      : 'No',
                  'Revised',
                  AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  Icons.event_rounded,
                  chapter.nextRevisionAt ==
                          null
                      ? '--'
                      : _formatDate(
                          chapter.nextRevisionAt,
                        ),
                  'Next revision',
                  AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight
            .withOpacity(0.65),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: color,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REVISION TIMELINE
  // ============================================================

  Widget _buildRevisionTimeline(
    ChapterModel chapter,
  ) {
    return _sectionCard(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            Icons.timeline_rounded,
            'Study Timeline',
            'Chapter completion and revision schedule',
          ),
          const SizedBox(height: 18),

          _timelineItem(
            icon: Icons.menu_book_rounded,
            title: 'Chapter created',
            date: chapter.createdAt,
            color: AppColors.textMuted,
            isLast: chapter.studiedAt == null,
          ),

          if (chapter.studiedAt != null)
            _timelineItem(
              icon: Icons.check_circle_rounded,
              title: 'Chapter completed',
              date: chapter.studiedAt!,
              color: AppColors.success,
              isLast:
                  chapter.lastRevisionAt == null &&
                  chapter.nextRevisionAt == null,
            ),

          if (chapter.nextRevisionAt != null &&
              chapter.lastRevisionAt == null)
            _timelineItem(
              icon: Icons.event_available_rounded,
              title: 'First revision scheduled',
              date: chapter.nextRevisionAt!,
              color: AppColors.accent,
              isLast: true,
            ),

          if (chapter.lastRevisionAt != null)
            _timelineItem(
              icon: Icons.history_edu_rounded,
              title: 'Latest revision completed',
              date: chapter.lastRevisionAt!,
              color: AppColors.primary,
              isLast: chapter.nextRevisionAt == null,
            ),

          if (chapter.lastRevisionAt != null &&
              chapter.nextRevisionAt != null)
            _timelineItem(
              icon: Icons.update_rounded,
              title: chapter.isRevisionDue
                  ? 'Next revision is due'
                  : 'Next revision scheduled',
              date: chapter.nextRevisionAt!,
              color: chapter.isRevisionDue
                  ? AppColors.warning
                  : AppColors.accent,
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _timelineItem({
    required IconData icon,
    required String title,
    required DateTime date,
    required Color color,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.13),
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: color,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      margin:
                          const EdgeInsets.symmetric(
                        vertical: 4,
                      ),
                      color:
                          AppColors.glassBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formatDateTime(date),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color:
                          AppColors.textMuted,
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

  // ============================================================
  // SECTION UI
  // ============================================================

  Widget _sectionCard({
    required Widget child,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.82),
        borderRadius:
            BorderRadius.circular(21),
        border: Border.all(
          color:
              borderColor ?? AppColors.glassBorder,
        ),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color:
                AppColors.primary.withOpacity(0.11),
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(
    String label,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 9),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANIMATION
  // ============================================================

  Widget _animated(
    int index,
    Widget child,
  ) {
    final start =
        (index * 0.08).clamp(0.0, 0.65);

    final end =
        (start + 0.35).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(
              0,
              18 * (1 - animation.value),
            ),
            child: child,
          ),
        );
      },
    );
  }
}