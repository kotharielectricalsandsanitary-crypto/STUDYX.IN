import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/backlog_model.dart';
import '../providers/backlog_provider.dart';
import '../theme/app_colors.dart';
import 'backlog_detail_screen.dart';

class BacklogScreen extends StatefulWidget {
  const BacklogScreen({super.key});

  @override
  State<BacklogScreen> createState() => _BacklogScreenState();
}

class _BacklogScreenState extends State<BacklogScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _fabScale = Tween<double>(
      begin: 1.0,
      end: 1.025,
    ).animate(
      CurvedAnimation(
        parent: _fabController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  // ============================================================
  // ADD BACKLOG
  // ============================================================

  void _showAddBacklogDialog() {
    final topicController = TextEditingController();
    final lectureController = TextEditingController();
    final minutesController =
        TextEditingController(text: '60');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cardBackground,
                  AppColors.cardBackground.withOpacity(0.95),
                  AppColors.background,
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.50),
                  blurRadius: 45,
                  offset: const Offset(0, 18),
                ),
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 35,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ------------------------------------------------
                  // HEADER
                  // ------------------------------------------------

                  Row(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          gradient:
                              AppColors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary
                                  .withOpacity(0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.library_add_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Backlog',
                              style: GoogleFonts.inter(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color:
                                    AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Track a topic you need to complete.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color:
                                    AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 19,
                        ),
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _dialogLabel('Topic name'),
                  const SizedBox(height: 8),

                  TextField(
                    controller: topicController,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textInputAction:
                        TextInputAction.next,
                    decoration: _inputDecoration(
                      'e.g. Human Physiology',
                      Icons.book_outlined,
                    ),
                  ),

                  const SizedBox(height: 17),

                  _dialogLabel('Number of lectures'),
                  const SizedBox(height: 8),

                  TextField(
                    controller: lectureController,
                    keyboardType:
                        TextInputType.number,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                      'e.g. 12',
                      Icons.video_library_outlined,
                    ),
                  ),

                  const SizedBox(height: 17),

                  _dialogLabel('Minutes per lecture'),
                  const SizedBox(height: 8),

                  TextField(
                    controller: minutesController,
                    keyboardType:
                        TextInputType.number,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _inputDecoration(
                      'e.g. 60',
                      Icons.timer_outlined,
                    ),
                  ),

                  const SizedBox(height: 25),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                            ).pop();
                          },
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final topic =
                                topicController.text.trim();

                            final lectures =
                                int.tryParse(
                              lectureController.text
                                  .trim(),
                            );

                            final minutes =
                                int.tryParse(
                                      minutesController
                                          .text
                                          .trim(),
                                    ) ??
                                    60;

                            if (topic.isEmpty) {
                              _showMessage(
                                'Please enter a topic name.',
                              );
                              return;
                            }

                            if (lectures == null ||
                                lectures < 1) {
                              _showMessage(
                                'Enter at least 1 lecture.',
                              );
                              return;
                            }

                            if (minutes < 1) {
                              _showMessage(
                                'Minutes must be greater than 0.',
                              );
                              return;
                            }

                            Navigator.of(
                              dialogContext,
                            ).pop();

                            await context
                                .read<BacklogProvider>()
                                .addBacklog(
                                  topic: topic,
                                  totalLectures:
                                      lectures,
                                  minutesPerLecture:
                                      minutes,
                                );

                            if (!mounted) return;

                            _showMessage(
                              'Backlog added successfully.',
                            );
                          },
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 17,
                          ),
                          label:
                              const Text('Add Backlog'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      topicController.dispose();
      lectureController.dispose();
      minutesController.dispose();
    });
  }

  // ============================================================
  // INPUT
  // ============================================================

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
  ) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 12,
      ),
      prefixIcon: Icon(
        icon,
        color: AppColors.primary,
        size: 19,
      ),
      filled: true,
      fillColor:
          AppColors.background.withOpacity(0.65),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: AppColors.cardBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: AppColors.primary.withOpacity(0.55),
          width: 1.2,
        ),
      ),
    );
  }

  Widget _dialogLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }

  // ============================================================
  // DAILY TARGET
  // ============================================================

  void _showTargetDialog(
    BacklogProvider provider,
  ) {
    int selected = provider.dailyTarget;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            statefulContext,
            setDialogState,
          ) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 24,
              ),
              child: Container(
                constraints:
                    const BoxConstraints(
                  maxWidth: 450,
                ),
                padding:
                    const EdgeInsets.all(23),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.cardBackground,
                      AppColors.background,
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(25),
                  border: Border.all(
                    color: AppColors.primary
                        .withOpacity(0.18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(
                        0.45,
                      ),
                      blurRadius: 40,
                      offset:
                          const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .primary
                                .withOpacity(
                              0.10,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                          child:
                              const Icon(
                            Icons.flag_rounded,
                            color:
                                AppColors.primary,
                            size: 21,
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Daily Target',
                                style:
                                    GoogleFonts
                                        .inter(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                  color: AppColors
                                      .textPrimary,
                                ),
                              ),
                              const SizedBox(
                                height: 3,
                              ),
                              Text(
                                'Set your daily lecture goal.',
                                style:
                                    GoogleFonts
                                        .inter(
                                  fontSize: 10.5,
                                  color: AppColors
                                      .textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 19,
                          ),
                          color:
                              AppColors.textMuted,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    DropdownButtonFormField<int>(
                      value: selected,
                      dropdownColor:
                          AppColors.cardBackground,
                      style: GoogleFonts.inter(
                        color:
                            AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w600,
                      ),
                      decoration:
                          _inputDecoration(
                        'Lectures per day',
                        Icons.flag_outlined,
                      ),
                      items: List.generate(
                        10,
                        (index) {
                          final value =
                              index + 1;

                          return DropdownMenuItem<
                              int>(
                            value: value,
                            child: Text(
                              '$value lecture${value == 1 ? '' : 's'} per day',
                            ),
                          );
                        },
                      ),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selected = value;
                        });
                      },
                    ),

                    const SizedBox(height: 22),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                            child:
                                const Text(
                              'Cancel',
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child:
                              ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(
                                dialogContext,
                              );

                              await provider
                                  .setDailyTarget(
                                selected,
                              );

                              if (!mounted) {
                                return;
                              }

                              _showMessage(
                                'Daily target updated.',
                              );
                            },
                            child:
                                const Text(
                              'Save Target',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _deleteBacklog(
    BacklogProvider provider,
    BacklogItem item,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Container(
            constraints:
                const BoxConstraints(
              maxWidth: 430,
            ),
            padding:
                const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cardBackground,
                  AppColors.background,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.danger
                    .withOpacity(0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(0.45),
                  blurRadius: 40,
                  offset:
                      const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration:
                      BoxDecoration(
                    color: AppColors.danger
                        .withOpacity(0.09),
                    borderRadius:
                        BorderRadius.circular(
                      17,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color:
                        AppColors.danger,
                    size: 26,
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  'Delete Backlog?',
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w900,
                    color:
                        AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'This will remove the topic and all its lecture progress.',
                  textAlign:
                      TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color:
                        AppColors.textMuted,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 13),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(
                    color: AppColors.background
                        .withOpacity(0.55),
                    borderRadius:
                        BorderRadius.circular(
                      13,
                    ),
                    border: Border.all(
                      color:
                          AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    item.topic,
                    textAlign:
                        TextAlign.center,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w700,
                      color:
                          AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 21),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                        child:
                            const Text(
                          'Cancel',
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child:
                          ElevatedButton(
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors
                                  .danger,
                        ),
                        onPressed: () async {
                          Navigator.pop(
                            dialogContext,
                          );

                          await provider
                              .deleteBacklog(
                            item.id,
                          );

                          if (!mounted) {
                            return;
                          }

                          _showMessage(
                            'Backlog deleted.',
                          );
                        },
                        child:
                            const Text(
                          'Delete',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width;

    final horizontalPadding =
        width >= 1000 ? 34.0 : 18.0;

    return Consumer<BacklogProvider>(
      builder: (
        context,
        provider,
        child,
      ) {
        return Scaffold(
          backgroundColor:
              Colors.transparent,

          body: SafeArea(
            child: provider.items.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(),
                    padding:
                        EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      120,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 1150,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            _buildHeader(
                              provider,
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            _buildSummaryCard(
                              provider,
                            ),

                            const SizedBox(
                              height: 26,
                            ),

                            _buildSectionHeader(
                              provider,
                            ),

                            const SizedBox(
                              height: 13,
                            ),

                            ...List.generate(
                              provider.items
                                  .length,
                              (index) {
                                final item =
                                    provider
                                        .items[index];

                                return _AnimatedBacklogCard(
                                  key: ValueKey(
                                    item.id,
                                  ),
                                  index: index,
                                  child:
                                      _buildBacklogCard(
                                    provider,
                                    item,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),

          floatingActionButton:
              ScaleTransition(
            scale: _fabScale,
            child:
                _buildFloatingActionButton(),
          ),
        );
      },
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BacklogProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 41,
                    height: 41,
                    decoration:
                        BoxDecoration(
                      gradient:
                          AppColors.primaryGradient,
                      borderRadius:
                          BorderRadius.circular(
                        13,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors
                              .primary
                              .withOpacity(
                            0.25,
                          ),
                          blurRadius: 18,
                          offset:
                              const Offset(
                            0,
                            6,
                          ),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons
                          .library_books_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Backlog',
                    style: GoogleFonts.inter(
                      fontSize: 25,
                      fontWeight:
                          FontWeight.w900,
                      color: AppColors
                          .textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${provider.items.length} topic${provider.items.length == 1 ? '' : 's'} in your learning backlog.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color:
                      AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        _headerIconButton(
          icon: Icons.flag_outlined,
          tooltip: 'Daily target',
          onTap: () {
            _showTargetDialog(provider);
          },
        ),
      ],
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius:
            BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(14),
          child: Container(
            width: 43,
            height: 43,
            decoration:
                BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color:
                    AppColors.cardBorder,
              ),
            ),
            child: Icon(
              icon,
              color:
                  AppColors.textSecondary,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard(
    BacklogProvider provider,
  ) {
    final progress =
        provider.overallProgress
            .clamp(0.0, 1.0);

    final hours =
        provider.remainingMinutes ~/ 60;

    final minutes =
        provider.remainingMinutes % 60;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary
                .withOpacity(0.11),
            AppColors.cardBackground
                .withOpacity(0.92),
            AppColors.background
                .withOpacity(0.40),
          ],
        ),
        borderRadius:
            BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary
              .withOpacity(0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.16),
            blurRadius: 25,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration:
                    BoxDecoration(
                  color: AppColors.primary
                      .withOpacity(0.09),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child: const Icon(
                  Icons
                      .trending_up_rounded,
                  color:
                      AppColors.primary,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Backlog Overview',
                      style:
                          GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                        color: AppColors
                            .textPrimary,
                      ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      'Your current learning progress',
                      style:
                          GoogleFonts.inter(
                        fontSize: 9.5,
                        color: AppColors
                            .textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              TweenAnimationBuilder<
                  double>(
                tween: Tween<double>(
                  begin: 0,
                  end: progress,
                ),
                duration:
                    const Duration(
                  milliseconds: 800,
                ),
                curve:
                    Curves.easeOutCubic,
                builder:
                    (context, value, _) {
                  return Text(
                    '${(value * 100).round()}%',
                    style:
                        GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w900,
                      color:
                          AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 19),

          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0,
              end: progress,
            ),
            duration:
                const Duration(
              milliseconds: 900,
            ),
            curve: Curves.easeOutCubic,
            builder:
                (context, value, _) {
              return ClipRRect(
                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
                child:
                    LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor:
                      Colors.white
                          .withOpacity(
                    0.06,
                  ),
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    AppColors.primary,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 19),

          LayoutBuilder(
            builder:
                (context, constraints) {
              if (constraints.maxWidth <
                  450) {
                return Wrap(
                  spacing: 25,
                  runSpacing: 16,
                  children: [
                    _stat(
                      'Completed',
                      '${provider.completedLectures}',
                      AppColors.success,
                    ),
                    _stat(
                      'Remaining',
                      '${provider.remainingLectures}',
                      AppColors.warning,
                    ),
                    _stat(
                      'Target',
                      '${provider.dailyTarget}/day',
                      AppColors.primary,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _stat(
                      'Completed',
                      '${provider.completedLectures}',
                      AppColors.success,
                    ),
                  ),
                  _statDivider(),
                  Expanded(
                    child: _stat(
                      'Remaining',
                      '${provider.remainingLectures}',
                      AppColors.warning,
                    ),
                  ),
                  _statDivider(),
                  Expanded(
                    child: _stat(
                      'Target',
                      '${provider.dailyTarget}/day',
                      AppColors.primary,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 18),

          Container(
            padding:
                const EdgeInsets.all(13),
            decoration:
                BoxDecoration(
              color: AppColors.background
                  .withOpacity(0.38),
              borderRadius:
                  BorderRadius.circular(14),
              border: Border.all(
                color:
                    AppColors.cardBorder,
              ),
            ),
            child: Column(
              children: [
                _infoRow(
                  Icons.today_rounded,
                  'Today',
                  '${provider.todayCompletedLectures}/${provider.dailyTarget} lectures',
                  AppColors.accent,
                ),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.schedule_rounded,
                  'Remaining time',
                  '${hours}h ${minutes}m',
                  AppColors.textSecondary,
                ),
                const SizedBox(height: 10),
                _infoRow(
                  Icons.event_available_rounded,
                  'Estimated completion',
                  '${provider.estimatedDaysRemaining} days',
                  AppColors.textSecondary,
                ),
                if (provider
                        .averageLecturesPerDay >
                    0) ...[
                  const SizedBox(height: 10),
                  _infoRow(
                    Icons.speed_rounded,
                    'Average pace',
                    '${provider.averageLecturesPerDay.toStringAsFixed(1)} lectures/day',
                    AppColors.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    String title,
    String value,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration:
              BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color
                    .withOpacity(0.45),
                blurRadius: 7,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight:
                    FontWeight.w900,
                color:
                    AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                color:
                    AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppColors.cardBorder,
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 10,
            color:
                AppColors.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight:
                FontWeight.w700,
            color:
                AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(
    BacklogProvider provider,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Your Backlog',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.w900,
                  color:
                      AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Open a topic to continue your lectures.',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color:
                      AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration:
              BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius:
                BorderRadius.circular(9),
            border: Border.all(
              color:
                  AppColors.cardBorder,
            ),
          ),
          child: Text(
            '${provider.items.length} topic${provider.items.length == 1 ? '' : 's'}',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
              color:
                  AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BACKLOG CARD
  // ============================================================

  Widget _buildBacklogCard(
    BacklogProvider provider,
    BacklogItem item,
  ) {
    final progress =
        item.progress.clamp(0.0, 1.0);

    final completed = item.isCompleted;

    final accent = completed
        ? AppColors.success
        : AppColors.primary;

    return Material(
      color: Colors.transparent,
      borderRadius:
          BorderRadius.circular(22),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(22),
        onTap: () {
          Navigator.push(
            context,
            PageRouteBuilder(
              transitionDuration:
                  const Duration(
                milliseconds: 350,
              ),
              reverseTransitionDuration:
                  const Duration(
                milliseconds: 250,
              ),
              pageBuilder: (
                context,
                animation,
                secondaryAnimation,
              ) =>
                  BacklogDetailScreen(
                backlogId: item.id,
              ),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                final slide =
                    Tween<Offset>(
                  begin:
                      const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve:
                        Curves.easeOutCubic,
                  ),
                );

                return FadeTransition(
                  opacity: animation,
                  child:
                      SlideTransition(
                    position: slide,
                    child: child,
                  ),
                );
              },
            ),
          );
        },
        child: Container(
          margin:
              const EdgeInsets.only(
            bottom: 12,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardBackground,
                AppColors.cardBackground
                    .withOpacity(0.82),
                AppColors.background
                    .withOpacity(0.28),
              ],
            ),
            borderRadius:
                BorderRadius.circular(22),
            border: Border.all(
              color: completed
                  ? AppColors.success
                      .withOpacity(0.22)
                  : AppColors.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.16),
                blurRadius: 22,
                offset:
                    const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(22),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // ------------------------------------------------
                  // ACCENT LINE
                  // ------------------------------------------------

                  Container(
                    width: 3,
                    decoration:
                        BoxDecoration(
                      color: accent,
                      boxShadow: [
                        BoxShadow(
                          color: accent
                              .withOpacity(
                            0.35,
                          ),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets
                              .fromLTRB(
                        14,
                        14,
                        12,
                        14,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // --------------------------------
                              // ICON
                              // --------------------------------

                              Container(
                                width: 49,
                                height: 49,
                                decoration:
                                    BoxDecoration(
                                  color: accent
                                      .withOpacity(
                                    0.09,
                                  ),
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    15,
                                  ),
                                  border:
                                      Border.all(
                                    color: accent
                                        .withOpacity(
                                      0.10,
                                    ),
                                  ),
                                ),
                                child: Icon(
                                  completed
                                      ? Icons
                                          .check_rounded
                                      : Icons
                                          .play_circle_outline_rounded,
                                  color: accent,
                                  size: 23,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              // --------------------------------
                              // TOPIC
                              // --------------------------------

                              Expanded(
                                child:
                                    Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child:
                                              Text(
                                            item.topic,
                                            maxLines:
                                                2,
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style:
                                                GoogleFonts.inter(
                                              fontSize:
                                                  13.5,
                                              fontWeight:
                                                  FontWeight
                                                      .w800,
                                              color:
                                                  AppColors.textPrimary,
                                              height:
                                                  1.3,
                                            ),
                                          ),
                                        ),
                                        if (completed)
                                          _completedBadge(),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 6,
                                    ),
                                    Text(
                                      '${item.completedLectures}/${item.totalLectures} lectures • ${item.minutesPerLecture} min each',
                                      style:
                                          GoogleFonts.inter(
                                        fontSize:
                                            9.5,
                                        color:
                                            AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(
                                width: 5,
                              ),

                              // --------------------------------
                              // MENU
                              // --------------------------------

                              PopupMenuButton<
                                  String>(
                                tooltip:
                                    'More',
                                color: AppColors
                                    .cardBackground,
                                elevation: 8,
                                icon:
                                    const Icon(
                                  Icons
                                      .more_vert_rounded,
                                  color: AppColors
                                      .textMuted,
                                  size: 19,
                                ),
                                onSelected:
                                    (value) {
                                  if (value ==
                                      'delete') {
                                    _deleteBacklog(
                                      provider,
                                      item,
                                    );
                                  }
                                },
                                itemBuilder:
                                    (_) =>
                                        [
                                  PopupMenuItem<
                                      String>(
                                    value:
                                        'delete',
                                    child:
                                        Row(
                                      children: [
                                        const Icon(
                                          Icons
                                              .delete_outline_rounded,
                                          color:
                                              AppColors.danger,
                                          size:
                                              17,
                                        ),
                                        const SizedBox(
                                          width:
                                              8,
                                        ),
                                        Text(
                                          'Delete Backlog',
                                          style:
                                              GoogleFonts.inter(
                                            fontSize:
                                                11,
                                            color:
                                                AppColors.danger,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 17,
                          ),

                          // --------------------------------
                          // PROGRESS
                          // --------------------------------

                          Row(
                            children: [
                              Expanded(
                                child:
                                    TweenAnimationBuilder<
                                        double>(
                                  tween:
                                      Tween<
                                          double>(
                                    begin:
                                        0,
                                    end:
                                        progress,
                                  ),
                                  duration:
                                      const Duration(
                                    milliseconds:
                                        800,
                                  ),
                                  curve:
                                      Curves
                                          .easeOutCubic,
                                  builder:
                                      (
                                    context,
                                    value,
                                    _,
                                  ) {
                                    return ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(
                                        8,
                                      ),
                                      child:
                                          LinearProgressIndicator(
                                        value:
                                            value,
                                        minHeight:
                                            7,
                                        backgroundColor:
                                            Colors.white.withOpacity(
                                          0.055,
                                        ),
                                        valueColor:
                                            AlwaysStoppedAnimation<
                                                Color>(
                                          accent,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(
                                width: 11,
                              ),

                              Text(
                                '${(progress * 100).round()}%',
                                style:
                                    GoogleFonts.inter(
                                  fontSize:
                                      11,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                  color:
                                      accent,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          // --------------------------------
                          // FOOTER
                          // --------------------------------

                          Row(
                            children: [
                              Icon(
                                completed
                                    ? Icons
                                        .verified_rounded
                                    : Icons
                                        .schedule_rounded,
                                size: 13,
                                color: completed
                                    ? AppColors
                                        .success
                                    : AppColors
                                        .textMuted,
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Expanded(
                                child:
                                    Text(
                                  completed
                                      ? 'Completed'
                                      : '${item.remainingLectures} lecture${item.remainingLectures == 1 ? '' : 's'} remaining',
                                  style:
                                      GoogleFonts.inter(
                                    fontSize:
                                        9.5,
                                    fontWeight:
                                        completed
                                            ? FontWeight
                                                .w700
                                            : FontWeight
                                                .w500,
                                    color: completed
                                        ? AppColors
                                            .success
                                        : AppColors
                                            .textMuted,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons
                                    .arrow_forward_rounded,
                                size: 16,
                                color: AppColors
                                    .textMuted,
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _completedBadge() {
    return Container(
      margin:
          const EdgeInsets.only(left: 7),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.success
            .withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(7),
        border: Border.all(
          color: AppColors.success
              .withOpacity(0.12),
        ),
      ),
      child: Text(
        'DONE',
        style: GoogleFonts.inter(
          fontSize: 7.5,
          fontWeight:
              FontWeight.w900,
          color: AppColors.success,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(30),
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(
            maxWidth: 440,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<
                  double>(
                tween: Tween<double>(
                  begin: 0.82,
                  end: 1,
                ),
                duration:
                    const Duration(
                  milliseconds: 700,
                ),
                curve:
                    Curves.easeOutBack,
                builder:
                    (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration:
                      BoxDecoration(
                    gradient:
                        LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        AppColors.primary
                            .withOpacity(
                          0.16,
                        ),
                        AppColors.accent
                            .withOpacity(
                          0.05,
                        ),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      31,
                    ),
                    border: Border.all(
                      color: AppColors.primary
                          .withOpacity(
                        0.15,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors
                            .primary
                            .withOpacity(
                          0.12,
                        ),
                        blurRadius: 35,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons
                        .library_books_rounded,
                    color:
                        AppColors.primary,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              Text(
                'No Backlog Yet',
                textAlign:
                    TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight:
                      FontWeight.w900,
                  color: AppColors
                      .textPrimary,
                  letterSpacing: -0.7,
                ),
              ),

              const SizedBox(
                height: 9,
              ),

              Text(
                'Add your pending topics and track every lecture from one place.',
                textAlign:
                    TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color:
                      AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              ElevatedButton.icon(
                onPressed:
                    _showAddBacklogDialog,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Add Backlog',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FAB
  // ============================================================

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary
                .withOpacity(0.28),
            blurRadius: 24,
            offset:
                const Offset(0, 9),
          ),
        ],
      ),
      child: FloatingActionButton
          .extended(
        onPressed:
            _showAddBacklogDialog,
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        elevation: 0,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(18),
        ),
        icon: const Icon(
          Icons.add_rounded,
          size: 20,
        ),
        label: Text(
          'Add Backlog',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons
                    .check_circle_outline_rounded,
                color:
                    AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
        ),
      );
  }
}

// ============================================================================
// ANIMATED BACKLOG CARD
// ============================================================================

class _AnimatedBacklogCard
    extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedBacklogCard({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedBacklogCard> createState() =>
      _AnimatedBacklogCardState();
}

class _AnimatedBacklogCardState
    extends State<_AnimatedBacklogCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController
      _controller;

  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds:
            420 + (widget.index * 55),
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scale = Tween<double>(
      begin: 0.975,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      Duration(
        milliseconds:
            widget.index * 45,
      ),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}