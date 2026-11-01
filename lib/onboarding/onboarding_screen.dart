import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/navigation_screen.dart';
import '../providers/study_session_provider.dart';
import '../providers/syllabus_provider.dart';
import '../providers/task_provider.dart';
import '../providers/user_provider.dart';
import '../services/notification_manager.dart';
import '../services/notification_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController pageController = PageController();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController goalController =
      TextEditingController();

  final TextEditingController hoursController =
      TextEditingController();

  int currentPage = 0;
  bool finishing = false;

  @override
  void dispose() {
    pageController.dispose();
    nameController.dispose();
    goalController.dispose();
    hoursController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (finishing) return;

    if (currentPage == 0 &&
        nameController.text.trim().isEmpty) {
      showError('Please enter your name.');
      return;
    }

    if (currentPage == 1 &&
        goalController.text.trim().isEmpty) {
      showError('Please enter your exam or goal.');
      return;
    }

    if (currentPage == 2) {
      finishOnboarding();
      return;
    }

    setState(() {
      currentPage++;
    });

    pageController.animateToPage(
      currentPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void previousPage() {
    if (currentPage == 0 || finishing) return;

    setState(() {
      currentPage--;
    });

    pageController.animateToPage(
      currentPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> finishOnboarding() async {
    if (finishing) return;

    final hoursText = hoursController.text.trim();
    final hours = double.tryParse(hoursText);

    if (hours == null || hours <= 0) {
      showError('Please enter a valid study goal.');
      return;
    }

    setState(() {
      finishing = true;
    });

    try {
      // SAVE USER DATA
      await context.read<UserProvider>().saveUser(
            userName: nameController.text.trim(),
            userGoal: goalController.text.trim(),
            studyHours: hours,
          );

      if (!mounted) return;

      // ASK NOTIFICATION PERMISSION
      await NotificationService.instance.requestPermission();

      if (!mounted) return;

      // GET PREFERENCES
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      // START NOTIFICATION MANAGER
      //
      // IMPORTANT:
      // Do NOT add "await" here because start() returns void.
      NotificationManager.instance.start(
        prefs: prefs,
        userProvider: context.read<UserProvider>(),
        taskProvider: context.read<TaskProvider>(),
        studySessionProvider:
            context.read<StudySessionProvider>(),
        syllabusProvider:
            context.read<SyllabusProvider>(),
      );

      if (!mounted) return;

      // OPEN MAIN APP
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const NavigationScreen(),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Onboarding error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        finishing = false;
      });

      showError(
        'Something went wrong. Please try again.',
      );
    }
  }

  void showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 25),

            // PROGRESS BAR
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
              ),
              child: Row(
                children: List.generate(
                  3,
                  (index) {
                    return Expanded(
                      child: Container(
                        height: 5,
                        margin: EdgeInsets.only(
                          right: index == 2 ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: index <= currentPage
                              ? const Color(0xFF6366F1)
                              : Colors.white12,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // ONBOARDING PAGES
            Expanded(
              child: PageView(
                controller: pageController,
                physics:
                    const NeverScrollableScrollPhysics(),
                children: [
                  buildNamePage(),
                  buildGoalPage(),
                  buildHoursPage(),
                ],
              ),
            ),

            // NAVIGATION BUTTONS
            Padding(
              padding: const EdgeInsets.all(25),
              child: Row(
                children: [
                  if (currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            finishing ? null : previousPage,
                        child: const Text('Back'),
                      ),
                    ),

                  if (currentPage > 0)
                    const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          finishing ? null : nextPage,
                      child: finishing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              currentPage == 2
                                  ? 'Start Studying'
                                  : 'Continue',
                            ),
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

  // NAME PAGE
  Widget buildNamePage() {
    return buildPage(
      icon: Icons.person,
      title: 'What should we call you?',
      subtitle:
          'Let’s personalize your StudyX experience.',
      child: buildTextField(
        controller: nameController,
        hint: 'Your name',
        icon: Icons.person_outline,
      ),
    );
  }

  // GOAL PAGE
  Widget buildGoalPage() {
    return buildPage(
      icon: Icons.flag,
      title: 'What are you preparing for?',
      subtitle:
          'Enter your exam or main study goal.',
      child: buildTextField(
        controller: goalController,
        hint: 'Example: NEET 2027',
        icon: Icons.flag_outlined,
      ),
    );
  }

  // STUDY HOURS PAGE
  Widget buildHoursPage() {
    return buildPage(
      icon: Icons.timer,
      title: 'How many hours do you study?',
      subtitle:
          'Set your daily study target.',
      child: buildTextField(
        controller: hoursController,
        hint: 'Example: 6',
        icon: Icons.access_time,
        keyboardType:
            const TextInputType.numberWithOptions(
          decimal: true,
        ),
      ),
    );
  }

  // COMMON PAGE LAYOUT
  Widget buildPage({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),

          Icon(
            icon,
            size: 60,
            color: const Color(0xFF6366F1),
          ),

          const SizedBox(height: 30),

          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 35),

          child,
        ],
      ),
    );
  }

  // COMMON TEXT FIELD
  Widget buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Colors.white38),
        prefixIcon: Icon(
          icon,
          color: Colors.white54,
        ),
        filled: true,
        fillColor: Colors.white12,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}