import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../theme/app_colors.dart';
import 'habit_detail_screen.dart';

class HabitScreen extends StatefulWidget {
  const HabitScreen({super.key});

  @override
  State<HabitScreen> createState() => _HabitScreenState();
}

class _HabitScreenState extends State<HabitScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerController;
  late final AnimationController _listController;

  final TextEditingController _habitController = TextEditingController();
  final TextEditingController _descriptionController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final Set<int> _selectedDays = {
    1,
    2,
    3,
    4,
    5,
    6,
    7,
  };

  String _selectedIcon = 'check_circle';
  int _selectedColorValue = 0xff6366F1;

  String _filter = 'Today';
  bool _showSearch = false;
  bool _isAdding = false;
  bool _isEditing = false;

  String? _editingHabitId;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerController.forward();

    Future.delayed(
      const Duration(milliseconds: 120),
      () {
        if (mounted) {
          _listController.forward();
        }
      },
    );

    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();

    _habitController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<HabitProvider>(
          builder: (context, provider, _) {
            final visibleHabits = _getVisibleHabits(provider);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(provider),
                ),
                SliverToBoxAdapter(
                  child: _buildTodayOverview(provider),
                ),
                SliverToBoxAdapter(
                  child: _buildQuickStats(provider),
                ),
                SliverToBoxAdapter(
                  child: _buildWeekStrip(provider),
                ),
                SliverToBoxAdapter(
                  child: _buildFilterBar(),
                ),
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    _filter == 'Today'
                        ? "Today's habits"
                        : _filter == 'Active'
                            ? 'Active habits'
                            : _filter == 'Completed'
                                ? 'Completed today'
                                : 'All habits',
                    visibleHabits.length,
                  ),
                ),
                if (visibleHabits.isEmpty)
                  SliverToBoxAdapter(
                    child: _buildEmptyState(provider),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      4,
                      20,
                      10,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final habit = visibleHabits[index];

                          return _animatedItem(
                            index,
                            _buildHabitCard(
                              context,
                              provider,
                              habit,
                            ),
                          );
                        },
                        childCount: visibleHabits.length,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _buildStreakSpotlight(provider),
                ),
                SliverToBoxAdapter(
                  child: _buildConsistencySection(provider),
                ),
                SliverToBoxAdapter(
                  child: _buildPausedSection(provider),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(HabitProvider provider) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _headerController,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            4,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HABITS',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Build your routine.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 27,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          provider.todaysHabits.isEmpty
                              ? 'Create habits that move you forward.'
                              : '${provider.todaysHabits.length} habits scheduled today',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _glassIconButton(
                    icon: _showSearch
                        ? Icons.close_rounded
                        : Icons.search_rounded,
                    onTap: () {
                      setState(() {
                        _showSearch = !_showSearch;

                        if (!_showSearch) {
                          _searchController.clear();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _glassIconButton(
                    icon: Icons.add_rounded,
                    onTap: _showAddHabitSheet,
                  ),
                ],
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 260),
                crossFadeState: _showSearch
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox(
                  width: double.infinity,
                  height: 0,
                ),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _searchField(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.glassBorder,
        ),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search habits...',
          hintStyle: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _searchController.clear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TODAY OVERVIEW
  // ============================================================

  Widget _buildTodayOverview(HabitProvider provider) {
    final progress = provider.todayProgress;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        10,
      ),
      child: _glassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                _progressRing(progress),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${provider.completedTodayCount}/${provider.todaysHabits.length}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'habits completed today',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        provider.remainingTodayCount == 0 &&
                                provider.todaysHabits.isNotEmpty
                            ? 'Perfect day. Keep the streak alive.'
                            : provider.todaysHabits.isEmpty
                                ? 'No habits scheduled today.'
                                : '${provider.remainingTodayCount} still remaining',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: provider.remainingTodayCount == 0 &&
                                  provider.todaysHabits.isNotEmpty
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 7,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressRing(double progress) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(
                AppColors.accent,
              ),
            ),
          ),
          Text(
            '${(progress * 100).round()}%',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return 'Good morning';
    }

    if (hour < 17) {
      return 'Good afternoon';
    }

    return 'Good evening';
  }

  // ============================================================
  // QUICK STATS
  // ============================================================

  Widget _buildQuickStats(HabitProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        4,
        20,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: _miniMetric(
              Icons.local_fire_department_rounded,
              '${provider.longestStreak}',
              'Best streak',
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _miniMetric(
              Icons.task_alt_rounded,
              '${provider.totalCompletions}',
              'Completed',
              AppColors.success,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _miniMetric(
              Icons.track_changes_rounded,
              '${provider.activeHabitCount}',
              'Active',
              AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return _glassContainer(
      padding: const EdgeInsets.fromLTRB(
        11,
        12,
        11,
        11,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
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
  // WEEK STRIP
  // ============================================================

  Widget _buildWeekStrip(HabitProvider provider) {
    final dates = provider.getCurrentWeekDates();

    return SizedBox(
      height: 91,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];

          final isToday = _isSameDay(
            date,
            DateTime.now(),
          );

          final completed =
              provider.completedCountForDate(date);

          final scheduled =
              provider.scheduledCountForDate(date);

          final progress = scheduled == 0
              ? 0.0
              : (completed / scheduled)
                  .clamp(0.0, 1.0);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 58,
            margin: EdgeInsets.only(
              right: index == dates.length - 1
                  ? 0
                  : 9,
            ),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.card,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: isToday
                    ? AppColors.primary
                        .withOpacity(0.55)
                    : AppColors.cardBorder,
              ),
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: AppColors.primary
                            .withOpacity(0.08),
                        blurRadius: 18,
                        spreadRadius: -7,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  _dayName(date.weekday),
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? AppColors.accent
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${date.day}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isToday
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                SizedBox(
                  width: 25,
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor:
                          AppColors.surfaceLight,
                      valueColor:
                          const AlwaysStoppedAnimation(
                        AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar() {
    const filters = [
      'Today',
      'Active',
      'Completed',
      'All',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        0,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map(
            (filter) {
              final selected =
                  _filter == filter;

              return Padding(
                padding:
                    const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _filter = filter;
                    });
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                              .withOpacity(0.18)
                          : AppColors.card,
                      borderRadius:
                          BorderRadius.circular(13),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                                .withOpacity(0.55)
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      filter,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(
    String title,
    int count,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        10,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary
                  .withOpacity(0.13),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FILTERED HABITS
  // ============================================================

  List<HabitModel> _getVisibleHabits(
    HabitProvider provider,
  ) {
    List<HabitModel> habits;

    switch (_filter) {
      case 'Active':
        habits = provider.activeHabits;
        break;

      case 'Completed':
        habits = provider.todaysHabits
            .where(
              (habit) =>
                  habit.isCompletedOn(
                DateTime.now(),
              ),
            )
            .toList();
        break;

      case 'All':
        habits = provider.habits;
        break;

      case 'Today':
      default:
        habits = provider.todaysHabits;
        break;
    }

    final query =
        _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      habits = habits.where((habit) {
        return habit.name
                .toLowerCase()
                .contains(query) ||
            habit.description
                .toLowerCase()
                .contains(query);
      }).toList();
    }

    return habits;
  }

  // ============================================================
  // HABIT CARD
  // ============================================================

  Widget _buildHabitCard(
    BuildContext context,
    HabitProvider provider,
    HabitModel habit,
  ) {
    final completed =
        habit.isCompletedOn(DateTime.now());

    final color = Color(habit.colorValue);

    return Dismissible(
      key: ValueKey(
        '${habit.id}_${_filter}',
      ),
      direction:
          DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return _confirmDelete(
          context,
          habit,
        );
      },
      onDismissed: (_) {
        provider.deleteHabit(habit.id);
      },
      background: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        alignment: Alignment.centerRight,
        padding:
            const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.danger
              .withOpacity(0.13),
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.danger
                .withOpacity(0.25),
          ),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
        ),
      ),
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 260),
        curve: Curves.easeOut,
        margin:
            const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: completed
              ? color.withOpacity(0.10)
              : AppColors.card,
          borderRadius:
              BorderRadius.circular(22),
          border: Border.all(
            color: completed
                ? color.withOpacity(0.42)
                : AppColors.cardBorder,
          ),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color:
                        color.withOpacity(0.08),
                    blurRadius: 22,
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(22),
            onTap: () {
              provider.toggleHabit(habit.id);
            },
            onLongPress: () {
              _showHabitActions(
                context,
                provider,
                habit,
              );
            },
            child: Padding(
              padding:
                  const EdgeInsets.all(15),
              child: Row(
                children: [
                  _habitIcon(habit),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                habit.name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style: GoogleFonts
                                    .spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight:
                                      FontWeight.w700,
                                  color: completed
                                      ? AppColors
                                          .textSecondary
                                      : AppColors
                                          .textPrimary,
                                  decoration:
                                      completed
                                          ? TextDecoration
                                              .lineThrough
                                          : null,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            GestureDetector(
                              onTap: () {
                                _showHabitActions(
                                  context,
                                  provider,
                                  habit,
                                );
                              },
                              child: const Icon(
                                Icons
                                    .more_horiz_rounded,
                                color: AppColors
                                    .textMuted,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                        if (habit.description
                            .isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            habit.description,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                GoogleFonts.inter(
                              fontSize: 11,
                              color:
                                  AppColors.textMuted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 10,
                          runSpacing: 5,
                          children: [
                            _smallInfo(
                              Icons
                                  .local_fire_department_outlined,
                              '${habit.currentStreak} day streak',
                              color,
                            ),
                            _smallInfo(
                              Icons.done_all_rounded,
                              '${habit.completedCount} done',
                              AppColors.textMuted,
                            ),
                            _smallInfo(
                              Icons.percent_rounded,
                              '${(habit.overallCompletionRate * 100).round()}%',
                              AppColors.textMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _completionButton(
                    completed,
                    color,
                    () {
                      provider.toggleHabit(
                        habit.id,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _habitIcon(
    HabitModel habit,
  ) {
    final color =
        Color(habit.colorValue);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: color.withOpacity(0.28),
        ),
      ),
      child: Icon(
        _iconFromName(habit.icon),
        color: color,
        size: 24,
      ),
    );
  }

  Widget _completionButton(
    bool completed,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap: onTap,
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 240),
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: completed
                ? LinearGradient(
                    colors: [
                      color,
                      AppColors.primary,
                    ],
                  )
                : null,
            color: completed
                ? null
                : AppColors.surfaceLight,
            border: Border.all(
              color: completed
                  ? Colors.transparent
                  : AppColors.glassBorder,
              width: 1.2,
            ),
          ),
          child: AnimatedSwitcher(
            duration:
                const Duration(milliseconds: 180),
            child: Icon(
              completed
                  ? Icons.check_rounded
                  : Icons.circle_outlined,
              key: ValueKey(completed),
              color: completed
                  ? Colors.white
                  : AppColors.textMuted,
              size: completed ? 24 : 22,
            ),
          ),
        ),
      ),
    );
  }

  Widget _smallInfo(
    IconData icon,
    String text,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STREAK SPOTLIGHT
  // ============================================================

  Widget _buildStreakSpotlight(
    HabitProvider provider,
  ) {
    if (provider.habits.isEmpty) {
      return const SizedBox.shrink();
    }

    HabitModel best = provider.habits.first;

    for (final habit in provider.habits) {
      if (habit.currentStreak >
          best.currentStreak) {
        best = habit;
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        4,
      ),
      child: _glassContainer(
        padding:
            const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.warning
                    .withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.warning
                      .withOpacity(0.25),
                ),
              ),
              child: const Icon(
                Icons
                    .local_fire_department_rounded,
                color: AppColors.warning,
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
                    'STREAK SPOTLIGHT',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w700,
                      letterSpacing: 1.4,
                      color:
                          AppColors.warning,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    best.currentStreak == 0
                        ? 'Start your first streak'
                        : '${best.currentStreak} day streak',
                    style: GoogleFonts
                        .spaceGrotesk(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    best.currentStreak == 0
                        ? best.name
                        : '${best.name} is your strongest habit',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        GoogleFonts.inter(
                      fontSize: 11,
                      color:
                          AppColors.textMuted,
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
  // CONSISTENCY
  // ============================================================

  Widget _buildConsistencySection(
    HabitProvider provider,
  ) {
    final weekly =
        provider.getWeeklyData();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        5,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Consistency',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color:
                  AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 11),
          _glassContainer(
            padding:
                const EdgeInsets.all(17),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons
                          .calendar_month_rounded,
                      size: 19,
                      color:
                          AppColors.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Last 7 days',
                      style:
                          GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(provider.overallCompletionRate * 100).round()}% overall',
                      style:
                          GoogleFonts.inter(
                        fontSize: 10,
                        color:
                            AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 17),
                SizedBox(
                  height: 75,
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: List.generate(
                      weekly.length,
                      (index) {
                        final item =
                            weekly[index];

                        final date =
                            item['date']
                                as DateTime;

                        final completed =
                            item['completed']
                                as int;

                        final scheduled =
                            item['scheduled']
                                as int;

                        final value =
                            scheduled == 0
                                ? 0.0
                                : (completed /
                                        scheduled)
                                    .clamp(
                                      0.0,
                                      1.0,
                                    );

                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 4,
                            ),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .end,
                              children: [
                                Text(
                                  '${(value * 100).round()}',
                                  style: GoogleFonts
                                      .inter(
                                    fontSize: 8,
                                    fontWeight:
                                        FontWeight
                                            .w700,
                                    color: value >
                                            0
                                        ? AppColors
                                            .textSecondary
                                        : AppColors
                                            .textMuted,
                                  ),
                                ),
                                const SizedBox(
                                  height: 4,
                                ),
                                AnimatedContainer(
                                  duration:
                                      const Duration(
                                    milliseconds:
                                        400,
                                  ),
                                  height:
                                      38 * value +
                                          4,
                                  width: 15,
                                  decoration:
                                      BoxDecoration(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      8,
                                    ),
                                    gradient:
                                        value > 0
                                            ? AppColors
                                                .primaryGradient
                                            : null,
                                    color: value == 0
                                        ? AppColors
                                            .surfaceLight
                                        : null,
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  _dayNameShort(
                                    date.weekday,
                                  ),
                                  style: GoogleFonts
                                      .inter(
                                    fontSize: 8,
                                    color: AppColors
                                        .textMuted,
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
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAUSED
  // ============================================================

  Widget _buildPausedSection(
    HabitProvider provider,
  ) {
    final inactive =
        provider.inactiveHabits;

    if (inactive.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Paused habits',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color:
                  AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...inactive.map(
            (habit) =>
                _pausedHabitCard(
              provider,
              habit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pausedHabitCard(
    HabitProvider provider,
    HabitModel habit,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 9),
      padding:
          const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.card
            .withOpacity(0.65),
        borderRadius:
            BorderRadius.circular(17),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          _habitIcon(habit),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Paused',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color:
                        AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              provider.setHabitActive(
                habit.id,
                true,
              );
            },
            child: Text(
              'Resume',
              style:
                  GoogleFonts.inter(
                fontSize: 11,
                fontWeight:
                    FontWeight.w700,
                color:
                    AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState(
    HabitProvider provider,
  ) {
    final searching =
        _searchController.text
            .trim()
            .isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20,
      ),
      child: _glassContainer(
        padding:
            const EdgeInsets.all(28),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary
                    .withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                searching
                    ? Icons.search_off_rounded
                    : Icons.auto_awesome_rounded,
                color:
                    AppColors.accent,
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              searching
                  ? 'No matching habits'
                  : _filter == 'Completed'
                      ? 'Nothing completed yet'
                      : 'No habits here',
              style:
                  GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight:
                    FontWeight.w700,
                color:
                    AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Try another habit name or description.'
                  : 'Create a habit and start building consistency.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color:
                    AppColors.textMuted,
              ),
            ),
            if (!searching &&
                _filter != 'Completed') ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed:
                    _showAddHabitSheet,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 19,
                ),
                label: Text(
                  'Create habit',
                  style:
                      GoogleFonts.inter(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      15,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HABIT ACTIONS
  // ============================================================

  void _showHabitActions(
    BuildContext context,
    HabitProvider provider,
    HabitModel habit,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration:
              const BoxDecoration(
            color: AppColors.background,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          padding:
              const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            25,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color: AppColors
                        .glassBorder,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _habitIcon(habit),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        habit.name,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: GoogleFonts
                            .spaceGrotesk(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.w700,
                          color: AppColors
                              .textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _actionTile(
                  Icons.open_in_new_rounded,
                  'Open details',
                  'View calendar and performance',
                  () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _openDetails(habit);
                  },
                ),
                _actionTile(
                  Icons.edit_rounded,
                  'Edit habit',
                  'Change name, schedule or appearance',
                  () {
                    Navigator.pop(
                      sheetContext,
                    );
                    _showEditHabitSheet(
                      habit,
                    );
                  },
                ),
                _actionTile(
                  habit.isActive
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  habit.isActive
                      ? 'Pause habit'
                      : 'Resume habit',
                  habit.isActive
                      ? 'Temporarily remove it from your routine'
                      : 'Bring it back into your routine',
                  () {
                    provider.toggleHabitActive(
                      habit.id,
                    );
                    Navigator.pop(
                      sheetContext,
                    );
                  },
                ),
                _actionTile(
                  Icons.delete_outline_rounded,
                  'Delete habit',
                  'Remove habit and completion history',
                  () async {
                    Navigator.pop(
                      sheetContext,
                    );

                    final confirmed =
                        await _confirmDelete(
                      context,
                      habit,
                    );

                    if (confirmed) {
                      provider.deleteHabit(
                        habit.id,
                      );
                    }
                  },
                  danger: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool danger = false,
  }) {
    final color = danger
        ? AppColors.danger
        : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 5,
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration:
                    BoxDecoration(
                  color: (danger
                          ? AppColors.danger
                          : AppColors.primary)
                      .withOpacity(0.10),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  icon,
                  color: danger
                      ? AppColors.danger
                      : AppColors.accent,
                  size: 20,
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
                      style:
                          GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                          GoogleFonts.inter(
                        fontSize: 10,
                        color:
                            AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons
                    .chevron_right_rounded,
                color:
                    AppColors.textMuted,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetails(
    HabitModel habit,
  ) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration:
            const Duration(milliseconds: 350),
        reverseTransitionDuration:
            const Duration(milliseconds: 250),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) =>
            HabitDetailScreen(
          habitId: habit.id,
        ),
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
              position:
                  Tween<Offset>(
                begin:
                    const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ADD / EDIT SHEET
  // ============================================================

  void _showAddHabitSheet() {
    _prepareSheetForAdd();
    _showHabitSheet();
  }

  void _showEditHabitSheet(
    HabitModel habit,
  ) {
    _prepareSheetForEdit(habit);
    _showHabitSheet();
  }

  void _prepareSheetForAdd() {
    _isEditing = false;
    _editingHabitId = null;

    _habitController.clear();
    _descriptionController.clear();

    _selectedDays
      ..clear()
      ..addAll([
        1,
        2,
        3,
        4,
        5,
        6,
        7,
      ]);

    _selectedIcon = 'check_circle';
    _selectedColorValue = 0xff6366F1;
  }

  void _prepareSheetForEdit(
    HabitModel habit,
  ) {
    _isEditing = true;
    _editingHabitId = habit.id;

    _habitController.text = habit.name;
    _descriptionController.text =
        habit.description;

    _selectedDays
      ..clear()
      ..addAll(habit.weekdays);

    _selectedIcon = habit.icon;
    _selectedColorValue =
        habit.colorValue;
  }

  void _showHabitSheet() {
    final editing = _isEditing;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor:
          Colors.black.withOpacity(0.72),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
            context,
            setSheetState,
          ) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom,
              ),
              child: Container(
                constraints:
                    const BoxConstraints(
                  maxHeight: 760,
                ),
                decoration:
                    const BoxDecoration(
                  color: AppColors.background,
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child:
                      SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      25,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration:
                                BoxDecoration(
                              color: AppColors
                                  .glassBorder,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                10,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          editing
                              ? 'Edit habit'
                              : 'Create habit',
                          style: GoogleFonts
                              .spaceGrotesk(
                            fontSize: 24,
                            fontWeight:
                                FontWeight.w700,
                            color: AppColors
                                .textPrimary,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          editing
                              ? 'Update your routine without losing its history.'
                              : 'Choose when you want this habit to appear.',
                          style:
                              GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors
                                .textMuted,
                          ),
                        ),
                        const SizedBox(
                          height: 22,
                        ),
                        _fieldLabel(
                          'Habit name',
                        ),
                        const SizedBox(
                          height: 7,
                        ),
                        _textField(
                          controller:
                              _habitController,
                          hint:
                              'e.g. Read Biology',
                          icon:
                              Icons.edit_rounded,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        _fieldLabel(
                          'Description',
                        ),
                        const SizedBox(
                          height: 7,
                        ),
                        _textField(
                          controller:
                              _descriptionController,
                          hint: 'Optional',
                          icon:
                              Icons.notes_rounded,
                          maxLines: 2,
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        _fieldLabel(
                          'Schedule',
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        _schedulePresets(
                          setSheetState,
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        _daySelector(
                          setSheetState,
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        _fieldLabel(
                          'Icon',
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        _iconSelector(
                          setSheetState,
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        _fieldLabel(
                          'Accent',
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        _colorSelector(
                          setSheetState,
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                        SizedBox(
                          width: double.infinity,
                          height: 53,
                          child:
                              ElevatedButton(
                            onPressed: _isAdding
                                ? null
                                : () async {
                                    if (editing) {
                                      await _updateHabit(
                                        sheetContext,
                                      );
                                    } else {
                                      await _createHabit(
                                        sheetContext,
                                      );
                                    }
                                  },
                            style:
                                ElevatedButton
                                    .styleFrom(
                              backgroundColor:
                                  AppColors
                                      .primary,
                              foregroundColor:
                                  Colors.white,
                              disabledBackgroundColor:
                                  AppColors
                                      .surfaceLight,
                              elevation: 0,
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  17,
                                ),
                              ),
                            ),
                            child: _isAdding
                                ? const SizedBox(
                                    width: 21,
                                    height: 21,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2,
                                      color: Colors
                                          .white,
                                    ),
                                  )
                                : Text(
                                    editing
                                        ? 'Save changes'
                                        : 'Create habit',
                                    style:
                                        GoogleFonts
                                            .inter(
                                      fontSize:
                                          14,
                                      fontWeight:
                                          FontWeight
                                              .w700,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<void> _createHabit(
    BuildContext sheetContext,
  ) async {
    final name =
        _habitController.text.trim();

    if (!_validateHabit()) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    final provider =
        context.read<HabitProvider>();

    try {
      await provider.addHabit(
        name: name,
        description:
            _descriptionController.text
                .trim(),
        icon: _selectedIcon,
        colorValue:
            _selectedColorValue,
        weekdays:
            List<int>.from(
              _selectedDays,
            )..sort(),
      );

      if (!mounted) return;

      setState(() {
        _isAdding = false;
      });

      Navigator.of(
        sheetContext,
      ).pop();

      _showSuccessSnackBar(
        'Habit created successfully.',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isAdding = false;
      });

      _showErrorSnackBar(
        'Could not create habit.',
      );
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<void> _updateHabit(
    BuildContext sheetContext,
  ) async {
    final name =
        _habitController.text.trim();

    if (!_validateHabit()) {
      return;
    }

    final habitId =
        _editingHabitId;

    if (habitId == null) {
      return;
    }

    setState(() {
      _isAdding = true;
    });

    final provider =
        context.read<HabitProvider>();

    try {
      await provider.updateHabit(
        habitId: habitId,
        name: name,
        description:
            _descriptionController.text
                .trim(),
        icon: _selectedIcon,
        colorValue:
            _selectedColorValue,
        weekdays:
            List<int>.from(
              _selectedDays,
            )..sort(),
      );

      if (!mounted) return;

      setState(() {
        _isAdding = false;
      });

      Navigator.of(
        sheetContext,
      ).pop();

      _showSuccessSnackBar(
        'Habit updated successfully.',
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isAdding = false;
      });

      _showErrorSnackBar(
        'Could not update habit.',
      );
    }
  }

  bool _validateHabit() {
    if (_habitController.text.trim().isEmpty) {
      _showErrorSnackBar(
        'Enter a habit name first.',
      );
      return false;
    }

    if (_selectedDays.isEmpty) {
      _showErrorSnackBar(
        'Select at least one day.',
      );
      return false;
    }

    return true;
  }

  // ============================================================
  // SCHEDULE PRESETS
  // ============================================================

  Widget _schedulePresets(
    StateSetter setSheetState,
  ) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        _presetChip(
          'Every day',
          const [
            1,
            2,
            3,
            4,
            5,
            6,
            7,
          ],
          setSheetState,
        ),
        _presetChip(
          'Weekdays',
          const [
            1,
            2,
            3,
            4,
            5,
          ],
          setSheetState,
        ),
        _presetChip(
          'Weekends',
          const [
            6,
            7,
          ],
          setSheetState,
        ),
      ],
    );
  }

  Widget _presetChip(
    String title,
    List<int> days,
    StateSetter setSheetState,
  ) {
    final selected =
        _sameDays(
      _selectedDays,
      days,
    );

    return GestureDetector(
      onTap: () {
        setSheetState(() {
          _selectedDays
            ..clear()
            ..addAll(days);
        });
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
                  .withOpacity(0.18)
              : AppColors.card,
          borderRadius:
              BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? AppColors.primary
                    .withOpacity(0.55)
                : AppColors.cardBorder,
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight:
                FontWeight.w700,
            color: selected
                ? AppColors.accent
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  bool _sameDays(
    Set<int> selected,
    List<int> days,
  ) {
    return selected.length ==
            days.length &&
        selected.containsAll(days);
  }

  // ============================================================
  // DAY SELECTOR
  // ============================================================

  Widget _daySelector(
    StateSetter setSheetState,
  ) {
    const names = [
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ];

    return Row(
      children: List.generate(
        7,
        (index) {
          final day = index + 1;

          final selected =
              _selectedDays.contains(day);

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right:
                    index == 6 ? 0 : 6,
              ),
              child: GestureDetector(
                onTap: () {
                  setSheetState(() {
                    if (selected) {
                      _selectedDays
                          .remove(day);
                    } else {
                      _selectedDays
                          .add(day);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 180,
                  ),
                  height: 43,
                  decoration:
                      BoxDecoration(
                    color: selected
                        ? AppColors.primary
                            .withOpacity(
                            0.2,
                          )
                        : AppColors.card,
                    borderRadius:
                        BorderRadius
                            .circular(
                      13,
                    ),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                              .withOpacity(
                              0.55,
                            )
                          : AppColors
                              .cardBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      names[index],
                      style:
                          GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w700,
                        color: selected
                            ? AppColors
                                .accent
                            : AppColors
                                .textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ICON SELECTOR
  // ============================================================

  Widget _iconSelector(
    StateSetter setSheetState,
  ) {
    final icons =
        <String, IconData>{
      'check_circle':
          Icons.check_circle_rounded,
      'book':
          Icons.menu_book_rounded,
      'fitness':
          Icons.fitness_center_rounded,
      'water':
          Icons.water_drop_rounded,
      'sleep':
          Icons.bedtime_rounded,
      'study':
          Icons.school_rounded,
      'code':
          Icons.code_rounded,
      'music':
          Icons.music_note_rounded,
      'favorite':
          Icons.favorite_rounded,
      'star':
          Icons.star_rounded,
    };

    return Wrap(
      spacing: 9,
      runSpacing: 9,
      children: icons.entries.map(
        (entry) {
          final selected =
              _selectedIcon ==
                  entry.key;

          return GestureDetector(
            onTap: () {
              setSheetState(() {
                _selectedIcon =
                    entry.key;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 160,
              ),
              width: 46,
              height: 46,
              decoration:
                  BoxDecoration(
                color: selected
                    ? AppColors.primary
                        .withOpacity(
                        0.18,
                      )
                    : AppColors.card,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                          .withOpacity(
                          0.55,
                        )
                      : AppColors
                          .cardBorder,
                ),
              ),
              child: Icon(
                entry.value,
                size: 21,
                color: selected
                    ? AppColors.accent
                    : AppColors
                        .textMuted,
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // COLOR SELECTOR
  // ============================================================

  Widget _colorSelector(
    StateSetter setSheetState,
  ) {
    const colors = [
      0xff6366F1,
      0xff8B5CF6,
      0xff06B6D4,
      0xff10B981,
      0xffF59E0B,
      0xffEF4444,
      0xffEC4899,
      0xffFFFFFF,
    ];

    return Wrap(
      spacing: 11,
      children: colors.map(
        (colorValue) {
          final selected =
              _selectedColorValue ==
                  colorValue;

          final color =
              Color(colorValue);

          return GestureDetector(
            onTap: () {
              setSheetState(() {
                _selectedColorValue =
                    colorValue;
              });
            },
            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 160,
              ),
              width: 32,
              height: 32,
              decoration:
                  BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color
                              .withOpacity(
                            0.4,
                          ),
                          blurRadius: 12,
                        ),
                      ]
                    : null,
              ),
              child: selected
                  ? Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: colorValue ==
                              0xffffffff
                          ? Colors.black
                          : Colors.white,
                    )
                  : null,
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // FLOATING BUTTON
  // ============================================================

  Widget _buildFloatingButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddHabitSheet,
      backgroundColor:
          AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 10,
      icon: const Icon(
        Icons.add_rounded,
      ),
      label: Text(
        'New habit',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding: padding,
          decoration:
              BoxDecoration(
            color: AppColors.card
                .withOpacity(0.82),
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color:
                  AppColors.glassBorder,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          width: 46,
          height: 46,
          decoration:
              BoxDecoration(
            color: AppColors.card,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color:
                  AppColors.cardBorder,
            ),
          ),
          child: Icon(
            icon,
            color:
                AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(
    String text,
  ) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight:
            FontWeight.w700,
        color:
            AppColors.textSecondary,
      ),
    );
  }

  Widget _textField({
    required TextEditingController
        controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(
        fontSize: 13,
        color:
            AppColors.textPrimary,
      ),
      cursorColor:
          AppColors.accent,
      decoration:
          InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.inter(
          fontSize: 12,
          color:
              AppColors.textMuted,
        ),
        prefixIcon:
            Icon(
          icon,
          size: 19,
          color:
              AppColors.textMuted,
        ),
        filled: true,
        fillColor:
            AppColors.card,
        contentPadding:
            const EdgeInsets
                .symmetric(
          horizontal: 15,
          vertical: 15,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              const BorderSide(
            color:
                AppColors.cardBorder,
          ),
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              const BorderSide(
            color:
                AppColors.cardBorder,
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            15,
          ),
          borderSide:
              const BorderSide(
            color:
                AppColors.primary,
            width: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _animatedItem(
    int index,
    Widget child,
  ) {
    final start =
        (index * 0.08)
            .clamp(0.0, 0.7);

    final end =
        (start + 0.32)
            .clamp(0.0, 1.0);

    final animation =
        CurvedAnimation(
      parent: _listController,
      curve: Interval(
        start,
        end,
        curve:
            Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position:
            Tween<Offset>(
          begin:
              const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> _confirmDelete(
    BuildContext context,
    HabitModel habit,
  ) async {
    final result =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              AppColors.card,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
          ),
          title: Text(
            'Delete habit?',
            style:
                GoogleFonts.spaceGrotesk(
              fontWeight:
                  FontWeight.w700,
              color:
                  AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Delete "${habit.name}" and its completion history?',
            style:
                GoogleFonts.inter(
              fontSize: 13,
              color:
                  AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: Text(
                'Cancel',
                style:
                    GoogleFonts.inter(
                  color: AppColors
                      .textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: Text(
                'Delete',
                style:
                    GoogleFonts.inter(
                  fontWeight:
                      FontWeight.w700,
                  color:
                      AppColors.danger,
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
  // SNACKBARS
  // ============================================================

  void _showSuccessSnackBar(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons
                  .check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style:
                    GoogleFonts.inter(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
            AppColors.success,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(
    String message,
  ) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(),
        ),
        backgroundColor:
            AppColors.danger,
        behavior:
            SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // GENERAL HELPERS
  // ============================================================

  bool _isSameDay(
    DateTime a,
    DateTime b,
  ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  String _dayName(
    int weekday,
  ) {
    const names = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    return names[weekday - 1];
  }

  String _dayNameShort(
    int weekday,
  ) {
    const names = [
      'M',
      'T',
      'W',
      'T',
      'F',
      'S',
      'S',
    ];

    return names[weekday - 1];
  }

  IconData _iconFromName(
    String name,
  ) {
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