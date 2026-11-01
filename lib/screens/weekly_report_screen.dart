import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/study_session_provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class WeeklyReportScreen extends StatelessWidget {
  const WeeklyReportScreen({super.key});

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  String _duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  Widget _panel(Widget child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('Weekly Report',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            )),
      ),
      body: SafeArea(
        child: Consumer2<StudySessionProvider, UserProvider>(
          builder: (context, study, user, _) {
            final today = _day(DateTime.now());
            final monday = today.subtract(Duration(days: today.weekday - 1));
            final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final secondsByDay = List<int>.filled(7, 0);
            var sessionCount = 0;

            for (final session in study.sessions) {
              final d = _day(session.date);
              if (d.isBefore(monday) ||
                  d.isAfter(monday.add(const Duration(days: 6)))) {
                continue;
              }
              final i = d.difference(monday).inDays;
              if (i >= 0 && i < 7) {
                secondsByDay[i] += session.seconds;
                sessionCount++;
              }
            }

            final total = secondsByDay.fold<int>(0, (a, b) => a + b);
            final activeDays = secondsByDay.where((s) => s > 0).length;
            final average = activeDays == 0 ? 0 : total ~/ activeDays;
            final best = secondsByDay.fold<int>(0, (a, b) => a > b ? a : b);
            final bestIndex = secondsByDay.indexOf(best);
            final goalHours = user.dailyHours > 0 ? user.dailyHours : 0.0;
            final weekGoal = (goalHours * 7 * 3600).round();
            final progress = weekGoal == 0
                ? 0.0
                : (total / weekGoal).clamp(0.0, 1.0).toDouble();
            final goalDays = goalHours == 0
                ? 0
                : secondsByDay.where((s) => s >= goalHours * 3600).length;
            final maxBar = [
              ...secondsByDay,
              if (goalHours > 0) (goalHours * 3600).round(),
              1,
            ].reduce((a, b) => a > b ? a : b);

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                _panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.insights_rounded,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Your week at a glance',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  )),
                              const SizedBox(height: 4),
                              Text(
                                  '${monday.day}/${monday.month} – ${monday.add(const Duration(days: 6)).day}/${monday.add(const Duration(days: 6)).month}',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                            ])),
                      ]),
                      const SizedBox(height: 22),
                      Text(_duration(total),
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          )),
                      const SizedBox(height: 4),
                      Text('Total saved study time this week',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          )),
                      if (goalHours > 0) ...[
                        const SizedBox(height: 18),
                        Row(children: [
                          Expanded(
                              child: Text('Weekly goal: ${_duration(weekGoal)}',
                                  style: GoogleFonts.inter(
                                      color: AppColors.textSecondary,
                                      fontSize: 12))),
                          Text('${(progress * 100).round()}%',
                              style: GoogleFonts.inter(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800)),
                        ]),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 9,
                            backgroundColor: AppColors.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ],
                    ])),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _stat('Sessions', '$sessionCount',
                          Icons.timer_outlined, AppColors.primary)),
                  const SizedBox(width: 9),
                  Expanded(
                      child: _stat('Active days', '$activeDays/7',
                          Icons.calendar_today_rounded, AppColors.accent)),
                  const SizedBox(width: 9),
                  Expanded(
                      child: _stat(
                          'Goal days',
                          goalHours == 0 ? '—' : '$goalDays/7',
                          Icons.flag_rounded,
                          const Color(0xFF45C486))),
                ]),
                const SizedBox(height: 12),
                _panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Daily study time',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 18),
                      SizedBox(
                          height: 160,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(7, (i) {
                              final seconds = secondsByDay[i];
                              final barHeight = seconds == 0
                                  ? 5.0
                                  : (100.0 * seconds / maxBar)
                                      .clamp(5.0, 100.0)
                                      .toDouble();
                              final isToday = i == today.weekday - 1;
                              return Expanded(
                                  child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(_duration(seconds),
                                          style: GoogleFonts.inter(
                                            color: AppColors.textSecondary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                          )),
                                      const SizedBox(height: 7),
                                      Container(
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          gradient: seconds > 0
                                              ? AppColors.primaryGradient
                                              : null,
                                          color: seconds == 0
                                              ? AppColors.cardBorder
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      const SizedBox(height: 9),
                                      Text(labels[i],
                                          style: GoogleFonts.inter(
                                            color: isToday
                                                ? AppColors.primary
                                                : AppColors.textMuted,
                                            fontSize: 10,
                                            fontWeight: isToday
                                                ? FontWeight.w900
                                                : FontWeight.w600,
                                          )),
                                    ]),
                              ));
                            }),
                          )),
                      if (goalHours > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                            'Daily target: ${_duration((goalHours * 3600).round())}',
                            style: GoogleFonts.inter(
                                color: AppColors.textMuted, fontSize: 11)),
                      ],
                    ])),
                const SizedBox(height: 12),
                _panel(Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly insights',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 15),
                      _insight(Icons.trending_up_rounded,
                          'Average per active day', _duration(average)),
                      const SizedBox(height: 13),
                      _insight(
                          Icons.emoji_events_outlined,
                          'Best study day',
                          best == 0
                              ? 'No sessions yet'
                              : '${labels[bestIndex]} · ${_duration(best)}'),
                      const SizedBox(height: 13),
                      _insight(
                          Icons.bolt_rounded,
                          'Next step',
                          total == 0
                              ? 'Save your first study session'
                              : (weekGoal > 0 && total >= weekGoal
                                  ? 'Weekly goal completed — great work!'
                                  : 'Keep building steady progress')),
                    ])),
                const SizedBox(height: 14),
                Text(
                    'Only sessions saved in StudyX are counted. Unsaved timer time is not included.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.5,
                    )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) =>
      _panel(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 11),
          Text(value,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              )),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              )),
        ]),
      );

  Widget _insight(IconData icon, String label, String value) => Row(children: [
        Icon(icon, size: 19, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ))),
        const SizedBox(width: 8),
        Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ))),
      ]);
}
