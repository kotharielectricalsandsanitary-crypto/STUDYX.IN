
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'chapter_detail_screen.dart';
import '../models/chapter_model.dart';
import '../providers/syllabus_provider.dart';
import '../theme/app_colors.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
  });

  @override
  State<SubjectDetailScreen> createState() =>
      _SubjectDetailScreenState();
}

class _SubjectDetailScreenState
    extends State<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pageAnimationController;

  @override
  void initState() {
    super.initState();

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _pageAnimationController.dispose();
    super.dispose();
  }

  // ============================================================
  // OPEN CHAPTER DETAIL
  // ============================================================

  void _openChapterDetail(
    Subject subject,
    Chapter chapter,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChapterDetailScreen(
          subjectId: subject.id,
          chapterId: chapter.id,
        ),
      ),
    );
  }

  // ============================================================
  // ADD CHAPTER
  // ============================================================

  Future<void> _showAddChapterDialog() async {
    final controller = TextEditingController();

    try {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 35,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient:
                              AppColors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Add Chapter',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                    ),
                    textInputAction:
                        TextInputAction.done,
                    decoration: InputDecoration(
                      hintText:
                          'Example: Cell: The Unit of Life',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.auto_stories_rounded,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor:
                          AppColors.surfaceLight,
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(17),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(17),
                        borderSide: BorderSide(
                          color: AppColors.primary
                              .withOpacity(0.65),
                        ),
                      ),
                    ),
                    onSubmitted: (_) {
                      final value =
                          controller.text.trim();

                      if (value.isNotEmpty) {
                        Navigator.of(dialogContext)
                            .pop(value);
                      }
                    },
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext)
                              .pop();
                        },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color:
                                AppColors.textMuted,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          final value =
                              controller.text.trim();

                          if (value.isEmpty) {
                            return;
                          }

                          Navigator.of(dialogContext)
                              .pop(value);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Add Chapter',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
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

      if (!mounted) return;

      if (name == null || name.trim().isEmpty) {
        return;
      }

      await context.read<SyllabusProvider>().addChapter(
            subjectId: widget.subjectId,
            name: name.trim(),
          );
    } finally {
      controller.dispose();
    }
  }

  // ============================================================
  // DELETE CHAPTER
  // ============================================================

  Future<void> _deleteChapter(Chapter chapter) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color:
                  AppColors.danger.withOpacity(0.20),
            ),
          ),
          title: Text(
            'Delete Chapter?',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Delete "${chapter.name}"?',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(false);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext)
                    .pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.danger.withOpacity(0.12),
                foregroundColor:
                    AppColors.danger,
                elevation: 0,
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    await context
        .read<SyllabusProvider>()
        .deleteChapter(
          widget.subjectId,
          chapter.id,
        );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<SyllabusProvider>(
      builder: (context, provider, child) {
        Subject? subject;

        for (final item in provider.subjects) {
          if (item.id == widget.subjectId) {
            subject = item;
            break;
          }
        }

        if (subject == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Subject not found',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                ),
              ),
            ),
          );
        }

        final currentSubject = subject;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(currentSubject),
          body: currentSubject.chapters.isEmpty
              ? _buildEmptyState()
              : SafeArea(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(
                      18,
                      15,
                      18,
                      120,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(
                          maxWidth: 1100,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildAnimatedProgressCard(
                              currentSubject,
                            ),
                            const SizedBox(height: 26),
                            _buildChapterHeader(
                              currentSubject,
                            ),
                            const SizedBox(height: 14),
                            ...List.generate(
                              currentSubject.chapters.length,
                              (index) {
                                final chapter =
                                    currentSubject
                                        .chapters[index];

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    bottom: 15,
                                  ),
                                  child:
                                      _AnimatedChapterCard(
                                    index: index,
                                    child:
                                        _buildChapterCard(
                                      currentSubject,
                                      chapter,
                                    ),
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
              _buildFloatingActionButton(),
        );
      },
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
    Subject subject,
  ) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
      titleSpacing: 0,
      title: Text(
        subject.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Add chapter',
          onPressed: _showAddChapterDialog,
          icon: const Icon(
            Icons.add_rounded,
            color: AppColors.primary,
            size: 27,
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  // ============================================================
  // PROGRESS CARD
  // ============================================================

  Widget _buildAnimatedProgressCard(
    Subject subject,
  ) {
    final progress = subject.progress;

    final completed = subject.chapters
        .where(
          (chapter) => chapter.isCompleted,
        )
        .length;

    return AnimatedBuilder(
      animation: _pageAnimationController,
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(
          _pageAnimationController.value,
        );

        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              0,
              18 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.card2,
              AppColors.cardBackground,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color:
                AppColors.primary.withOpacity(0.16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.20),
              blurRadius: 25,
              offset: const Offset(0, 12),
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
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    gradient:
                        AppColors.primaryGradient,
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Subject Progress',
                    style: GoogleFonts.inter(
                      color:
                          AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(20),
              child:
                  TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: progress,
                ),
                duration:
                    const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder:
                    (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 9,
                    backgroundColor:
                        AppColors.surfaceLight,
                    valueColor:
                        const AlwaysStoppedAnimation<
                            Color>(
                      AppColors.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  '$completed of ${subject.chapters.length} chapters completed',
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CHAPTER HEADER
  // ============================================================

  Widget _buildChapterHeader(
    Subject subject,
  ) {
    final completed = subject.chapters
        .where(
          (chapter) => chapter.isCompleted,
        )
        .length;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Chapters',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a chapter to open its full study dashboard.',
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color:
                AppColors.primary.withOpacity(0.09),
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color:
                  AppColors.primary.withOpacity(0.14),
            ),
          ),
          child: Text(
            '$completed/${subject.chapters.length}',
            style: GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CHAPTER CARD
  // ============================================================

  Widget _buildChapterCard(
    Subject subject,
    Chapter chapter,
  ) {
    final progress = chapter.progress;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: chapter.isCompleted
                ? AppColors.success.withOpacity(0.24)
                : AppColors.cardBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 20,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Column(
          children: [
            // ======================================================
            // CLICKABLE CHAPTER HEADER
            // ======================================================

            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(23),
                ),
                splashColor:
                    AppColors.primary.withOpacity(0.08),
                highlightColor:
                    AppColors.primary.withOpacity(0.04),
                onTap: () {
                  _openChapterDetail(
                    subject,
                    chapter,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    10,
                    15,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 300),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: chapter.isCompleted
                              ? LinearGradient(
                                  colors: [
                                    AppColors.success
                                        .withOpacity(0.18),
                                    AppColors.success
                                        .withOpacity(0.06),
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    AppColors.primary
                                        .withOpacity(0.18),
                                    AppColors.accent
                                        .withOpacity(0.06),
                                  ],
                                ),
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                        child: Icon(
                          chapter.isCompleted
                              ? Icons.check_rounded
                              : Icons.book_rounded,
                          color: chapter.isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                          size: 23,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              chapter.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color:
                                    AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  '${(progress * 100).round()}% completed',
                                  style: GoogleFonts.inter(
                                    color:
                                        AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color:
                                      AppColors.textMuted,
                                  size: 10,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      PopupMenuButton<String>(
                        color: AppColors.card2,
                        elevation: 12,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color:
                              AppColors.textMuted,
                        ),
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteChapter(chapter);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons
                                      .delete_outline_rounded,
                                  color:
                                      AppColors.danger,
                                  size: 19,
                                ),
                                const SizedBox(width: 9),
                                Text(
                                  'Delete Chapter',
                                  style:
                                      GoogleFonts.inter(
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
                ),
              ),
            ),

            // ======================================================
            // PROGRESS
            // ======================================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 18,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(20),
                child:
                    TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: progress,
                  ),
                  duration: const Duration(
                    milliseconds: 700,
                  ),
                  curve: Curves.easeOutCubic,
                  builder:
                      (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor:
                          AppColors.surfaceLight,
                      valueColor:
                          AlwaysStoppedAnimation<
                              Color>(
                        chapter.isCompleted
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            Divider(
              color: AppColors.cardBorder,
              height: 1,
            ),

            // ======================================================
            // STEPS
            // ======================================================

            if (chapter.steps.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color:
                          AppColors.textMuted,
                      size: 17,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      'No steps added to this chapter yet.',
                      style: GoogleFonts.inter(
                        color:
                            AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...chapter.steps.map(
                (step) {
                  return AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 220,
                    ),
                    margin:
                        const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: step.completed
                          ? AppColors.success
                              .withOpacity(0.025)
                          : Colors.transparent,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: CheckboxListTile(
                      value: step.completed,
                      onChanged:
                          (value) async {
                        if (value == null) {
                          return;
                        }

                        await context
                            .read<
                                SyllabusProvider>()
                            .toggleStep(
                              subjectId:
                                  subject.id,
                              chapterId:
                                  chapter.id,
                              stepId:
                                  step.id,
                              completed:
                                  value,
                            );
                      },
                      activeColor:
                          AppColors.primary,
                      checkColor:
                          Colors.white,
                      controlAffinity:
                          ListTileControlAffinity
                              .leading,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      title: Text(
                        step.title,
                        style: GoogleFonts.inter(
                          color: step.completed
                              ? AppColors.textMuted
                              : AppColors
                                  .textPrimary,
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w500,
                          decoration:
                              step.completed
                                  ? TextDecoration
                                      .lineThrough
                                  : null,
                          decorationColor:
                              AppColors.textMuted,
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 7,
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary
                          .withOpacity(0.18),
                      AppColors.accent
                          .withOpacity(0.07),
                    ],
                  ),
                  borderRadius:
                      BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.primary
                        .withOpacity(0.15),
                  ),
                ),
                child: const Icon(
                  Icons.auto_stories_rounded,
                  color: AppColors.primary,
                  size: 45,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Chapters Yet',
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Add chapters to start tracking\nyour syllabus.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              ElevatedButton.icon(
                onPressed:
                    _showAddChapterDialog,
                icon: const Icon(
                  Icons.add_rounded,
                ),
                label: Text(
                  'Add Chapter',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 21,
                    vertical: 15,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FLOATING BUTTON
  // ============================================================

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddChapterDialog,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Add Chapter',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// ANIMATED CHAPTER CARD
// ============================================================

class _AnimatedChapterCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedChapterCard({
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedChapterCard> createState() =>
      _AnimatedChapterCardState();
}

class _AnimatedChapterCardState
    extends State<_AnimatedChapterCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
   duration: const Duration(milliseconds: 450),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.045),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scale = Tween<double>(
      begin: 0.985,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(
  Duration(
    milliseconds: 50 + (widget.index * 35).clamp(0, 350),
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
