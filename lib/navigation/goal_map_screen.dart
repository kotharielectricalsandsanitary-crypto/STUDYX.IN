import 'package:flutter/material.dart';

class GoalMapScreen extends StatelessWidget {
  const GoalMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF050505),
        elevation: 0,
        title: const Text(
          'Goal Map',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),

              const SizedBox(height: 24),

              _buildMainGoal(),

              const SizedBox(height: 24),

              const Text(
                'Your Journey',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 14),

              _buildJourneyStep(
                number: '01',
                icon: Icons.flag_rounded,
                title: 'Set Your Goal',
                description:
                    'Define the main goal you want to achieve.',
                completed: true,
              ),

              _buildConnector(),

              _buildJourneyStep(
                number: '02',
                icon: Icons.menu_book_rounded,
                title: 'Build Your Syllabus',
                description:
                    'Add subjects and chapters to your preparation.',
                completed: false,
              ),

              _buildConnector(),

              _buildJourneyStep(
                number: '03',
                icon: Icons.check_circle_rounded,
                title: 'Complete Your Tasks',
                description:
                    'Finish your daily study tasks consistently.',
                completed: false,
              ),

              _buildConnector(),

              _buildJourneyStep(
                number: '04',
                icon: Icons.auto_graph_rounded,
                title: 'Track Your Progress',
                description:
                    'Use analytics to understand your performance.',
                completed: false,
              ),

              _buildConnector(),

              _buildJourneyStep(
                number: '05',
                icon: Icons.emoji_events_rounded,
                title: 'Achieve Your Goal',
                description:
                    'Reach the destination you are working toward.',
                completed: false,
              ),

              const SizedBox(height: 28),

              _buildMotivationCard(),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your path starts here.',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Every completed step moves you closer to your main goal.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MAIN GOAL
  // ============================================================

  Widget _buildMainGoal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A1A35),
            Color(0xFF101018),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF6366F1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1)
                  .withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: Color(0xFF818CF8),
              size: 36,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'MAIN GOAL',
            style: TextStyle(
              color: Color(0xFF818CF8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Your Future',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Stay consistent. Complete the steps. Reach the destination.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // JOURNEY STEP
  // ============================================================

  Widget _buildJourneyStep({
    required String number,
    required IconData icon,
    required String title,
    required String description,
    required bool completed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: completed
              ? const Color(0xFF6366F1)
                  .withValues(alpha: 0.35)
              : Colors.white10,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Number
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: completed
                  ? const Color(0xFF6366F1)
                      .withValues(alpha: 0.16)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: completed
                      ? const Color(0xFF818CF8)
                      : Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: completed
                  ? const Color(0xFF818CF8)
                  : Colors.white54,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    if (completed)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF818CF8),
                        size: 20,
                      ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 12,
                    height: 1.4,
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
  // CONNECTOR
  // ============================================================

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 40,
      ),
      child: Container(
        width: 2,
        height: 28,
        color: const Color(0xFF6366F1)
            .withValues(alpha: 0.25),
      ),
    );
  }

  // ============================================================
  // MOTIVATION
  // ============================================================

  Widget _buildMotivationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFF818CF8),
              size: 27,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep Moving',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'You do not need to finish everything today. '
                  'You only need to complete the next step.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}