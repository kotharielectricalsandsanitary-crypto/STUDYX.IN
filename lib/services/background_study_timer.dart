import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Background study timer for StudyX (flutter_foreground_task 11.0.3).
///
/// Elapsed time is calculated from a persisted base duration and start
/// timestamp. Pause/resume/reset wait for the service to persist their state.
class BackgroundStudyTimer {
  BackgroundStudyTimer._();

  static const int serviceId = 731;

  static const String _elapsedKey = 'study_timer_elapsed_seconds';
  static const String _startedAtKey = 'study_timer_started_at';
  static const String _runningKey = 'study_timer_running';
  static const String _finishedKey = 'study_timer_finished_seconds';

  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'studyx_focus_timer',
        channelName: 'StudyX Focus Timer',
        channelDescription: 'Shows your active study session.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<bool> requestNotificationPermission() async {
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission == NotificationPermission.granted) return true;

    final result = await FlutterForegroundTask.requestNotificationPermission();
    return result == NotificationPermission.granted;
  }

  /// Starts a fresh session or resumes the saved session.
  static Future<void> start() async {
    final granted = await requestNotificationPermission();
    if (!granted) {
      throw Exception('Allow notifications for the StudyX timer.');
    }

    if (await FlutterForegroundTask.isRunningService) {
      final running = await _readBool(_runningKey);
      if (!running) {
        FlutterForegroundTask.sendDataToTask({'action': 'resume'});
        await _waitForRunningState(true);
      }
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final savedElapsed = await _readInt(_elapsedKey);
    final savedStartedAt = await _readIntOrNull(_startedAtKey);
    final wasRunning = await _readBool(_runningKey);

    // If Android killed the service while it was running, recover elapsed
    // time from the previous start timestamp. A paused timer keeps its value.
    var elapsed = savedElapsed;
    if (wasRunning && savedStartedAt != null) {
      final additional = ((now - savedStartedAt) ~/ 1000)
          .clamp(0, 2147483647);
      elapsed += additional;
    }

    await FlutterForegroundTask.saveData(key: _elapsedKey, value: elapsed);
    await FlutterForegroundTask.saveData(key: _startedAtKey, value: now);
    await FlutterForegroundTask.saveData(key: _runningKey, value: true);
    await FlutterForegroundTask.removeData(key: _finishedKey);

    await FlutterForegroundTask.startService(
      serviceId: serviceId,
      notificationTitle: 'StudyX • Study session',
      notificationText: 'Focus timer is starting...',
      notificationButtons: const [
        NotificationButton(id: 'toggle', text: 'Pause'),
        NotificationButton(id: 'stop', text: 'Stop'),
      ],
      callback: studyXTimerCallback,
    );
  }

  static Future<void> pause() async {
    if (!await FlutterForegroundTask.isRunningService) {
      // If service is already gone, preserve any recoverable elapsed time.
      final elapsed = await getElapsedSeconds();
      await FlutterForegroundTask.saveData(key: _elapsedKey, value: elapsed);
      await FlutterForegroundTask.saveData(key: _runningKey, value: false);
      return;
    }

    if (await isTimerRunning()) {
      FlutterForegroundTask.sendDataToTask({'action': 'pause'});
      await _waitForRunningState(false);
    }
  }

  static Future<void> resume() async {
    if (!await FlutterForegroundTask.isRunningService) {
      await start();
      return;
    }

    if (!await isTimerRunning()) {
      FlutterForegroundTask.sendDataToTask({'action': 'resume'});
      await _waitForRunningState(true);
    }
  }

  /// Stops the service and records the final duration for one-time retrieval.
  static Future<void> stop() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    FlutterForegroundTask.sendDataToTask({'action': 'stop'});
    await _waitForServiceStopped();
  }

  static Future<bool> isTimerRunning() async => _readBool(_runningKey);

  static Future<int> getElapsedSeconds() async {
    final elapsed = await _readInt(_elapsedKey);
    final running = await _readBool(_runningKey);
    final startedAt = await _readIntOrNull(_startedAtKey);

    if (!running || startedAt == null) return elapsed;
    final now = DateTime.now().millisecondsSinceEpoch;
    final additional = ((now - startedAt) ~/ 1000).clamp(0, 2147483647);
    return elapsed + additional;
  }

  /// Resets to zero and waits until the foreground service has stopped.
  static Future<void> reset() async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.sendDataToTask({'action': 'reset'});
      await _waitForServiceStopped();
    }

    await FlutterForegroundTask.saveData(key: _elapsedKey, value: 0);
    await FlutterForegroundTask.saveData(
      key: _startedAtKey,
      value: DateTime.now().millisecondsSinceEpoch,
    );
    await FlutterForegroundTask.saveData(key: _runningKey, value: false);
    await FlutterForegroundTask.removeData(key: _finishedKey);
  }

  /// Returns a completed session once, then clears it.
  static Future<int> takeFinishedSessionSeconds() async {
    final value = await _readInt(_finishedKey);
    await FlutterForegroundTask.removeData(key: _finishedKey);
    return value;
  }

  static String formatDuration(int seconds) {
    final safeSeconds = seconds < 0 ? 0 : seconds;
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final remainingSeconds = safeSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static Future<int> _readInt(String key) async {
    final value = await FlutterForegroundTask.getData(key: key);
    return value is int ? value : 0;
  }

  static Future<int?> _readIntOrNull(String key) async {
    final value = await FlutterForegroundTask.getData(key: key);
    return value is int ? value : null;
  }

  static Future<bool> _readBool(String key) async {
    return await FlutterForegroundTask.getData(key: key) == true;
  }

  static Future<void> _waitForRunningState(bool expected) async {
    final deadline = DateTime.now().add(const Duration(seconds: 3));
    while (DateTime.now().isBefore(deadline)) {
      if (await isTimerRunning() == expected) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    // The persisted state is authoritative after the wait; don't silently
    // claim the requested state was reached.
    if (await isTimerRunning() != expected) {
      throw Exception('The StudyX timer did not respond. Please try again.');
    }
  }

  static Future<void> _waitForServiceStopped() async {
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (DateTime.now().isBefore(deadline)) {
      if (!await FlutterForegroundTask.isRunningService) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (await FlutterForegroundTask.isRunningService) {
      throw Exception('The StudyX timer service did not stop in time.');
    }
  }
}

@pragma('vm:entry-point')
void studyXTimerCallback() {
  FlutterForegroundTask.setTaskHandler(StudyXTimerHandler());
}

class StudyXTimerHandler extends TaskHandler {
  int _elapsedSeconds = 0;
  int _startedAtMillis = 0;
  bool _isRunning = true;
  bool _finishing = false;
  bool _resetting = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final elapsed = await FlutterForegroundTask.getData(key: 'study_timer_elapsed_seconds');
    final startedAt = await FlutterForegroundTask.getData(key: 'study_timer_started_at');
    final running = await FlutterForegroundTask.getData(key: 'study_timer_running');

    _elapsedSeconds = elapsed is int ? elapsed : 0;
    _startedAtMillis = startedAt is int
        ? startedAt
        : timestamp.millisecondsSinceEpoch;
    _isRunning = running != false;
    await _updateNotification();
  }

  int _currentElapsed(DateTime now) {
    if (!_isRunning) return _elapsedSeconds;
    final additional = ((now.millisecondsSinceEpoch - _startedAtMillis) ~/ 1000)
        .clamp(0, 2147483647);
    return _elapsedSeconds + additional;
  }

  Future<void> _saveState() async {
    await FlutterForegroundTask.saveData(
      key: 'study_timer_elapsed_seconds', value: _elapsedSeconds);
    await FlutterForegroundTask.saveData(
      key: 'study_timer_started_at', value: _startedAtMillis);
    await FlutterForegroundTask.saveData(
      key: 'study_timer_running', value: _isRunning);
  }

  Future<void> _updateNotification() async {
    final seconds = _currentElapsed(DateTime.now());
    await FlutterForegroundTask.updateService(
      notificationTitle: 'StudyX • ${_isRunning ? 'Studying' : 'Paused'}',
      notificationText: '${BackgroundStudyTimer.formatDuration(seconds)} elapsed',
      notificationButtons: [
        NotificationButton(id: 'toggle', text: _isRunning ? 'Pause' : 'Resume'),
        const NotificationButton(id: 'stop', text: 'Stop'),
      ],
    );
    FlutterForegroundTask.sendDataToMain({
      'elapsedSeconds': seconds,
      'running': _isRunning,
    });
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_updateNotification());
  }

  @override
  void onReceiveData(Object data) {
    if (data is! Map) return;
    final action = data['action'];

    if (action == 'pause' && _isRunning) {
      _elapsedSeconds = _currentElapsed(DateTime.now());
      _isRunning = false;
      unawaited(_saveState().then((_) => _updateNotification()));
    } else if (action == 'resume' && !_isRunning) {
      _startedAtMillis = DateTime.now().millisecondsSinceEpoch;
      _isRunning = true;
      unawaited(_saveState().then((_) => _updateNotification()));
    } else if (action == 'stop' && !_finishing && !_resetting) {
      unawaited(_finish());
    } else if (action == 'reset' && !_finishing && !_resetting) {
      unawaited(_reset());
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'toggle') {
      onReceiveData({'action': _isRunning ? 'pause' : 'resume'});
    } else if (id == 'stop') {
      onReceiveData({'action': 'stop'});
    }
  }

  Future<void> _finish() async {
    _finishing = true;
    _elapsedSeconds = _currentElapsed(DateTime.now());
    _isRunning = false;
    await FlutterForegroundTask.saveData(
      key: 'study_timer_finished_seconds', value: _elapsedSeconds);
    await _saveState();
    await FlutterForegroundTask.stopService();
  }

  Future<void> _reset() async {
    _resetting = true;
    _elapsedSeconds = 0;
    _startedAtMillis = DateTime.now().millisecondsSinceEpoch;
    _isRunning = false;
    await FlutterForegroundTask.removeData(key: 'study_timer_finished_seconds');
    await _saveState();
    await FlutterForegroundTask.stopService();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    // If Android destroys the service unexpectedly, persist the current
    // elapsed value and running state. The next start() can recover time
    // from the saved timestamp if the timer had been running.
    if (_isRunning && !_finishing && !_resetting) {
      _elapsedSeconds = _currentElapsed(timestamp);
      _startedAtMillis = timestamp.millisecondsSinceEpoch;
    }
    await _saveState();
  }
}
