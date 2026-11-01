import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/study_session_provider.dart';

class StudyTimerCard extends StatefulWidget {
  const StudyTimerCard({super.key});

  @override
  State<StudyTimerCard> createState() => _StudyTimerCardState();
}

class _StudyTimerCardState extends State<StudyTimerCard> {
  Timer? timer;

  Duration elapsed = Duration.zero;

  bool isRunning = false;

  DateTime? startTime;

  // ------------------------------------------------------------
  // STORAGE KEYS
  // ------------------------------------------------------------

  static const String _elapsedKey = 'study_timer_elapsed';
  static const String _runningKey = 'study_timer_running';
  static const String _startTimeKey = 'study_timer_start_time';

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadTimer();
  }

  // ------------------------------------------------------------
  // LOAD SAVED TIMER
  // ------------------------------------------------------------

  Future<void> _loadTimer() async {
    final prefs = await SharedPreferences.getInstance();

    final savedElapsed = prefs.getInt(_elapsedKey) ?? 0;
    final savedRunning = prefs.getBool(_runningKey) ?? false;
    final savedStartTime = prefs.getInt(_startTimeKey);

    Duration loadedElapsed =
        Duration(seconds: savedElapsed);

    if (savedRunning && savedStartTime != null) {
      final start =
          DateTime.fromMillisecondsSinceEpoch(
        savedStartTime,
      );

      final now = DateTime.now();

      final additionalTime =
          now.difference(start);

      loadedElapsed =
          loadedElapsed + additionalTime;

      startTime = start;
      isRunning = true;
    }

    if (!mounted) return;

    setState(() {
      elapsed = loadedElapsed;
    });

    if (isRunning) {
      _startTicker();
    }
  }

  // ------------------------------------------------------------
  // SAVE TIMER
  // ------------------------------------------------------------

  Future<void> _saveTimer() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _elapsedKey,
      elapsed.inSeconds,
    );

    await prefs.setBool(
      _runningKey,
      isRunning,
    );

    if (isRunning && startTime != null) {
      await prefs.setInt(
        _startTimeKey,
        startTime!.millisecondsSinceEpoch,
      );
    } else {
      await prefs.remove(_startTimeKey);
    }
  }

  // ------------------------------------------------------------
  // START
  // ------------------------------------------------------------

  Future<void> startTimer() async {
    if (isRunning) return;

    startTime = DateTime.now();

    isRunning = true;

    await _saveTimer();

    _startTicker();

    if (mounted) {
      setState(() {});
    }
  }

  // ------------------------------------------------------------
  // TIMER TICKER
  // ------------------------------------------------------------

  void _startTicker() {
    timer?.cancel();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        if (isRunning && startTime != null) {
          final now = DateTime.now();

          final currentElapsed =
              now.difference(startTime!);

          setState(() {
            elapsed = currentElapsed;
          });
        }
      },
    );
  }

  // ------------------------------------------------------------
  // PAUSE
  // ------------------------------------------------------------

  Future<void> pauseTimer() async {
    if (!isRunning) return;

    if (startTime != null) {
      final additionalTime =
          DateTime.now().difference(startTime!);

      elapsed = elapsed + additionalTime;
    }

    timer?.cancel();

    timer = null;

    isRunning = false;

    startTime = null;

    await _saveTimer();

    if (mounted) {
      setState(() {});
    }
  }

  // ------------------------------------------------------------
  // RESET
  // ------------------------------------------------------------

  Future<void> resetTimer() async {
    timer?.cancel();

    timer = null;

    elapsed = Duration.zero;

    isRunning = false;

    startTime = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_elapsedKey);
    await prefs.remove(_runningKey);
    await prefs.remove(_startTimeKey);

    if (mounted) {
      setState(() {});
    }
  }

  // ------------------------------------------------------------
  // DONE
  // ------------------------------------------------------------

  Future<void> doneTimer() async {
    if (elapsed.inSeconds <= 0) return;

    if (isRunning && startTime != null) {
      elapsed =
          elapsed + DateTime.now().difference(startTime!);
    }

    timer?.cancel();

    timer = null;

    isRunning = false;

    startTime = null;

    final seconds = elapsed.inSeconds;

    if (mounted) {
      setState(() {});
    }

    // ----------------------------------------------------------
    // SAVE STUDY SESSION TO GRAPH
    // ----------------------------------------------------------

    await context
        .read<StudySessionProvider>()
        .addSession(seconds);

    // ----------------------------------------------------------
    // CLEAR ACTIVE TIMER
    // ----------------------------------------------------------

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_elapsedKey);
    await prefs.remove(_runningKey);
    await prefs.remove(_startTimeKey);

    final formatted = formatTime();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Study Session Complete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'You studied for $formatted.',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  elapsed = Duration.zero;
                });
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------------------
  // FORMAT TIME
  // ------------------------------------------------------------

  String formatTime() {
    final hours =
        elapsed.inHours.toString().padLeft(2, '0');

    final minutes =
        (elapsed.inMinutes % 60)
            .toString()
            .padLeft(2, '0');

    final seconds =
        (elapsed.inSeconds % 60)
            .toString()
            .padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF191919),
            Color(0xFF0D0D0D),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white10,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 25,
            spreadRadius: 0,
            offset: Offset(0, 10),
            color: Colors.black54,
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: Color(0xFF818CF8),
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Study Session',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Text(
            formatTime(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),

          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: resetTimer,
                  icon: const Icon(
                    Icons.refresh,
                  ),
                  label: const Text('Reset'),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      isRunning ? pauseTimer : startTimer,
                  icon: Icon(
                    isRunning
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    isRunning
                        ? 'Pause'
                        : 'Start',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed:
                  elapsed.inSeconds > 0
                      ? doneTimer
                      : null,
              icon: const Icon(
                Icons.check_circle_outline,
              ),
              label: const Text(
                'Done',
              ),
            ),
          ),
        ],
      ),
    );
  }
}