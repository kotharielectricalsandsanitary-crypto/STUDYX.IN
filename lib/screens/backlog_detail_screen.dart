import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/backlog_model.dart';
import '../providers/backlog_provider.dart';
import '../theme/app_colors.dart';

class BacklogDetailScreen extends StatelessWidget {
  final String backlogId;

  const BacklogDetailScreen({
    super.key,
    required this.backlogId,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BacklogProvider>(
      builder: (context, provider, child) {
        final item = provider.findById(backlogId);

        if (item == null) {
          return _buildNotFound(context);
        }

        final progress = item.progress.clamp(0.0, 1.0);
        final isCompleted = item.isCompleted;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
              ),
            ),
            title: Text(
              item.topic,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth >= 1000
                        ? 34.0
                        : constraints.maxWidth >= 600
                            ? 26.0
                            : 18.0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    8,
                    horizontalPadding,
                    45,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 1100,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          _buildHeroProgressCard(
                            item,
                            progress,
                            isCompleted,
                          ),

                          const SizedBox(height: 18),

                          _buildTodayCard(provider),

                          const SizedBox(height: 28),

                          _buildLectureHeader(item),

                          const SizedBox(height: 13),

                          ...List.generate(
                            item.lectures.length,
                            (index) {
                              final lecture =
                                  item.lectures[index];

                              return _AnimatedLectureTile(
                                key: ValueKey(
                                  '${item.id}_${lecture.number}',
                                ),
                                index: index,
                                child: _buildLectureTile(
                                  context,
                                  item,
                                  lecture,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // NOT FOUND
  // ============================================================

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.danger.withOpacity(0.14),
                  ),
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: AppColors.danger,
                  size: 40,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'Backlog not found',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This backlog item may have been deleted.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 22),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO PROGRESS CARD
  // ============================================================

  Widget _buildHeroProgressCard(
    BacklogItem item,
    double progress,
    bool isCompleted,
  ) {
    final accent =
        isCompleted ? AppColors.success : AppColors.primary;

    final remainingHours = item.remainingMinutes ~/ 60;
    final remainingMinutes = item.remainingMinutes % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.13),
            AppColors.cardBackground.withOpacity(0.94),
            AppColors.background,
          ],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: accent.withOpacity(0.16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withOpacity(0.12),
                  ),
                ),
                child: Icon(
                  isCompleted
                      ? Icons.verified_rounded
                      : Icons.play_circle_outline_rounded,
                  color: accent,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted
                          ? 'Backlog Completed'
                          : 'Backlog Progress',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.totalLectures} lectures • ${item.minutesPerLecture} min each',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: progress,
                ),
                duration:
                    const Duration(milliseconds: 850),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    '${(value * 100).round()}%',
                    style: GoogleFonts.inter(
                      color: accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: progress,
            ),
            duration:
                const Duration(milliseconds: 950),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  backgroundColor:
                      Colors.white.withOpacity(0.055),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    accent,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 17),

          Row(
            children: [
              Expanded(
                child: _metric(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Completed',
                  value:
                      '${item.completedLectures}',
                  color: AppColors.success,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _metric(
                  icon: Icons.pending_actions_rounded,
                  title: 'Remaining',
                  value:
                      '${item.remainingLectures}',
                  color: AppColors.warning,
                ),
              ),
              _verticalDivider(),
              Expanded(
                child: _metric(
                  icon: Icons.schedule_rounded,
                  title: 'Time left',
                  value:
                      '${remainingHours}h ${remainingMinutes}m',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 38,
      color: AppColors.cardBorder,
    );
  }

  // ============================================================
  // TODAY CARD
  // ============================================================

  Widget _buildTodayCard(
    BacklogProvider provider,
  ) {
    final completed =
        provider.todayCompletedLectures;

    final target =
        provider.dailyTarget;

    final remaining =
        provider.todayRemainingTarget;

    final ratio = target <= 0
        ? 0.0
        : (completed / target).clamp(0.0, 1.0);

    final targetCompleted = remaining == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: targetCompleted
              ? AppColors.success.withOpacity(0.18)
              : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: targetCompleted
                      ? AppColors.success.withOpacity(0.09)
                      : AppColors.primary.withOpacity(0.09),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: Icon(
                  targetCompleted
                      ? Icons.emoji_events_rounded
                      : Icons.today_rounded,
                  color: targetCompleted
                      ? AppColors.success
                      : AppColors.primary,
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today',
                      style: GoogleFonts.inter(
                        color:
                            AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      targetCompleted
                          ? 'Daily target achieved'
                          : 'Keep moving toward your target',
                      style: GoogleFonts.inter(
                        color:
                            AppColors.textMuted,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '$completed/$target',
                style: GoogleFonts.inter(
                  color: targetCompleted
                      ? AppColors.success
                      : AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: ratio,
            ),
            duration:
                const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius:
                    BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor:
                      Colors.white.withOpacity(0.05),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    targetCompleted
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 11),

          Text(
            targetCompleted
                ? '🎯 Daily target completed!'
                : '$remaining lecture${remaining == 1 ? '' : 's'} left for today',
            style: GoogleFonts.inter(
              color: targetCompleted
                  ? AppColors.success
                  : AppColors.textMuted,
              fontSize: 10,
              fontWeight: targetCompleted
                  ? FontWeight.w800
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LECTURE HEADER
  // ============================================================

  Widget _buildLectureHeader(
    BacklogItem item,
  ) {
    final completed =
        item.completedLectures;

    final total =
        item.totalLectures;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Lectures',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete lectures to clear this backlog.',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius:
                BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Text(
            '$completed / $total',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LECTURE TILE
  // ============================================================

  Widget _buildLectureTile(
    BuildContext context,
    BacklogItem item,
    BacklogLecture lecture,
  ) {
    final completed = lecture.completed;

    final accent = completed
        ? AppColors.success
        : AppColors.primary;

    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(18),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () async {
          await context
              .read<BacklogProvider>()
              .toggleLecture(
                backlogId: item.id,
                lectureNumber: lecture.number,
                completed: !completed,
              );
        },
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 220),
          margin:
              const EdgeInsets.only(bottom: 10),
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: completed
                  ? [
                      AppColors.success
                          .withOpacity(0.075),
                      AppColors.cardBackground,
                    ]
                  : [
                      AppColors.cardBackground,
                      AppColors.background
                          .withOpacity(0.25),
                    ],
            ),
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: completed
                  ? AppColors.success
                      .withOpacity(0.18)
                  : AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              // CHECKBOX
              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 220),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: completed
                      ? AppColors.success
                      : AppColors.surfaceLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: completed
                        ? AppColors.success
                        : AppColors.textMuted
                            .withOpacity(0.40),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  completed
                      ? Icons.check_rounded
                      : Icons.play_arrow_rounded,
                  color: completed
                      ? Colors.black
                      : AppColors.textMuted,
                  size: 17,
                ),
              ),

              const SizedBox(width: 12),

              // NUMBER
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.08),
                  borderRadius:
                      BorderRadius.circular(9),
                ),
                child: Text(
                  '${lecture.number}',
                  style: GoogleFonts.inter(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(width: 11),

              // TITLE
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lecture ${lecture.number}',
                      style: GoogleFonts.inter(
                        color: completed
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                        decoration: completed
                            ? TextDecoration
                                .lineThrough
                            : null,
                        decorationColor:
                            AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 11,
                          color:
                              AppColors.textMuted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${item.minutesPerLecture} minutes',
                          style:
                              GoogleFonts.inter(
                            color: AppColors
                                .textMuted,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // STATUS
              if (completed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success
                        .withOpacity(0.07),
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: Text(
                    'DONE',
                    style: GoogleFonts.inter(
                      color:
                          AppColors.success,
                      fontSize: 7,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons
                      .radio_button_unchecked_rounded,
                  size: 17,
                  color:
                      AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ANIMATED LECTURE TILE
// ============================================================================

class _AnimatedLectureTile
    extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedLectureTile({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedLectureTile> createState() =>
      _AnimatedLectureTileState();
}

class _AnimatedLectureTileState
    extends State<_AnimatedLectureTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController
      _controller;

  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            350 + (widget.index * 35),
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      Duration(
        milliseconds: widget.index * 35,
      ),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}