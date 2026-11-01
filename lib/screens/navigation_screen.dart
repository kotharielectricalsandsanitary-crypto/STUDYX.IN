import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import 'backlog_screen.dart';
import 'exam/exam_screen.dart';
import 'graph_screen.dart';
import 'habit_screen.dart';
import 'home_screen.dart';
import 'manual_planner_screen.dart';
import 'revision_screen.dart';
import 'study_buddy_screen.dart';
import 'study_heatmap_screen.dart';
import 'syllabus_screen.dart';
import 'tasks_screen.dart';
import 'weekly_report_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  static const String _prefsKey = 'studyx_pinned_navigation_screens';
  static const String _hiddenPrefsKey = 'studyx_temporarily_hidden_screens';
  static const int _minPinned = 2;
  static const int _maxPinned = 4;

  static const int _home = 0;
  static const int _syllabus = 1;
  static const int _tasks = 2;
  static const int _backlog = 3;
  static const int _revision = 4;
  static const int _exam = 5;
  static const int _habits = 6;
  static const int _graph = 7;
  static const int _manualPlanner = 8;
  static const int _studyBuddy = 9;
  static const int _weeklyReport = 10;
  static const int _consistency = 11;

  int _selectedIndex = _home;
  bool _preferencesLoaded = false;
  List<int> _hiddenIndexes = const [];
  List<int> _pinnedIndexes = const [_home, _syllabus, _tasks, _graph];

  final List<Widget> _screens = const [
    HomeScreen(),
    SyllabusScreen(),
    TasksScreen(),
    BacklogScreen(),
    RevisionScreen(),
    ExamScreen(),
    HabitScreen(),
    GraphScreen(),
    ManualPlannerScreen(),
    StudyBuddyScreen(),
    WeeklyReportScreen(),
    StudyHeatmapScreen(),
  ];

  static const List<_ScreenLink> _allScreens = [
    _ScreenLink('Home', Icons.home_rounded, _home, 'Your study dashboard'),
    _ScreenLink('Syllabus', Icons.menu_book_rounded, _syllabus, 'Subjects and chapters'),
    _ScreenLink('Tasks', Icons.check_circle_outline_rounded, _tasks, 'Daily study tasks'),
    _ScreenLink('Backlog', Icons.library_books_rounded, _backlog, 'Catch up on pending work'),
    _ScreenLink('Revision', Icons.history_edu_rounded, _revision, 'Revise what you studied'),
    _ScreenLink('Exam Planner', Icons.calendar_month_rounded, _exam, 'Plan upcoming exams'),
    _ScreenLink('Habits', Icons.track_changes_rounded, _habits, 'Track study habits'),
    _ScreenLink('Progress Graph', Icons.bar_chart_rounded, _graph, 'View study progress'),
    _ScreenLink('Manual Planner', Icons.event_note_rounded, _manualPlanner, 'Build your own plan'),
    _ScreenLink('Study Buddy', Icons.smart_toy_rounded, _studyBuddy, 'Your study companion'),
    _ScreenLink('Weekly Report', Icons.assessment_rounded, _weeklyReport, 'Review your week'),
    _ScreenLink('Study Consistency', Icons.calendar_view_month_rounded, _consistency, 'View your consistency heatmap'),
  ];

  @override
  void initState() {
    super.initState();
    _loadPinnedScreens();
  }

  Future<void> _loadPinnedScreens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_prefsKey);
      final hiddenStored = prefs.getStringList(_hiddenPrefsKey);
      final hidden = (hiddenStored ?? const <String>[])
          .map(int.tryParse)
          .whereType<int>()
          .where((index) => index > _home && index < _screens.length)
          .toSet()
          .toList();
      if (stored != null) {
        final parsed = stored.map(int.tryParse).whereType<int>()
            .where((index) => index >= 0 && index < _screens.length && !hidden.contains(index))
            .toSet().toList();
        if (parsed.length >= _minPinned && parsed.length <= _maxPinned) {
          if (!mounted) return;
          setState(() {
            _hiddenIndexes = hidden;
            _pinnedIndexes = parsed;
            _preferencesLoaded = true;
          });
          return;
        }
      }
      if (mounted) {
        setState(() {
          _hiddenIndexes = hidden;
          _pinnedIndexes = [_home, _syllabus, _tasks, _graph].where((i) => !hidden.contains(i)).take(_maxPinned).toList();
          while (_pinnedIndexes.length < _minPinned) {
            final available = _allScreens.where((link) => !hidden.contains(link.screenIndex) && !_pinnedIndexes.contains(link.screenIndex));
            if (available.isEmpty) break;
            _pinnedIndexes.add(available.first.screenIndex);
          }
          _preferencesLoaded = true;
        });
      }
    } catch (_) {
      // Keep safe defaults if preferences cannot be read.
      if (mounted) setState(() => _preferencesLoaded = true);
    }
  }

  Future<void> _saveHiddenScreens(List<int> indexes) async {
    final hidden = indexes.where((i) => i > _home && i < _screens.length).toSet().toList();
    final nextPinned = _pinnedIndexes.where((i) => !hidden.contains(i)).toList();
    for (final preferred in [_home, _syllabus, _tasks, _graph, _revision, _exam]) {
      if (nextPinned.length >= _minPinned) break;
      if (!hidden.contains(preferred) && !nextPinned.contains(preferred)) nextPinned.add(preferred);
    }
    for (final link in _allScreens) {
      if (nextPinned.length >= _minPinned) break;
      if (!hidden.contains(link.screenIndex) && !nextPinned.contains(link.screenIndex)) nextPinned.add(link.screenIndex);
    }
    setState(() {
      _hiddenIndexes = hidden;
      _pinnedIndexes = nextPinned.take(_maxPinned).toList();
      if (hidden.contains(_selectedIndex)) _selectedIndex = _home;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_hiddenPrefsKey, hidden.map((i) => i.toString()).toList());
      await prefs.setStringList(_prefsKey, _pinnedIndexes.map((i) => i.toString()).toList());
    } catch (_) {}
  }

  Future<void> _savePinnedScreens(List<int> indexes) async {
    setState(() => _pinnedIndexes = List<int>.from(indexes));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, indexes.map((index) => index.toString()).toList());
    } catch (_) {
      // Navigation still works for this session if persistence is unavailable.
    }
  }

  void _selectScreen(int index) {
    if (index < 0 || index >= _screens.length) return;
    if (mounted) setState(() => _selectedIndex = index);
  }

  Future<void> _showAllScreens({bool customize = false, bool manageHidden = false}) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        List<int> draft = List<int>.from(_pinnedIndexes);
        List<int> hiddenDraft = List<int>.from(_hiddenIndexes);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final height = MediaQuery.of(context).size.height * 0.78;
            return SafeArea(
              child: Container(
                height: height,
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.glassBorder),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 30, offset: Offset(0, 8))],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 38, height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMuted.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customize ? 'Customize bottom bar' : manageHidden ? 'Temporarily hidden screens' : 'All StudyX screens',
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 19, fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        customize
                            ? 'Choose $_minPinned–$_maxPinned shortcuts. Unpinned screens stay available here.'
                            : manageHidden
                                ? 'Restore a hidden screen whenever you need it. Nothing is deleted.'
                                : 'Open a screen, hide one temporarily, or customize your shortcuts.',
                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                    if (!customize && !manageHidden) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _showAllScreens(customize: true);
                          },
                          icon: const Icon(Icons.tune_rounded),
                          label: const Text('Customize bottom bar'),
                        ),
                      ),
                    ],
                    if (!customize) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _showAllScreens(manageHidden: !manageHidden);
                          },
                          icon: Icon(manageHidden ? Icons.arrow_back_rounded : Icons.visibility_off_rounded),
                          label: Text(manageHidden ? 'Back to available screens' : 'Manage hidden screens (${_hiddenIndexes.length})'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: (manageHidden ? _allScreens.where((link) => hiddenDraft.contains(link.screenIndex)) : _allScreens.where((link) => !hiddenDraft.contains(link.screenIndex))).length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.glassBorder),
                        itemBuilder: (context, index) {
                          final visibleLinks = (manageHidden ? _allScreens.where((item) => hiddenDraft.contains(item.screenIndex)) : _allScreens.where((item) => !hiddenDraft.contains(item.screenIndex))).toList();
                          final link = visibleLinks[index];
                          final pinned = draft.contains(link.screenIndex);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                            leading: Container(
                              width: 43, height: 43,
                              decoration: BoxDecoration(
                                color: pinned ? AppColors.primary.withValues(alpha: .14) : AppColors.background.withValues(alpha: .65),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: pinned ? AppColors.primary.withValues(alpha: .30) : AppColors.glassBorder),
                              ),
                              child: Icon(link.icon, color: pinned ? AppColors.primary : AppColors.textSecondary),
                            ),
                            title: Text(link.label, style: GoogleFonts.inter(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
                            subtitle: Text(link.description, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                            trailing: customize
                                ? Icon(
                                    pinned ? Icons.push_pin_rounded : Icons.add_circle_outline_rounded,
                                    color: pinned ? AppColors.primary : AppColors.textMuted,
                                  )
                                : manageHidden
                                    ? IconButton(
                                        tooltip: 'Restore screen',
                                        icon: Icon(Icons.visibility_rounded, color: AppColors.primary),
                                        onPressed: () {
                                          final updated = List<int>.from(hiddenDraft)..remove(link.screenIndex);
                                          setSheetState(() => hiddenDraft = updated);
                                          _saveHiddenScreens(updated);
                                        },
                                      )
                                    : link.screenIndex == _home
                                        ? Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)
                                        : IconButton(
                                            tooltip: 'Hide temporarily',
                                            icon: Icon(Icons.visibility_off_outlined, color: AppColors.textMuted),
                                            onPressed: () {
                                              final updated = List<int>.from(hiddenDraft)..add(link.screenIndex);
                                              setSheetState(() => hiddenDraft = updated);
                                              _saveHiddenScreens(updated);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('${link.label} hidden temporarily. Restore it from More → Manage hidden screens.')),
                                              );
                                            },
                                          ),
                            onTap: () {
                              if (customize) {
                                if (pinned) {
                                  if (draft.length <= _minPinned) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Keep at least 2 shortcuts on the bottom bar.')),
                                    );
                                    return;
                                  }
                                  setSheetState(() => draft.remove(link.screenIndex));
                                } else {
                                  if (draft.length >= _maxPinned) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('The bottom bar supports up to 4 shortcuts. Remove one first.')),
                                    );
                                    return;
                                  }
                                  setSheetState(() => draft.add(link.screenIndex));
                                }
                              } else if (!manageHidden) {
                                Navigator.of(sheetContext).pop();
                                _selectScreen(link.screenIndex);
                              }
                            },
                          );
                        },
                      ),
                    ),
                    if (customize) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text('${draft.length} of $_maxPinned shortcuts selected',
                              style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          TextButton(
                            onPressed: () => setSheetState(() => draft = [_home, _syllabus, _tasks, _graph].where((i) => !hiddenDraft.contains(i)).take(_maxPinned).toList()),
                            child: const Text('Reset'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: draft.length < _minPinned || draft.length > _maxPinned
                                ? null
                                : () async {
                                    await _savePinnedScreens(draft);
                                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                                  },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1050;
    final isTablet = width >= 700 && width < 1050;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          if (isDesktop) _buildDesktopSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
      bottomNavigationBar: isDesktop ? null : _buildBottomBar(isTablet),
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        Positioned(
          top: -140, right: -120,
          child: IgnorePointer(
            child: Container(
              width: 360, height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.primary.withValues(alpha: .12), Colors.transparent]),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -180, left: -120,
          child: IgnorePointer(
            child: Container(
              width: 380, height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.accent.withValues(alpha: .07), Colors.transparent]),
              ),
            ),
          ),
        ),
        IndexedStack(index: _selectedIndex, children: _screens),
        Positioned(
          top: 0, left: 0, right: 0,
          child: IgnorePointer(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, AppColors.primary.withValues(alpha: .30), Colors.transparent]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isTablet) {
    final links = _pinnedIndexes
        .map((index) => _allScreens.firstWhere((link) => link.screenIndex == index))
        .toList();
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: isTablet ? 84 : 74,
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 12 : 5, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.cardBackground.withValues(alpha: .96),
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .45), blurRadius: 28, offset: const Offset(0, -8))],
          ),
          child: Row(
            children: [
              ...links.map((link) => Expanded(child: _buildBottomItem(link, isTablet))),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showAllScreens(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.grid_view_rounded, color: AppColors.textSecondary, size: isTablet ? 23 : 21),
                      const SizedBox(height: 4),
                      Text('More', style: GoogleFonts.inter(fontSize: isTablet ? 10 : 9, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(_ScreenLink link, bool isTablet) {
    final selected = _selectedIndex == link.screenIndex;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectScreen(link.screenIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: .12) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: selected ? AppColors.primary.withValues(alpha: .22) : Colors.transparent),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.08 : 1,
              duration: const Duration(milliseconds: 240),
              child: Icon(link.icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: isTablet ? 23 : 21),
            ),
            const SizedBox(height: 4),
            Text(
              link.label == 'Progress Graph' ? 'Progress' : link.label == 'Study Consistency' ? 'Consistency' : link.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: isTablet ? 10 : 9,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    final links = _pinnedIndexes
        .map((index) => _allScreens.firstWhere((link) => link.screenIndex == index))
        .toList();
    return Container(
      width: 252,
      decoration: BoxDecoration(
        color: AppColors.cardBackground.withValues(alpha: .78),
        border: Border(right: BorderSide(color: AppColors.glassBorder)),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 26),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 45, height: 45,
                        decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
                        child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 23),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('StudyX', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -.5)),
                            Text('STUDY • FOCUS • GROW', style: GoogleFonts.inter(fontSize: 7.5, fontWeight: FontWeight.w700, letterSpacing: 1.1, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('YOUR SHORTCUTS', style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      ...links.map(_buildDesktopItem),
                      const SizedBox(height: 8),
                      _buildCustomizeDesktopItem(),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: .35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, size: 18, color: AppColors.accent),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('StudyX', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              Text('Personal study space', style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopItem(_ScreenLink link) {
    final selected = _selectedIndex == link.screenIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectScreen(link.screenIndex),
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withValues(alpha: .13) : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: selected ? AppColors.primary.withValues(alpha: .25) : Colors.transparent),
            ),
            child: Row(
              children: [
                Icon(link.icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text(link.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizeDesktopItem() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showAllScreens(customize: true),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.accent, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Customize shortcuts', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700))),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScreenLink {
  final String label;
  final IconData icon;
  final int screenIndex;
  final String description;

  const _ScreenLink(this.label, this.icon, this.screenIndex, this.description);
}
