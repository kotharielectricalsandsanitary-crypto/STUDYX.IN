import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/study_session_provider.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const Color _violet = Color(0xFF7C5CFF);
  static const Color _indigo = Color(0xFF4F46E5);
  static const Color _gold = Color(0xFFF2C66D);
  static const Color _green = Color(0xFF36D399);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070A),
      body: SafeArea(
        child: Consumer<StudySessionProvider>(
          builder: (context, provider, _) {
            final now = DateTime.now();

            final days = List.generate(
              7,
              (index) => DateTime(
                now.year,
                now.month,
                now.day - (6 - index),
              ),
            );

            final dailyHours = days
                .map((date) => provider.hoursForDate(date))
                .toList();

            final todayHours = dailyHours.last;

            final weeklyTotal = dailyHours.fold<double>(
              0,
              (sum, value) => sum + value,
            );

            final weeklyAverage = weeklyTotal / 7;

            final maxHours = dailyHours.isEmpty
                ? 1.0
                : math.max(
                    dailyHours.reduce(math.max),
                    1.0,
                  );

            final bestIndex = dailyHours.isEmpty
                ? 0
                : dailyHours.indexOf(
                    dailyHours.reduce(math.max),
                  );

            final bestDay =
                days.isEmpty ? now : days[bestIndex];

            final bestHours =
                dailyHours.isEmpty ? 0.0 : dailyHours[bestIndex];

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 920,
                ),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    16,
                    18,
                    110,
                  ),
                  children: [
                    _animatedItem(
                      index: 0,
                      child: _buildHeader(),
                    ),

                    const SizedBox(height: 20),

                    _animatedItem(
                      index: 1,
                      child: _buildOverviewCard(
                        todayHours,
                        weeklyTotal,
                        weeklyAverage,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _animatedItem(
                      index: 2,
                      child: _buildGraphCard(
                        days,
                        dailyHours,
                        maxHours,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _animatedItem(
                      index: 3,
                      child: _buildBestDayCard(
                        bestDay,
                        bestHours,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _animatedItem(
                      index: 4,
                      child: _buildStatisticsCard(
                        provider,
                        weeklyTotal,
                        weeklyAverage,
                      ),
                    ),

                    const SizedBox(height: 18),

                    _animatedItem(
                      index: 5,
                      child: _buildRecentSessions(provider),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your study performance at a glance',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.42),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _violet,
                _indigo,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _violet.withOpacity(0.25),
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: const Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // OVERVIEW
  // ─────────────────────────────────────────────

  Widget _buildOverviewCard(
    double todayHours,
    double weeklyTotal,
    double weeklyAverage,
  ) {
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF17142A),
            Color(0xFF0E0E13),
          ],
        ),
        border: Border.all(
          color: _violet.withOpacity(0.17),
        ),
        boxShadow: [
          BoxShadow(
            color: _violet.withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _violet.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'LAST 7 DAYS',
                  style: GoogleFonts.inter(
                    color: _violet,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.auto_awesome_rounded,
                color: _gold,
                size: 16,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            _formatHours(weeklyTotal),
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Total focused study time',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.40),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _overviewMetric(
                  icon: Icons.today_rounded,
                  value: _formatHours(todayHours),
                  label: 'Today',
                  accent: _green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _overviewMetric(
                  icon: Icons.speed_rounded,
                  value: _formatHours(weeklyAverage),
                  label: 'Daily average',
                  accent: _gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewMetric({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.035),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.055),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: accent,
              size: 16,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // GRAPH
  // ─────────────────────────────────────────────

  Widget _buildGraphCard(
    List<DateTime> days,
    List<double> dailyHours,
    double maxHours,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        19,
        18,
        17,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: Colors.white.withOpacity(0.065),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Study activity',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Daily focused hours',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.35),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _violet.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: _violet,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '7 days',
                      style: GoogleFonts.inter(
                        color: _violet,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          SizedBox(
            height: 225,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${maxHours.ceil()}h',
                        style: _axisStyle(),
                      ),
                      Text(
                        '${(maxHours * 0.75).ceil()}h',
                        style: _axisStyle(),
                      ),
                      Text(
                        '${(maxHours * 0.5).ceil()}h',
                        style: _axisStyle(),
                      ),
                      Text(
                        '${(maxHours * 0.25).ceil()}h',
                        style: _axisStyle(),
                      ),
                      Text(
                        '0h',
                        style: _axisStyle(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildBars(
                    days,
                    dailyHours,
                    maxHours,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _axisStyle() {
    return GoogleFonts.inter(
      color: Colors.white.withOpacity(0.20),
      fontSize: 8,
      fontWeight: FontWeight.w600,
    );
  }

  Widget _buildBars(
    List<DateTime> days,
    List<double> dailyHours,
    double maxHours,
  ) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      5,
                      (_) => Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.white.withOpacity(0.045),
                      ),
                    ),
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: List.generate(
                        dailyHours.length,
                        (index) {
                          final ratio = maxHours <= 0
                              ? 0.0
                              : (dailyHours[index] /
                                      maxHours)
                                  .clamp(0.0, 1.0);

                          final start =
                              (index * 0.08).clamp(
                            0.0,
                            0.55,
                          );

                          final end =
                              (start + 0.40).clamp(
                            0.0,
                            1.0,
                          );

                          final animation =
                              CurvedAnimation(
                            parent: _controller,
                            curve: Interval(
                              start,
                              end,
                              curve: Curves.easeOutCubic,
                            ),
                          );

                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, _) {
                              final animatedRatio =
                                  ratio *
                                      animation.value;

                              final height =
                                  constraints.maxHeight *
                                      animatedRatio;

                              final isToday =
                                  index ==
                                      dailyHours.length - 1;

                              return SizedBox(
                                width: 29,
                                height:
                                    constraints.maxHeight,
                                child: Align(
                                  alignment:
                                      Alignment.bottomCenter,
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      if (dailyHours[index] >
                                              0 &&
                                          animation.value >
                                              0.7)
                                        Padding(
                                          padding:
                                              const EdgeInsets
                                                  .only(
                                            bottom: 5,
                                          ),
                                          child: Text(
                                            _shortHours(
                                              dailyHours[index],
                                            ),
                                            style:
                                                GoogleFonts
                                                    .inter(
                                              color: isToday
                                                  ? _gold
                                                  : Colors.white
                                                      .withOpacity(
                                                      0.45,
                                                    ),
                                              fontSize: 8,
                                              fontWeight:
                                                  FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      Container(
                                        width: 18,
                                        height: math.max(
                                          height,
                                          dailyHours[index] >
                                                  0
                                              ? 3
                                              : 0,
                                        ),
                                        decoration:
                                            BoxDecoration(
                                          borderRadius:
                                              const BorderRadius
                                                  .vertical(
                                            top:
                                                Radius.circular(
                                              7,
                                            ),
                                          ),
                                          gradient:
                                              LinearGradient(
                                            begin: Alignment
                                                .topCenter,
                                            end: Alignment
                                                .bottomCenter,
                                            colors: isToday
                                                ? [
                                                    _gold,
                                                    _gold
                                                        .withOpacity(
                                                        0.28,
                                                      ),
                                                  ]
                                                : [
                                                    _violet,
                                                    _indigo
                                                        .withOpacity(
                                                        0.25,
                                                      ),
                                                  ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isToday
                                                  ? _gold
                                                      .withOpacity(
                                                      0.15,
                                                    )
                                                  : _violet
                                                      .withOpacity(
                                                      0.13,
                                                    ),
                                              blurRadius: 12,
                                              spreadRadius: -4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,
          children: List.generate(
            days.length,
            (index) {
              final isToday =
                  index == days.length - 1;

              return SizedBox(
                width: 29,
                child: Text(
                  _dayName(days[index]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isToday
                        ? _gold
                        : Colors.white.withOpacity(0.28),
                    fontSize: 8,
                    fontWeight: isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // BEST DAY
  // ─────────────────────────────────────────────

  Widget _buildBestDayCard(
    DateTime bestDay,
    double bestHours,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: _gold.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: _gold.withOpacity(0.08),
              border: Border.all(
                color: _gold.withOpacity(0.13),
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: _gold,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Best study day',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.38),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateLabel(bestDay),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          Text(
            _formatHours(bestHours),
            style: GoogleFonts.inter(
              color: _gold,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────

  Widget _buildStatisticsCard(
    StudySessionProvider provider,
    double weeklyTotal,
    double weeklyAverage,
  ) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.065),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.access_time_filled_rounded,
                  value: _formatHours(provider.totalHours),
                  label: 'All-time study',
                  accent: _violet,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  icon: Icons.timer_rounded,
                  value: '${provider.sessions.length}',
                  label: 'Sessions',
                  accent: _green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _statTile(
                  icon: Icons.date_range_rounded,
                  value: _formatHours(weeklyTotal),
                  label: 'This week',
                  accent: _gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  icon: Icons.trending_up_rounded,
                  value: _formatHours(weeklyAverage),
                  label: 'Daily average',
                  accent: _indigo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.028),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.045),
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
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.32),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // RECENT SESSIONS
  // ─────────────────────────────────────────────

  Widget _buildRecentSessions(
    StudySessionProvider provider,
  ) {
    final sessions = provider.sessions.reversed
        .take(5)
        .toList();

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.065),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent sessions',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${sessions.length}',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          if (sessions.isEmpty)
            _buildNoSessions()
          else
            ...List.generate(
              sessions.length,
              (index) {
                final session = sessions[index];

                return Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        index == sessions.length - 1
                            ? 0
                            : 9,
                  ),
                  child: _buildSessionTile(
                    session,
                    index,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNoSessions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 25,
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            color: Colors.white.withOpacity(0.15),
            size: 31,
          ),
          const SizedBox(height: 9),
          Text(
            'No study sessions yet',
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.38),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(
    dynamic session,
    int index,
  ) {
    final duration = _formatSeconds(
      session.seconds,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.025),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.045),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: _violet.withOpacity(0.08),
            ),
            child: const Icon(
              Icons.timer_outlined,
              color: _violet,
              
              size: 18,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _dateLabel(session.date),
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _timeLabel(session.date),
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.30),
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              duration,
              style: GoogleFonts.inter(
                color: _green,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ANIMATION
  // ─────────────────────────────────────────────

  Widget _animatedItem({
    required int index,
    required Widget child,
  }) {
    final start =
        (index * 0.075).clamp(0.0, 0.65);

    final end =
        (start + 0.35).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
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
          begin: const Offset(0, 0.045),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FORMATTERS
  // ─────────────────────────────────────────────

  String _formatHours(double hours) {
    if (hours <= 0) {
      return '0m';
    }

    final totalMinutes =
        (hours * 60).round();

    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    if (h == 0) {
      return '${m}m';
    }

    if (m == 0) {
      return '${h}h';
    }

    return '${h}h ${m}m';
  }

  String _shortHours(double hours) {
    if (hours <= 0) {
      return '0m';
    }

    if (hours < 1) {
      return '${(hours * 60).round()}m';
    }

    return '${hours.toStringAsFixed(1)}h';
  }

  String _formatSeconds(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes =
        (seconds % 3600) ~/ 60;

    if (hours > 0) {
      if (minutes == 0) {
        return '${hours}h';
      }

      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m';
    }

    return '${seconds}s';
  }

  String _dayName(DateTime date) {
    const names = [
      'MON',
      'TUE',
      'WED',
      'THU',
      'FRI',
      'SAT',
      'SUN',
    ];

    return names[date.weekday - 1];
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

  String _timeLabel(DateTime date) {
    final hour =
        date.hour.toString().padLeft(2, '0');

    final minute =
        date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}