
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DistractionBlockerScreen extends StatefulWidget {
  const DistractionBlockerScreen({super.key});

  @override
  State<DistractionBlockerScreen> createState() =>
      _DistractionBlockerScreenState();
}

class _DistractionBlockerScreenState
    extends State<DistractionBlockerScreen> {
  static const MethodChannel _channel =
      MethodChannel('studyx/distraction_blocker');

  static const String _enabledKey =
      'distraction_blocker_enabled';

  static const String _limitKey =
      'distraction_daily_limit';

  bool _enabled = false;
  bool _permissionGranted = false;
  int _dailyLimit = 30;
  int _usedMinutes = 0;

  final List<_BlockedApp> _apps = const [
    _BlockedApp(
      name: 'Instagram',
      packageName: 'com.instagram.android',
      icon: Icons.camera_alt_rounded,
    ),
    _BlockedApp(
      name: 'Snapchat',
      packageName: 'com.snapchat.android',
      icon: Icons.chat_bubble_rounded,
    ),
    _BlockedApp(
      name: 'YouTube',
      packageName: 'com.google.android.youtube',
      icon: Icons.play_circle_fill_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final enabled = prefs.getBool(_enabledKey) ?? false;
    final limit = prefs.getInt(_limitKey) ?? 30;

    int used = 0;
    bool permission = false;

    try {
      permission =
          await _channel.invokeMethod<bool>('hasUsageAccess') ?? false;

      used =
          await _channel.invokeMethod<int>('getTodayUsage') ?? 0;
    } catch (_) {
      // Android native blocker is not available.
      // UI continues to work without crashing.
    }

    if (!mounted) return;

    setState(() {
      _enabled = enabled;
      _dailyLimit = limit.clamp(20, 40).toInt();
      _permissionGranted = permission;
      _usedMinutes = used;
    });
  }

  Future<void> _saveEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_enabledKey, value);

    if (value) {
      await _startBlocker();
    } else {
      await _stopBlocker();
    }

    if (!mounted) return;

    setState(() {
      _enabled = value;
    });
  }

  Future<void> _startBlocker() async {
    try {
      await _channel.invokeMethod(
        'startBlocker',
        {
          'limitMinutes': _dailyLimit,
        },
      );
    } catch (_) {
      // Native blocker may not be available.
    }
  }

  Future<void> _stopBlocker() async {
    try {
      await _channel.invokeMethod('stopBlocker');
    } catch (_) {
      // Native blocker may not be available.
    }
  }

  Future<void> _requestUsagePermission() async {
    try {
      await _channel.invokeMethod('openUsageAccessSettings');
    } catch (_) {
      // Not available on web/non-Android.
    }

    await Future.delayed(
      const Duration(milliseconds: 700),
    );

    await _loadSettings();
  }

  Future<void> _setLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(
      _limitKey,
      value,
    );

    if (_enabled) {
      await _startBlocker();
    }

    if (!mounted) return;

    setState(() {
      _dailyLimit = value;
    });
  }

  Future<void> _showLimitPicker() async {
    int selected = _dailyLimit;

    final result = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  10,
                  24,
                  30,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily reels limit',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose how much entertainment time '
                      'you want each day.',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$selected minutes',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      min: 20,
                      max: 40,
                      divisions: 4,
                      value: selected.toDouble(),
                      label: '$selected min',
                      onChanged: (value) {
                        setModalState(() {
                          selected = value.round();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            selected,
                          );
                        },
                        child: const Text(
                          'Save limit',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      await _setLimit(result);
    }
  }

  double get _progress {
    if (_dailyLimit <= 0) return 0;

    return (_usedMinutes / _dailyLimit)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  int get _remaining {
    final remaining = _dailyLimit - _usedMinutes;

    return remaining < 0 ? 0 : remaining;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Distraction Blocker',
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSettings,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildHeroCard(theme),
            const SizedBox(height: 18),
            _buildUsageCard(theme),
            const SizedBox(height: 18),
            _buildPermissionCard(theme),
            const SizedBox(height: 18),
            _buildLimitCard(theme),
            const SizedBox(height: 18),
            _buildAppsCard(theme),
            const SizedBox(height: 18),
            _buildHowItWorksCard(theme),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary
                    .withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shield_rounded,
                size: 34,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Stay focused',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'StudyX helps you control entertainment '
              'time so your study sessions stay on track.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Distraction blocker',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                _enabled
                    ? 'Protection is active'
                    : 'Protection is turned off',
              ),
              value: _enabled,
              onChanged:
                  _permissionGranted ? _saveEnabled : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Today',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.end,
              children: [
                Text(
                  '$_usedMinutes',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(
                    bottom: 7,
                    left: 6,
                  ),
                  child: Text('min used'),
                ),
                const Spacer(),
                Text(
                  '$_remaining min left',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: _progress,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Limit: $_dailyLimit minutes/day',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(ThemeData theme) {
    final granted = _permissionGranted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              granted
                  ? Icons.check_circle_rounded
                  : Icons.warning_rounded,
              color: granted
                  ? Colors.green
                  : Colors.orange,
              size: 30,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    granted
                        ? 'Usage access enabled'
                        : 'Usage access required',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    granted
                        ? 'StudyX can monitor supported app usage.'
                        : 'Android requires permission to monitor app usage.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (!granted)
              TextButton(
                onPressed: _requestUsagePermission,
                child: const Text('Enable'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitCard(ThemeData theme) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.timer_rounded,
        ),
        title: const Text(
          'Daily entertainment limit',
        ),
        subtitle: Text(
          '$_dailyLimit minutes',
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
        onTap: _showLimitPicker,
      ),
    );
  }

  Widget _buildAppsCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Column(
          children: [
            const ListTile(
              leading: Icon(
                Icons.block_rounded,
              ),
              title: Text(
                'Protected apps',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Entertainment apps monitored by StudyX',
              ),
            ),
            ..._apps.map(
              (app) => ListTile(
                leading: CircleAvatar(
                  child: Icon(app.icon),
                ),
                title: Text(app.name),
                subtitle: Text(
                  app.packageName,
                ),
                trailing: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard(
    ThemeData theme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'How it works',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(
              Icons.analytics_rounded,
              'Tracks daily usage',
            ),
            _infoRow(
              Icons.timer_rounded,
              'Uses your 20–40 minute limit',
            ),
            _infoRow(
              Icons.school_rounded,
              'Encourages you back to studying',
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}

class _BlockedApp {
  final String name;
  final String packageName;
  final IconData icon;

  const _BlockedApp({
    required this.name,
    required this.packageName,
    required this.icon,
  });
}
