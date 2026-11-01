
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

import 'providers/ai_provider.dart';
import 'providers/backlog_provider.dart';
import 'providers/distraction_provider.dart';
import 'providers/exam_provider.dart';
import 'providers/habit_provider.dart';
import 'providers/planner_provider.dart';
import 'providers/study_session_provider.dart';
import 'providers/syllabus_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/background_study_timer.dart';
import 'services/notification_manager.dart';
import 'services/notification_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
if (!kIsWeb) {
  FlutterForegroundTask.initCommunicationPort();
  BackgroundStudyTimer.initialize();
}
  final prefs = await SharedPreferences.getInstance();

  if (!kIsWeb) {
  await NotificationService.instance.initialize();
}

  final studySessionProvider = StudySessionProvider(prefs);
  final userProvider = UserProvider(prefs);
  final syllabusProvider = SyllabusProvider(prefs);
  final taskProvider = TaskProvider(prefs);
  final backlogProvider = BacklogProvider(prefs);
  final aiProvider = AiProvider();

  final examProvider = ExamProvider(
    prefs: prefs,
    syllabusProvider: syllabusProvider,
  );

  final distractionProvider = DistractionProvider(prefs);

  // Load existing study sessions.
  await studySessionProvider.loadSessions();

  // Start existing notifications.
 if (!kIsWeb && userProvider.isUserDone) {
  NotificationManager.instance.start(
      prefs: prefs,
      userProvider: userProvider,
      taskProvider: taskProvider,
      studySessionProvider: studySessionProvider,
      syllabusProvider: syllabusProvider,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<HabitProvider>(
          create: (_) => HabitProvider(),
        ),

        ChangeNotifierProvider<PlannerProvider>(
          create: (_) => PlannerProvider(),
        ),

        ChangeNotifierProvider<StudySessionProvider>.value(
          value: studySessionProvider,
        ),

        ChangeNotifierProvider<UserProvider>.value(
          value: userProvider,
        ),

        ChangeNotifierProvider<SyllabusProvider>.value(
          value: syllabusProvider,
        ),

        ChangeNotifierProvider<TaskProvider>.value(
          value: taskProvider,
        ),

        ChangeNotifierProvider<BacklogProvider>.value(
          value: backlogProvider,
        ),

        ChangeNotifierProvider<AiProvider>.value(
          value: aiProvider,
        ),

        ChangeNotifierProvider<ExamProvider>.value(
          value: examProvider,
        ),

        ChangeNotifierProvider<DistractionProvider>.value(
          value: distractionProvider,
        ),
      ],
      child: const StudyXApp(),
    ),
  );
}
