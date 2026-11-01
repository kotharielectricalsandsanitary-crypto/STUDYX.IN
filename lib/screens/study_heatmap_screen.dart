import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/study_session_provider.dart';

/// Study Consistency Heatmap for StudyX.
///
/// Uses saved StudySessionProvider sessions (session.date and session.seconds).
/// This screen does not change or overwrite any existing StudyX screen.
class StudyHeatmapScreen extends StatefulWidget {
  const StudyHeatmapScreen({super.key});

  @override
  State<StudyHeatmapScreen> createState() => _StudyHeatmapScreenState();
}

class _StudyHeatmapScreenState extends State<StudyHeatmapScreen> {
  int _year = DateTime.now().year;

  static const Color _background = Color(0xFF08090D);
  static const Color _panelColor = Color(0xFF12141B);
  static const Color _border = Color(0xFF252936);
  static const Color _muted = Color(0xFF8D95A7);
  static const Color _green1 = Color(0xFF183A2A);
  static const Color _green2 = Color(0xFF246B43);
  static const Color _green3 = Color(0xFF2EA866);
  static const Color _green4 = Color(0xFF6BE39B);

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  Map<DateTime, int> _dailySeconds(StudySessionProvider provider) {
    final result = <DateTime, int>{};
    for (final session in provider.sessions) {
      final date = _day(session.date);
      if (date.year == _year && session.seconds > 0) {
        result[date] = (result[date] ?? 0) + session.seconds;
      }
    }
    return result;
  }

  int _currentStreak(Set<DateTime> dates) {
    final today = _day(DateTime.now());
    var cursor = dates.contains(today) ? today : today.subtract(const Duration(days: 1));
    var count = 0;
    while (dates.contains(cursor)) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }

  int _longestStreak(Set<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final sorted = dates.toList()..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  Color _level(int seconds) {
    if (seconds <= 0) return const Color(0xFF20232C);
    if (seconds < 3600) return _green1;
    if (seconds < 2 * 3600) return _green2;
    if (seconds < 4 * 3600) return _green3;
    return _green4;
  }

  String _duration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m';
    return '0m';
  }

  String _monthLabel(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Widget _panel(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _panelColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
        ),
        child: child,
      );

  Widget _stat(String label, String value, IconData icon, Color tint) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _panelColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tint, size: 19),
            const SizedBox(height: 10),
            Text(value, style: GoogleFonts.inter(
              color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800,
            )),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(
              color: _muted, fontSize: 10, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Consumer<StudySessionProvider>(
          builder: (context, provider, _) {
            final daily = _dailySeconds(provider);
            final dates = daily.keys.toSet();
            final totalSeconds = daily.values.fold<int>(0, (a, b) => a + b);
            final activeDays = dates.length;
            final currentStreak = _currentStreak(dates);
            final longestStreak = _longestStreak(dates);
            final now = DateTime.now();
            final yearStart = DateTime(_year, 1, 1);
            final yearEnd = DateTime(_year + 1, 1, 1);
            // Start on Monday so each column is a week, like a contribution chart.
            final gridStart = yearStart.subtract(
              Duration(days: yearStart.weekday - 1),
            );
            final totalWeeks = ((yearEnd.difference(gridStart).inDays + 6) ~/ 7);

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _green2.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: _green4),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Study Consistency', style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
                          )),
                          const SizedBox(height: 3),
                          Text('Your study activity, one day at a time', style: GoogleFonts.inter(
                            color: _muted, fontSize: 11,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _stat('Study time', _duration(totalSeconds), Icons.timer_outlined, _green4),
                    const SizedBox(width: 9),
                    _stat('Active days', '$activeDays', Icons.check_circle_outline, const Color(0xFF69B8FF)),
                    const SizedBox(width: 9),
                    _stat('Current streak', '$currentStreak 🔥', Icons.local_fire_department_outlined, const Color(0xFFFFB45B)),
                  ],
                ),
                const SizedBox(height: 12),
                _panel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Activity map', style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800,
                            )),
                          ),
                          IconButton(
                            tooltip: 'Previous year',
                            onPressed: _year > 2000 ? () => setState(() => _year--) : null,
                            icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                          ),
                          Text('$_year', style: GoogleFonts.inter(
                            color: Colors.white, fontWeight: FontWeight.w800,
                          )),
                          IconButton(
                            tooltip: 'Next year',
                            onPressed: _year < now.year ? () => setState(() => _year++) : null,
                            icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(totalWeeks, (week) {
                                final date = gridStart.add(Duration(days: week * 7));
                                final showMonth = date.day <= 7 || week == 0;
                                return SizedBox(
                                  width: 13,
                                  child: showMonth
                                      ? Text(_monthLabel(date.month), style: GoogleFonts.inter(
                                          color: _muted, fontSize: 8,
                                        ), overflow: TextOverflow.visible)
                                      : const SizedBox.shrink(),
                                );
                              }),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(totalWeeks, (week) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 3),
                                  child: Column(
                                    children: List.generate(7, (weekdayIndex) {
                                      final date = gridStart.add(
                                        Duration(days: week * 7 + weekdayIndex),
                                      );
                                      final inYear = date.year == _year;
                                      final seconds = daily[_day(date)] ?? 0;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 3),
                                        child: Tooltip(
                                          message: inYear
                                              ? '${date.day} ${_monthLabel(date.month)} $_year · ${_duration(seconds)}'
                                              : '',
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                              color: inYear ? _level(seconds) : Colors.transparent,
                                              borderRadius: BorderRadius.circular(2),
                                              border: date.year == now.year &&
                                                      date.month == now.month &&
                                                      date.day == now.day
                                                  ? Border.all(color: Colors.white, width: 1)
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('Less', style: GoogleFonts.inter(color: _muted, fontSize: 10)),
                          const SizedBox(width: 6),
                          ...[_level(0), _green1, _green2, _green3, _green4].map(
                            (color) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              width: 11,
                              height: 11,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Text('More', style: GoogleFonts.inter(color: _muted, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _panel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Consistency insights', style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800,
                      )),
                      const SizedBox(height: 15),
                      _insight(Icons.local_fire_department_rounded, 'Longest streak', '$longestStreak days'),
                      const SizedBox(height: 13),
                      _insight(Icons.event_available_rounded, 'Days studied this year', '$activeDays of ${DateTime.now().year == _year ? now.difference(yearStart).inDays + 1 : 365} days'),
                      const SizedBox(height: 13),
                      _insight(Icons.lightbulb_outline_rounded, 'Your next step',
                        activeDays == 0
                            ? 'Save your first study session to start the map.'
                            : (dates.contains(_day(now))
                                ? 'You studied today. Keep your routine realistic and steady.'
                                : 'Save a study session today to continue your progress.')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Only saved StudyX study sessions count. Days without a saved session stay empty.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: _muted, fontSize: 11, height: 1.5),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _insight(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: _green4, size: 19),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            color: _muted, fontSize: 12, fontWeight: FontWeight.w600,
          ))),
          const SizedBox(width: 8),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: GoogleFonts.inter(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800,
          ))),
        ],
      );
}
