import 'dart:math' as math;
import 'package:flutter/material.dart';

class GoalMapScreen extends StatefulWidget {
  const GoalMapScreen({super.key});

  @override
  State<GoalMapScreen> createState() => _GoalMapScreenState();
}

class _GoalMapScreenState extends State<GoalMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Change this if you want a different default goal.
  String mainGoal = 'AIIMS Delhi';

  // Overall progress. This can later be connected to your real StudyX data.
  double progress = 0.38;

  final List<_GoalMilestone> milestones = [
    _GoalMilestone(
      title: 'Start Your Journey',
      subtitle: 'Build your study foundation',
      icon: Icons.rocket_launch_rounded,
      requiredProgress: 0.00,
    ),
    _GoalMilestone(
      title: 'Build Foundation',
      subtitle: 'Understand the basics',
      icon: Icons.menu_book_rounded,
      requiredProgress: 0.15,
    ),
    _GoalMilestone(
      title: 'Complete Syllabus',
      subtitle: 'Finish your planned chapters',
      icon: Icons.school_rounded,
      requiredProgress: 0.35,
    ),
    _GoalMilestone(
      title: 'Question Practice',
      subtitle: 'DPPs, questions and tests',
      icon: Icons.edit_note_rounded,
      requiredProgress: 0.50,
    ),
    _GoalMilestone(
      title: 'Revision',
      subtitle: 'Strengthen everything you learned',
      icon: Icons.refresh_rounded,
      requiredProgress: 0.65,
    ),
    _GoalMilestone(
      title: 'Mock Tests',
      subtitle: 'Test yourself under exam conditions',
      icon: Icons.timer_rounded,
      requiredProgress: 0.80,
    ),
    _GoalMilestone(
      title: 'Final Preparation',
      subtitle: 'You are almost there',
      icon: Icons.local_fire_department_rounded,
      requiredProgress: 0.92,
    ),
    _GoalMilestone(
      title: 'Goal Reached',
      subtitle: 'Your destination',
      icon: Icons.emoji_events_rounded,
      requiredProgress: 1.00,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get currentMilestoneIndex {
    int index = 0;

    for (int i = 0; i < milestones.length; i++) {
      if (progress >= milestones[i].requiredProgress) {
        index = i;
      }
    }

    return index;
  }

  String get progressText {
    return '${(progress * 100).round()}%';
  }

  void _showGoalDialog() {
    final controller = TextEditingController(text: mainGoal);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF17171D),
          title: const Text(
            'Change Main Goal',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your main goal',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(
                  color: Color(0xFF7C5CFC),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    mainGoal = controller.text.trim();
                  });
                }

                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showTodayMission() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111116),
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Mission",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Complete your work to move closer to $mainGoal.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 22),
                _missionTile(
                  Icons.menu_book_rounded,
                  'Study today\'s target',
                  true,
                ),
                _missionTile(
                  Icons.check_circle_outline_rounded,
                  'Complete your planned tasks',
                  true,
                ),
                _missionTile(
                  Icons.replay_rounded,
                  'Revise previous topics',
                  false,
                ),
                _missionTile(
                  Icons.quiz_rounded,
                  'Solve questions',
                  false,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Today\'s mission started. Keep moving. 🚀',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text(
                      'START TODAY',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
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

  Widget _missionTile(
    IconData icon,
    String title,
    bool completed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Row(
          children: [
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : icon,
              color: completed
                  ? const Color(0xFF5EE6A8)
                  : Colors.white.withValues(alpha: 0.55),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: completed ? 0.9 : 0.7,
                  ),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = milestones[currentMilestoneIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF09090D),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildGoalCard(),
            ),
            SliverToBoxAdapter(
              child: _buildTodayMovement(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                child: Row(
                  children: [
                    const Text(
                      'YOUR JOURNEY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      current.title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildJourney(),
            ),
            SliverToBoxAdapter(
              child: _buildBottomMessage(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFF15151C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: const Icon(
              Icons.map_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOAL MAP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your destination. Your journey.',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showGoalDialog,
            icon: const Icon(
              Icons.edit_rounded,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final glow =
              0.08 + (_animationController.value * 0.07);

          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF211B38),
                  Color(0xFF111117),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF7C5CFC).withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C5CFC).withValues(alpha: glow),
                  blurRadius: 35,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7C5CFC).withValues(alpha: 0.14),
                    border: Border.all(
                      color: const Color(0xFF7C5CFC).withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    color: Color(0xFFA993FF),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MAIN GOAL',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mainGoal,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  progressText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: Text(
                    'closer to your goal',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: const AlwaysStoppedAnimation(
                  Color(0xFF8A6CFF),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'START',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'DESTINATION',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayMovement() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: InkWell(
        onTap: _showTodayMission,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFF101015),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF5EE6A8).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF5EE6A8),
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S MOVEMENT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Complete today\'s mission to move forward.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white30,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJourney() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          milestones.length,
          (index) {
            final milestone = milestones[index];
            final isCompleted =
                progress >= milestone.requiredProgress;
            final isCurrent =
                index == currentMilestoneIndex &&
                !isCompleted;

            return _buildMilestone(
              milestone,
              index,
              isCompleted,
              isCurrent,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMilestone(
    _GoalMilestone milestone,
    int index,
    bool isCompleted,
    bool isCurrent,
  ) {
    final isLast = index == milestones.length - 1;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final pulse = isCurrent
            ? 0.12 + (_animationController.value * 0.12)
            : 0.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 66,
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? const Color(0xFF5EE6A8).withValues(alpha: 0.13)
                          : isCurrent
                              ? const Color(0xFF8A6CFF)
                                  .withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.035),
                      border: Border.all(
                        width: isCurrent ? 2 : 1,
                        color: isCompleted
                            ? const Color(0xFF5EE6A8)
                            : isCurrent
                                ? const Color(0xFF9B84FF)
                                : Colors.white.withValues(alpha: 0.09),
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: const Color(0xFF8A6CFF)
                                    .withValues(alpha: pulse),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : milestone.icon,
                      color: isCompleted
                          ? const Color(0xFF5EE6A8)
                          : isCurrent
                              ? const Color(0xFFA993FF)
                              : Colors.white30,
                      size: 22,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 82,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isCompleted
                          ? const Color(0xFF5EE6A8).withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.07),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? const Color(0xFF171522)
                      : Colors.white.withValues(alpha: 0.025),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isCurrent
                        ? const Color(0xFF8A6CFF).withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.055),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  milestone.title,
                                  style: TextStyle(
                                    color: isCompleted || isCurrent
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '${(milestone.requiredProgress * 100).round()}%',
                                style: TextStyle(
                                  color: isCompleted
                                      ? const Color(0xFF5EE6A8)
                                      : Colors.white24,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            milestone.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(
                                alpha: isCompleted || isCurrent
                                    ? 0.5
                                    : 0.28,
                              ),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomMessage() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF15121F),
              const Color(0xFF101014),
            ],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.flag_rounded,
              color: Color(0xFFA993FF),
              size: 28,
            ),
            const SizedBox(height: 10),
            const Text(
              'The destination stays the same.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Your daily work decides how fast you reach $mainGoal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalMilestone {
  final String title;
  final String subtitle;
  final IconData icon;
  final double requiredProgress;

  const _GoalMilestone({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.requiredProgress,
  });
}