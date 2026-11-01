import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../theme/app_colors.dart';

class HabitDetailScreen extends StatefulWidget {
  final String habitId;

  const HabitDetailScreen({
    super.key,
    required this.habitId,
  });

  @override
  State<HabitDetailScreen> createState() =>
      _HabitDetailScreenState();
}

class _HabitDetailScreenState extends State<HabitDetailScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  DateTime _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HabitProvider>(
      builder: (context, provider, _) {
        final habit = provider.getHabitById(widget.habitId);

        if (habit == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              title: const Text('Habit'),
            ),
            body: Center(
              child: Text(
                'Habit not found.',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildAppBar(
                    context,
                    provider,
                    habit,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildHeroCard(habit),
                ),
                SliverToBoxAdapter(
                  child: _buildStatistics(habit),
                ),
                SliverToBoxAdapter(
                  child: _buildScheduleCard(habit),
                ),
                SliverToBoxAdapter(
                  child: _buildCalendar(
                    provider,
                    habit,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildPerformanceCard(habit),
                ),
                SliverToBoxAdapter(
                  child: _buildActions(
                    context,
                    provider,
                    habit,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
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
    BuildContext context,
    HabitProvider provider,
    HabitModel habit,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        8,
      ),
      child: Row(
        children: [
          _topButton(
            icon: Icons.arrow_back_rounded,
            onTap: () {
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              habit.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _topButton(
            icon: Icons.more_horiz_rounded,
            onTap: () {
              _showMoreMenu(
                context,
                provider,
                habit,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _topButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHeroCard(HabitModel habit) {
    final color = Color(habit.colorValue);

    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            12,
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.22),
                  AppColors.card,
                  AppColors.background,
                ],
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: color.withOpacity(0.32),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 30,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                      color: color.withOpacity(0.30),
                    ),
                  ),
                  child: Icon(
                    _iconFromName(habit.icon),
                    color: color,
                    size: 31,
                  ),
                ),
                const SizedBox(width: 17),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      if (habit.description.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          habit.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 9),
                      Row(
                        children: [
                          Icon(
                            habit.isActive
                                ? Icons.play_circle_outline_rounded
                                : Icons.pause_circle_outline_rounded,
                            size: 14,
                            color: habit.isActive
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            habit.isActive
                                ? 'Active'
                                : 'Paused',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: habit.isActive
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  Widget _buildStatistics(HabitModel habit) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _metricCard(
              Icons.local_fire_department_rounded,
              '${habit.currentStreak}',
              'Current streak',
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metricCard(
              Icons.workspace_premium_rounded,
              '${habit.longestStreak}',
              'Best streak',
              AppColors.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metricCard(
              Icons.check_circle_outline_rounded,
              '${habit.completedCount}',
              'Completed',
              AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    IconData icon,
    String value,
    String label,
    Color accent,
  ) {
    return _glassContainer(
      padding: const EdgeInsets.fromLTRB(
        12,
        14,
        12,
        13,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: accent,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
  // SCHEDULE
  // ============================================================

  Widget _buildScheduleCard(HabitModel habit) {
    final days = habit.weekdays.isEmpty
        ? const [1, 2, 3, 4, 5, 6, 7]
        : habit.weekdays;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        12,
      ),
      child: _glassContainer(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              habit.weekdays.isEmpty
                  ? 'Every day'
                  : '${days.length} days per week',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: List.generate(
                7,
                (index) {
                  final day = index + 1;
                  final selected =
                      days.contains(day);

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == 6 ? 0 : 6,
                      ),
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary
                                  .withOpacity(0.18)
                              : AppColors.surfaceLight,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                    .withOpacity(0.45)
                                : AppColors.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _shortDay(day),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight:
                                  FontWeight.w700,
                              color: selected
                                  ? AppColors.accent
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CALENDAR
  // ============================================================

  Widget _buildCalendar(
    HabitProvider provider,
    HabitModel habit,
  ) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;

    final firstDay = DateTime(
      year,
      month,
      1,
    );

    final daysInMonth = DateTime(
      year,
      month + 1,
      0,
    ).day;

    final leadingDays = firstDay.weekday - 1;

    final totalCells =
        ((leadingDays + daysInMonth) / 7).ceil() * 7;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        12,
      ),
      child: _glassContainer(
        padding: const EdgeInsets.fromLTRB(
          16,
          18,
          16,
          18,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'History',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                _monthButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: () {
                    setState(() {
                      _selectedMonth = DateTime(
                        year,
                        month - 1,
                      );
                    });
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  _monthName(month),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                _monthButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () {
                    final next = DateTime(
                      year,
                      month + 1,
                    );

                    setState(() {
                      _selectedMonth = next;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                'M',
                'T',
                'W',
                'T',
                'F',
                'S',
                'S',
              ]
                  .map(
                    (day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 7,
                crossAxisSpacing: 7,
              ),
              itemBuilder: (context, index) {
                if (index < leadingDays ||
                    index >=
                        leadingDays + daysInMonth) {
                  return const SizedBox();
                }

                final dayNumber =
                    index - leadingDays + 1;

                final date = DateTime(
                  year,
                  month,
                  dayNumber,
                );

                final completed =
    habit.isCompletedOn(date);

final scheduled =
    habit.isScheduledOn(date);

final today = _isSameDay(
  date,
  DateTime.now(),
);

return GestureDetector(
  onTap: () async {
    await provider.toggleHabit(
      habit.id,
      date: date,
    );
  },
  child: AnimatedContainer(
    duration: const Duration(
      milliseconds: 180,
    ),
    decoration: BoxDecoration(
      color: completed
          ? Color(habit.colorValue)
              .withOpacity(0.82)
          : scheduled
              ? AppColors.surfaceLight
              : AppColors.background,
                      borderRadius:
                          BorderRadius.circular(10),
                      border: Border.all(
                        color: today
                            ? AppColors.accent
                            : completed
                                ? Color(
                                    habit.colorValue,
                                  ).withOpacity(0.45)
                                : AppColors.cardBorder,
                        width: today ? 1.5 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$dayNumber',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight:
                              FontWeight.w700,
                          color: completed
                              ? Colors.white
                              : scheduled
                                  ? AppColors
                                      .textSecondary
                                  : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _legendDot(
                  Color(habit.colorValue),
                  'Completed',
                ),
                const SizedBox(width: 14),
                _legendDot(
                  AppColors.surfaceLight,
                  'Scheduled',
                ),
                const SizedBox(width: 14),
                _legendDot(
                  AppColors.background,
                  'Not scheduled',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _legendDot(
    Color color,
    String label,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================

  Widget _buildPerformanceCard(HabitModel habit) {
    final weekly =
        habit.weeklyCompletionRate.clamp(0.0, 1.0);

    final monthly =
        habit.monthlyCompletionRate.clamp(0.0, 1.0);

    final overall =
        habit.overallCompletionRate.clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        12,
      ),
      child: _glassContainer(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Performance',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _performanceRow(
              'Last 7 days',
              weekly,
            ),
            const SizedBox(height: 14),
            _performanceRow(
              'This month',
              monthly,
            ),
            const SizedBox(height: 14),
            _performanceRow(
              'Overall',
              overall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _performanceRow(
    String title,
    double progress,
  ) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor:
                AppColors.surfaceLight,
            valueColor:
                const AlwaysStoppedAnimation(
              AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions(
    BuildContext context,
    HabitProvider provider,
    HabitModel habit,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        0,
      ),
      child: Column(
        children: [
          _actionButton(
            icon: habit.isActive
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            title: habit.isActive
                ? 'Pause habit'
                : 'Resume habit',
            subtitle: habit.isActive
                ? 'Temporarily hide this habit from your routine.'
                : 'Start showing this habit again.',
            color: AppColors.warning,
            onTap: () {
              provider.toggleHabitActive(
                habit.id,
              );
            },
          ),
          const SizedBox(height: 10),
          _actionButton(
            icon: Icons.delete_outline_rounded,
            title: 'Delete habit',
            subtitle:
                'Remove this habit and its completion history.',
            color: AppColors.danger,
            onTap: () async {
              final confirmed =
                  await _confirmDelete(
                context,
                habit,
              );

              if (!confirmed) return;

              await provider.deleteHabit(
                habit.id,
              );

              if (!mounted) return;

              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
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
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MORE MENU
  // ============================================================

  void _showMoreMenu(
    BuildContext context,
    HabitProvider provider,
    HabitModel habit,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            15,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                _menuItem(
                  Icons.pause_circle_outline_rounded,
                  habit.isActive
                      ? 'Pause habit'
                      : 'Resume habit',
                  AppColors.warning,
                  () {
                    provider.toggleHabitActive(
                      habit.id,
                    );
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),
                _menuItem(
                  Icons.delete_outline_rounded,
                  'Delete habit',
                  AppColors.danger,
                  () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    final confirmed =
                        await _confirmDelete(
                      context,
                      habit,
                    );

                    if (!confirmed) return;

                    await provider.deleteHabit(
                      habit.id,
                    );

                    if (!mounted) return;

                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        vertical: 2,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius:
              BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: color,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      onTap: onTap,
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<bool> _confirmDelete(
    BuildContext context,
    HabitModel habit,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Delete habit?',
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          content: Text(
            'Delete "${habit.name}" and its completion history?',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // GLASS
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color:
                AppColors.card.withOpacity(0.82),
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.glassBorder,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _isSameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _shortDay(int day) {
    const names = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    return names[day - 1];
  }

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return names[month - 1];
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'book':
        return Icons.menu_book_rounded;

      case 'fitness':
        return Icons.fitness_center_rounded;

      case 'water':
        return Icons.water_drop_rounded;

      case 'sleep':
        return Icons.bedtime_rounded;

      case 'study':
        return Icons.school_rounded;

      case 'code':
        return Icons.code_rounded;

      case 'music':
        return Icons.music_note_rounded;

      case 'favorite':
        return Icons.favorite_rounded;

      case 'star':
        return Icons.star_rounded;

      case 'check_circle':
      default:
        return Icons.check_circle_rounded;
    }
  }
}