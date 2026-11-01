import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'goal_map_screen.dart';

import '../screens/tasks_screen.dart';
import '../screens/subject_detail_screen.dart';
import '../screens/graph_screen.dart';
import '../screens/profile_screen.dart';

import '../providers/syllabus_provider.dart';
import '../providers/study_session_provider.dart';
import '../providers/user_provider.dart';

import '../widgets/study_timer_card.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() =>
      _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int currentIndex = 0;

  static const Color background = Color(0xFF050505);
  static const Color card = Color(0xFF101010);
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);

  static const List<String> titles = [
    'Home',
    'Syllabus',
    'Tasks',
    'Graph',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildCurrentScreen(),
            ),
          ],
        ),
      ),
      floatingActionButton: currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: _showAddSubjectDialog,
              backgroundColor: primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Subject',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[currentIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _headerSubtitle(),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _headerSubtitle() {
    switch (currentIndex) {
      case 1:
        return 'Track your syllabus step by step.';
      case 2:
        return 'Complete your tasks and stay consistent.';
      case 3:
        return 'See your study progress and analytics.';
      case 4:
        return 'Manage your StudyX profile.';
      default:
        return 'Build your future, one session at a time.';
    }
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return NavigationBar(
      backgroundColor: const Color(0xFF0B0B0B),
      indicatorColor: primary.withValues(alpha: 0.20),
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          currentIndex = index;
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Syllabus',
        ),
        NavigationDestination(
          icon: Icon(Icons.check_circle_outline),
          selectedIcon: Icon(Icons.check_circle),
          label: 'Tasks',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: 'Graph',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  // ============================================================
  // SCREEN ROUTER
  // ============================================================

  Widget _buildCurrentScreen() {
    switch (currentIndex) {
      case 0:
        return _buildHome();

      case 1:
        return _buildSyllabus();

      case 2:
        return const TasksScreen();

      case 3:
        return const GraphScreen();

      case 4:
        return const ProfileScreen();

      default:
        return _buildHome();
    }
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget _buildHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 15, 22, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudyTimerCard(),

          const SizedBox(height: 20),

          const Text(
            "Today's Progress",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildProgressCard(),

          const SizedBox(height: 22),

          const Text(
            'Your Journey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildGoalMapCard(),

          const SizedBox(height: 22),

          const Text(
            'StudyX Tools',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _buildFeatureGrid(),

          const SizedBox(height: 22),

          const Text(
            'Quick Access',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickCard(
                  Icons.menu_book,
                  'Syllabus',
                  () {
                    setState(() {
                      currentIndex = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickCard(
                  Icons.check_circle,
                  'Tasks',
                  () {
                    setState(() {
                      currentIndex = 2;
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildQuickCard(
                  Icons.bar_chart,
                  'Graph',
                  () {
                    setState(() {
                      currentIndex = 3;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickCard(
                  Icons.person,
                  'Profile',
                  () {
                    setState(() {
                      currentIndex = 4;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FEATURE GRID
  // ============================================================

  Widget _buildFeatureGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.calendar_today_rounded,
                title: 'Today Plan',
                subtitle: 'What to study today',
                onTap: () {
                  _openFeature(
                    'Today Plan',
                    Icons.calendar_today_rounded,
                    'Your personalized study plan will appear here.',
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.backpack_rounded,
                title: 'Backlog',
                subtitle: 'Clear unfinished work',
                onTap: () {
                  _openFeature(
                    'Backlog',
                    Icons.backpack_rounded,
                    'Your unfinished chapters and tasks will appear here.',
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.psychology_rounded,
                title: 'Mastery',
                subtitle: 'Chapter strength',
                onTap: () {
                  _openFeature(
                    'Chapter Mastery',
                    Icons.psychology_rounded,
                    'Your chapter mastery levels will appear here.',
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.analytics_rounded,
                title: 'Analytics',
                subtitle: 'Study performance',
                onTap: () {
                  _openFeature(
                    'Analytics',
                    Icons.analytics_rounded,
                    'Detailed study analytics will appear here.',
                  );
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.timer_outlined,
                title: 'Exam',
                subtitle: 'Countdown to exam',
                onTap: () {
                  _openFeature(
                    'Exam Countdown',
                    Icons.timer_outlined,
                    'Your exam countdown will appear here.',
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeatureCard(
                icon: Icons.emoji_events_outlined,
                title: 'Achievements',
                subtitle: 'Your milestones',
                onTap: () {
                  _openFeature(
                    'Achievements',
                    Icons.emoji_events_outlined,
                    'Your StudyX achievements will appear here.',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // FEATURE CARD
  // ============================================================

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 125,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: primaryLight,
                  size: 23,
                ),
              ),

              const Spacer(),

              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FEATURE PLACEHOLDER
  // ============================================================

  void _openFeature(
    String title,
    IconData icon,
    String description,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FeaturePlaceholderScreen(
          title: title,
          icon: icon,
          description: description,
        ),
      ),
    );
  }

  // ============================================================
  // GOAL MAP
  // ============================================================

  Widget _buildGoalMapCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GoalMapScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF17172A),
                Color(0xFF101018),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: primary.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: primaryLight,
                  size: 31,
                ),
              ),

              const SizedBox(width: 15),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal Map',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Follow your path to your main goal.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: primaryLight,
                          size: 15,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Open your journey',
                          style: TextStyle(
                            color: primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white38,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TODAY PROGRESS
  // ============================================================

  Widget _buildProgressCard() {
    return Consumer2<StudySessionProvider, UserProvider>(
      builder: (
        context,
        sessionProvider,
        userProvider,
        child,
      ) {
        final today = sessionProvider.hoursForDate(
          DateTime.now(),
        );

        final goal = userProvider.dailyHours;

        double progress = 0;

        if (goal > 0) {
          progress = today / goal;
        }

        progress = progress.clamp(0.0, 1.0);

        final percentage = (progress * 100).round();

        final todayDuration = Duration(
          seconds: (today * 3600).round(),
        );

        final todayHours = todayDuration.inHours;
        final todayMinutes = todayDuration.inMinutes % 60;

        final goalText = goal % 1 == 0
            ? goal.toInt().toString()
            : goal.toStringAsFixed(1);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white10,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 105,
                height: 105,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 105,
                      height: 105,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 9,
                        backgroundColor: Colors.white10,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          primary,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Today',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 22),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Study Goal',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${todayHours}h '
                      '${todayMinutes.toString().padLeft(2, '0')}m '
                      '/ ${goalText}h',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      today <= 0
                          ? 'Start your first study session today.'
                          : percentage >= 100
                              ? 'Daily goal completed! 🎉'
                              : 'Keep going. You are making progress.',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // QUICK CARD
  // ============================================================

  Widget _buildQuickCard(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 115,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white10,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: primaryLight,
                size: 28,
              ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SYLLABUS
  // ============================================================

  Widget _buildSyllabus() {
    return Consumer<SyllabusProvider>(
      builder: (
        context,
        provider,
        child,
      ) {
        final subjects = provider.subjects;

        if (subjects.isEmpty) {
          return _buildEmptySyllabus();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            110,
          ),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final subject = subjects[index];

            return _buildSubjectCard(subject);
          },
        );
      },
    );
  }

  // ============================================================
  // EMPTY SYLLABUS
  // ============================================================

  Widget _buildEmptySyllabus() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: primaryLight,
                size: 44,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Your Syllabus',
              style: TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Add your subjects and chapters\n'
              'to start tracking your preparation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 25),

            ElevatedButton.icon(
              onPressed: _showAddSubjectDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Subject'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUBJECT CARD
  // ============================================================

  Widget _buildSubjectCard(Subject subject) {
    final progress = subject.progress;

    final completedChapters = subject.chapters
        .where(
          (chapter) => chapter.isCompleted,
        )
        .length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubjectDetailScreen(
                subjectId: subject.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: primaryLight,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '${subject.chapters.length} chapters • '
                          '$completedChapters completed',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    color: const Color(0xFF1B1B1B),
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.white54,
                    ),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteSubject(
                          subject.id,
                          subject.name,
                        );
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Delete Subject',
                          style: TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.white10,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(
                          primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
  // ADD SUBJECT
  // ============================================================

  void _showAddSubjectDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Add Subject',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Example: Biology',
              hintStyle: const TextStyle(
                color: Colors.white38,
              ),
              prefixIcon: const Icon(
                Icons.book_outlined,
                color: primaryLight,
              ),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop();
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();

                if (name.isEmpty) {
                  return;
                }

                final syllabusProvider = context.read<SyllabusProvider>();
                Navigator.of(dialogContext, rootNavigator: true).pop();

                await syllabusProvider.addSubject(name);
              },
              child: const Text('Add Subject'),
            ),
          ],
        );
      },
    ).then((_) {
      controller.dispose();
    });
  }

  // ============================================================
  // DELETE SUBJECT
  // ============================================================

  void _deleteSubject(
    String subjectId,
    String subjectName,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Delete Subject?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Delete "$subjectName" and all its chapters?',
            style: const TextStyle(
              color: Colors.white60,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop();
              },
              child: const Text('Cancel'),
            ),

            TextButton(
              onPressed: () async {
                final syllabusProvider = context.read<SyllabusProvider>();
                Navigator.of(dialogContext, rootNavigator: true).pop();

                await syllabusProvider.deleteSubject(subjectId);
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ================================================================
// TEMPORARY FEATURE SCREEN
// ================================================================

class _FeaturePlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;

  const _FeaturePlaceholderScreen({
    required this.title,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6366F1);
    const primaryLight = Color(0xFF818CF8);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  icon,
                  color: primaryLight,
                  size: 48,
                ),
              ),

              const SizedBox(height: 25),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}