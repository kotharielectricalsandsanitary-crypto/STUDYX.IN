import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class ProfileControlScreen extends StatefulWidget {
  const ProfileControlScreen({super.key});

  @override
  State<ProfileControlScreen> createState() =>
      _ProfileControlScreenState();
}

class _ProfileControlScreenState
    extends State<ProfileControlScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late TextEditingController _hoursController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    final user = context.read<UserProvider>();

    _nameController =
        TextEditingController(text: user.name);

    _goalController =
        TextEditingController(text: user.goal);

    _hoursController = TextEditingController(
      text: user.dailyHours > 0
          ? _removeTrailingZeros(user.dailyHours)
          : '',
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _controller.forward();
  }

  String _removeTrailingZeros(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _hoursController.dispose();

    _controller.dispose();

    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    final goal = _goalController.text.trim();
    final hours =
        double.tryParse(_hoursController.text.trim());

    if (name.isEmpty) {
      _showError('Please enter your name.');
      return;
    }

    if (goal.isEmpty) {
      _showError('Please enter your goal.');
      return;
    }

    if (hours == null || hours <= 0) {
      _showError(
        'Please enter valid daily study hours.',
      );
      return;
    }

    if (hours > 24) {
      _showError(
        'Daily study hours cannot be more than 24.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await context.read<UserProvider>().updateUser(
            newName: name,
            newGoal: goal,
            newDailyHours: hours,
          );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );

      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showError(
        'Could not save changes. Please try again.',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildBackground(),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),
                child: Column(
                  children: [
                    _buildAppBar(),

                    Expanded(
                      child: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal:
                              isDesktop ? 35 : 18,
                          vertical: 20,
                        ),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final opacity =
                                Curves.easeOutCubic
                                    .transform(
                              _controller.value,
                            );

                            final offset =
                                25 *
                                    (1 -
                                        Curves
                                            .easeOutCubic
                                            .transform(
                                          _controller.value,
                                        ));

                            return Opacity(
                              opacity: opacity,
                              child: Transform.translate(
                                offset:
                                    Offset(0, offset),
                                child: child,
                              ),
                            );
                          },
                          child: _buildContent(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BACKGROUND
  // ============================================================

  Widget _buildBackground() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -130,
            right: -100,
            child: _glow(
              320,
              AppColors.primary,
            ),
          ),
          Positioned(
            bottom: -170,
            left: -120,
            child: _glow(
              300,
              AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.055),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        15,
        18,
        5,
      ),
      child: Row(
        children: [
          _iconButton(
            Icons.arrow_back_rounded,
            () => Navigator.of(context).pop(),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Control Panel',
                  style: GoogleFonts.inter(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Manage your StudyX profile',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius:
                  BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withOpacity(0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color:
                AppColors.cardBackground.withOpacity(0.8),
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _buildProfileHero(),

        const SizedBox(height: 20),

        _sectionTitle(
          'PROFILE',
          Icons.person_outline_rounded,
        ),

        const SizedBox(height: 11),

        _buildProfileCard(),

        const SizedBox(height: 22),

        _sectionTitle(
          'STUDY SETTINGS',
          Icons.school_outlined,
        ),

        const SizedBox(height: 11),

        _buildStudyCard(),

        const SizedBox(height: 25),

        _buildSaveButton(),

        const SizedBox(height: 25),

        Text(
          'Changes are saved locally to your StudyX profile.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),

        const SizedBox(height: 25),
      ],
    );
  }

  // ============================================================
  // PROFILE HERO
  // ============================================================

  Widget _buildProfileHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.20),
            AppColors.accent.withOpacity(0.07),
            AppColors.cardBackground,
          ],
        ),
        borderRadius:
            BorderRadius.circular(25),
        border: Border.all(
          color:
              AppColors.primary.withOpacity(0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient:
                  AppColors.primaryGradient,
              borderRadius:
                  BorderRadius.circular(21),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withOpacity(0.25),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 17),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Your StudyX Profile',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Customize your identity and study targets.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.45,
                    color: AppColors.textSecondary,
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
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.primary,
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard() {
    return _card(
      child: Column(
        children: [
          _field(
            controller: _nameController,
            label: 'Your Name',
            hint: 'Enter your name',
            icon: Icons.person_outline_rounded,
          ),

          const SizedBox(height: 15),

          _field(
            controller: _goalController,
            label: 'Main Goal',
            hint: 'Example: NEET 2028',
            icon: Icons.flag_outlined,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDY CARD
  // ============================================================

  Widget _buildStudyCard() {
    return _card(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          _field(
            controller: _hoursController,
            label: 'Daily Study Hours',
            hint: 'Example: 8',
            icon: Icons.timer_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
          ),

          const SizedBox(height: 17),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  AppColors.primary.withOpacity(0.055),
              borderRadius:
                  BorderRadius.circular(15),
              border: Border.all(
                color:
                    AppColors.primary.withOpacity(0.10),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Your daily study target controls the progress percentage shown on your Home screen.',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
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
  // FIELD
  // ============================================================

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 7),

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
            prefixIcon: Icon(
              icon,
              size: 19,
              color: AppColors.primary,
            ),
            filled: true,
            fillColor:
                AppColors.background.withOpacity(0.55),
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide: BorderSide(
                color: AppColors.cardBorder,
              ),
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide: BorderSide(
                color: AppColors.cardBorder,
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(15),
              borderSide: BorderSide(
                color: AppColors.primary
                    .withOpacity(0.65),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _card({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground
                .withOpacity(0.78),
          ],
        ),
        borderRadius:
            BorderRadius.circular(23),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(17),
        child: InkWell(
          onTap:
              _saving ? null : _saveChanges,
          borderRadius:
              BorderRadius.circular(17),
          child: Ink(
            decoration: BoxDecoration(
              gradient:
                  AppColors.primaryGradient,
              borderRadius:
                  BorderRadius.circular(17),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Save Changes',
                          style:
                              GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}