import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/study_session_provider.dart';
import '../providers/syllabus_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _nameKey = 'studyx_profile_name';
  static const String _goalKey = 'studyx_profile_goal';
  static const String _hoursKey = 'studyx_daily_goal_hours';

  String _name = 'Student';
  String _goal = 'NEET Preparation';
  double _dailyHours = 6;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _name = prefs.getString(_nameKey) ?? 'Student';
      _goal = prefs.getString(_goalKey) ?? 'NEET Preparation';
      _dailyHours = prefs.getDouble(_hoursKey) ?? 6;
      _loading = false;
    });
  }

  Future<void> _saveProfile({
    required String name,
    required String goal,
    required double hours,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_nameKey, name);
    await prefs.setString(_goalKey, goal);
    await prefs.setDouble(_hoursKey, hours);

    if (!mounted) return;

    setState(() {
      _name = name;
      _goal = goal;
      _dailyHours = hours;
    });
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    final goalController = TextEditingController(text: _goal);

    double selectedHours = _dailyHours;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF151515),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: _inputDecoration(
                        'Your name',
                        Icons.person_outline,
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: goalController,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                      decoration: _inputDecoration(
                        'Exam / Goal',
                        Icons.flag_outlined,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Daily Study Goal',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${selectedHours.toStringAsFixed(1)} hours / day',
                      style: const TextStyle(
                        color: Color(0xFF818CF8),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Slider(
                      value: selectedHours,
                      min: 1,
                      max: 12,
                      divisions: 22,
                      activeColor: const Color(0xFF6366F1),
                      inactiveColor: Colors.white12,
                      onChanged: (value) {
                        setDialogState(() {
                          selectedHours = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final goal = goalController.text.trim();

                    if (name.isEmpty || goal.isEmpty) {
                      return;
                    }

                    await _saveProfile(
                      name: name,
                      goal: goal,
                      hours: selectedHours,
                    );

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      goalController.dispose();
    });
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Colors.white38,
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF818CF8),
      ),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6366F1),
        ),
      );
    }

    return Consumer2<StudySessionProvider, SyllabusProvider>(
      builder: (
        context,
        sessionProvider,
        syllabusProvider,
        child,
      ) {
        final totalHours = sessionProvider.totalHours;

        final subjects = syllabusProvider.subjects.length;

        final chapters = syllabusProvider.subjects.fold<int>(
          0,
          (sum, subject) => sum + subject.chapters.length,
        );

        final completedChapters =
            syllabusProvider.subjects.fold<int>(
          0,
          (sum, subject) =>
              sum +
              subject.chapters
                  .where((chapter) => chapter.isCompleted)
                  .length,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            110,
          ),
          child: Column(
            children: [
              _buildProfileHeader(),

              const SizedBox(height: 20),

              _buildStatsCard(
                totalHours,
                subjects,
                chapters,
                completedChapters,
              ),

              const SizedBox(height: 20),

              _buildGoalCard(),

              const SizedBox(height: 20),

              _buildSectionTitle('Profile'),

              const SizedBox(height: 10),

              _buildSettingTile(
                icon: Icons.person_outline,
                title: 'Name',
                value: _name,
                onTap: _showEditProfileDialog,
              ),

              _buildSettingTile(
                icon: Icons.flag_outlined,
                title: 'Preparation Goal',
                value: _goal,
                onTap: _showEditProfileDialog,
              ),

              _buildSettingTile(
                icon: Icons.schedule_outlined,
                title: 'Daily Study Goal',
                value:
                    '${_dailyHours.toStringAsFixed(1)} hours',
                onTap: _showEditProfileDialog,
              ),

              const SizedBox(height: 20),

              _buildSectionTitle('About StudyX'),

              const SizedBox(height: 10),

              _buildInfoTile(
                Icons.school_outlined,
                'StudyX',
                'Premium Study Tracker',
              ),

              _buildInfoTile(
                Icons.auto_awesome_outlined,
                'Version',
                '1.0.0',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    final firstLetter = _name.isEmpty
        ? 'S'
        : _name.trim().substring(0, 1).toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C1C2B),
            Color(0xFF101010),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF818CF8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1)
                      .withOpacity(0.25),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _goal,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(
                Icons.edit_outlined,
                size: 18,
              ),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(
                  color: Colors.white12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    double totalHours,
    int subjects,
    int chapters,
    int completedChapters,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStat(
              Icons.timer_outlined,
              totalHours >= 100
                  ? '${totalHours.toStringAsFixed(0)}h'
                  : '${totalHours.toStringAsFixed(1)}h',
              'Study',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStat(
              Icons.menu_book_outlined,
              '$subjects',
              'Subjects',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStat(
              Icons.library_books_outlined,
              '$chapters',
              'Chapters',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildStat(
              Icons.check_circle_outline,
              '$completedChapters',
              'Done',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF818CF8),
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 45,
      color: Colors.white10,
    );
  }

  Widget _buildGoalCard() {
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF6366F1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Color(0xFF818CF8),
                ),
              ),

              const SizedBox(width: 13),

              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Study Goal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Stay consistent every day',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${_dailyHours.toStringAsFixed(1)}h',
                style: const TextStyle(
                  color: Color(0xFF818CF8),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_dailyHours / 12).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white10,
              valueColor:
                  const AlwaysStoppedAnimation(
                Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF818CF8),
            size: 21,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white30,
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF101010),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white10,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: const Color(0xFF818CF8),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}