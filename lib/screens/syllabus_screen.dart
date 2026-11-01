
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/syllabus_provider.dart';
import '../theme/app_colors.dart';
import 'subject_detail_screen.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController =
      TextEditingController();

  late final AnimationController _animationController;

  String _searchQuery = '';
  bool _isImporting = false;

  // ============================================================
  // BUILT-IN BOOKS
  // ============================================================

  final Map<String, List<String>> _builtInBooks = {
    'NCERT Class 11 Biology': [
      'The Living World',
      'Biological Classification',
      'Plant Kingdom',
      'Animal Kingdom',
      'Morphology of Flowering Plants',
      'Anatomy of Flowering Plants',
      'Structural Organisation in Animals',
      'Cell: The Unit of Life',
      'Biomolecules',
      'Cell Cycle and Cell Division',
      'Photosynthesis in Plants',
      'Respiration in Plants',
      'Plant Growth and Development',
      'Breathing and Exchange of Gases',
      'Body Fluids and Circulation',
      'Excretory Products and Their Elimination',
      'Locomotion and Movement',
      'Neural Control and Coordination',
      'Chemical Coordination and Integration',
    ],
    'NCERT Class 11 Chemistry': [
      'Some Basic Concepts of Chemistry',
      'Structure of Atom',
      'Classification of Elements and Periodicity in Properties',
      'Chemical Bonding and Molecular Structure',
      'Thermodynamics',
      'Equilibrium',
      'Redox Reactions',
      'Organic Chemistry: Some Basic Principles and Techniques',
      'Hydrocarbons',
      'Some Basic Principles of Organic Chemistry',
      'Environmental Chemistry',
    ],
    'NCERT Class 11 Physics': [
      'Units and Measurements',
      'Motion in a Straight Line',
      'Motion in a Plane',
      'Laws of Motion',
      'Work, Energy and Power',
      'System of Particles and Rotational Motion',
      'Gravitation',
      'Mechanical Properties of Solids',
      'Mechanical Properties of Fluids',
      'Thermal Properties of Matter',
      'Thermodynamics',
      'Kinetic Theory',
      'Oscillations',
      'Waves',
    ],
  };

  // ============================================================
  // COLORS
  // ============================================================

  Color get _violet => AppColors.primary;
Color get _deepViolet => const Color(0xff2855B8);
Color get _gold => AppColors.accent;

  LinearGradient get _premiumGradient {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        _deepViolet,
        _violet,
      ],
    );
  }

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();

    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (!mounted) return;

    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // SUBJECT HELPERS
  // ============================================================

  String _subjectSubtitle(Subject subject) {
    final count = subject.chapters.length;

    if (count == 0) {
      return 'No chapters added yet';
    }

    return '$count ${count == 1 ? 'chapter' : 'chapters'}';
  }

  double _subjectProgress(Subject subject) {
    if (subject.chapters.isEmpty) {
      return 0;
    }

    double total = 0;

    for (final chapter in subject.chapters) {
      total += chapter.studyProgress;
    }

    return (total / subject.chapters.length).clamp(0.0, 1.0);
  }

  bool _subjectMatches(Subject subject) {
    if (_searchQuery.isEmpty) {
      return true;
    }

    if (subject.name.toLowerCase().contains(_searchQuery)) {
      return true;
    }

    for (final chapter in subject.chapters) {
      if (chapter.name.toLowerCase().contains(_searchQuery)) {
        return true;
      }

      for (final step in chapter.steps) {
        if (step.title.toLowerCase().contains(_searchQuery)) {
          return true;
        }
      }
    }

    return false;
  }

  List<Subject> _filteredSubjects(List<Subject> subjects) {
    return subjects.where(_subjectMatches).toList();
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _openSubject(Subject subject) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return SubjectDetailScreen(
            subjectId: subject.id,
          );
        },
        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // ADD SUBJECT
  // ============================================================

  Future<void> _showAddSubjectDialog() async {
    final controller = TextEditingController();

    try {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return _PremiumDialog(
            icon: Icons.menu_book_rounded,
            title: 'Add Subject',
            subtitle: 'Create a new study subject.',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogTextField(
                  controller: controller,
                  hint: 'Example: Biology',
                  icon: Icons.auto_stories_rounded,
                  autofocus: true,
                  onSubmitted: () {
                    final value = controller.text.trim();

                    if (value.isNotEmpty) {
                      Navigator.of(dialogContext).pop(value);
                    }
                  },
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        final value = controller.text.trim();

                        if (value.isEmpty) return;

                        Navigator.of(dialogContext).pop(value);
                      },
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'Add Subject',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: _primaryButtonStyle(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

      if (!mounted) return;

      if (name == null || name.trim().isEmpty) {
        return;
      }

      await context.read<SyllabusProvider>().addSubject(
            name.trim(),
          );
    } finally {
      controller.dispose();
    }
  }

  // ============================================================
  // DELETE SUBJECT
  // ============================================================

  Future<void> _deleteSubject(Subject subject) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.danger.withOpacity(0.20),
            ),
          ),
          title: Text(
            'Delete Subject?',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'Delete "${subject.name}" and all its chapters?',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
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
                Navigator.of(dialogContext).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.danger.withOpacity(0.12),
                foregroundColor: AppColors.danger,
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

    await context.read<SyllabusProvider>().deleteSubject(
          subject.id,
        );
  }

  // ============================================================
  // IMPORT BOOK
  // ============================================================

  Future<void> _showBookImportDialog() async {
    String? selectedBook;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return _PremiumDialog(
              icon: Icons.library_books_rounded,
              title: 'Import a Book',
              subtitle: 'Add a complete syllabus instantly.',
              maxWidth: 600,
              maxHeight: 720,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        for (final book in _builtInBooks.keys)
                          _bookOption(
                            book: book,
                            selected: selectedBook == book,
                            onTap: () {
                              setDialogState(() {
                                selectedBook = book;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      ElevatedButton.icon(
                        onPressed: selectedBook == null
                            ? null
                            : () async {
                                final book = selectedBook!;

                                Navigator.of(dialogContext).pop();

                                await _importBook(book);
                              },
                        icon: const Icon(
                          Icons.download_rounded,
                          size: 18,
                        ),
                        label: Text(
                          'Import Book',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: _primaryButtonStyle(
                          disabled: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _bookOption({
    required String book,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final chapters = _builtInBooks[book] ?? const <String>[];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected
                  ? _violet.withOpacity(0.11)
                  : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? _violet
                    : AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected
                      ? _violet
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        book,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${chapters.length} chapters',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: selected
                      ? _violet
                      : AppColors.textMuted,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _importBook(String book) async {
    if (_isImporting) return;

    final chapters = _builtInBooks[book];

    if (chapters == null || chapters.isEmpty) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      final provider = context.read<SyllabusProvider>();

      final subjectName = _subjectNameForBook(book);

      Subject? subject =
          provider.findSubjectByName(subjectName);

      if (subject == null) {
        subject = await provider.addSubject(
          subjectName,
        );
      }

      int added = 0;

      for (final chapterName in chapters) {
        final existing = provider.findChapterByName(
          subjectId: subject.id,
          chapterName: chapterName,
        );

        if (existing != null) {
          continue;
        }

        await provider.addChapter(
          subjectId: subject.id,
          name: chapterName,
        );

        added++;
      }

      if (!mounted) return;

      _showSnackBar(
        added == 0
            ? 'All chapters already exist in $subjectName.'
            : '$added chapters imported into $subjectName.',
        success: added > 0,
      );
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        'Book import failed.',
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  String _subjectNameForBook(String book) {
    final lower = book.toLowerCase();

    if (lower.contains('biology')) {
      return 'Biology';
    }

    if (lower.contains('chemistry')) {
      return 'Chemistry';
    }

    if (lower.contains('physics')) {
      return 'Physics';
    }

    return book;
  }

  // ============================================================
  // PASTE INDEX
  // ============================================================

  Future<void> _showPasteIndexDialog() async {
    final controller = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return _PremiumDialog(
            icon: Icons.content_paste_search_rounded,
            title: 'Paste Full Index',
            subtitle: 'Detect chapters automatically.',
            maxWidth: 680,
            maxHeight: 760,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _violet.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _violet.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: _gold,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Example:\n'
                          '1. The Living World\n'
                          '2. Biological Classification\n'
                          '3. Plant Kingdom',
                          style: GoogleFonts.inter(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    expands: true,
                    minLines: null,
                    maxLines: null,
                    textAlignVertical:
                        TextAlignVertical.top,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Paste your entire index here...',
                      hintStyle: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: _violet.withOpacity(0.6),
                        ),
                      ),
                      contentPadding:
                          const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 17),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final text =
                            controller.text.trim();

                        if (text.isEmpty) return;

                        Navigator.of(dialogContext).pop();

                        await _parseAndImportIndex(text);
                      },
                      icon: const Icon(
                        Icons.auto_fix_high_rounded,
                        size: 18,
                      ),
                      label: Text(
                        'Detect Chapters',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: _primaryButtonStyle(),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  // ============================================================
  // PARSE INDEX
  // ============================================================

  Future<void> _parseAndImportIndex(String text) async {
    final chapters = _extractChapterNames(text);

    if (chapters.isEmpty) {
      if (!mounted) return;

      _showSnackBar(
        'No numbered chapters were detected.',
        success: false,
      );

      return;
    }

    final selected =
        await _showDetectedChaptersDialog(chapters);

    if (selected == null || selected.isEmpty) {
      return;
    }

    if (!mounted) return;

    final subjectName = await _askSubjectName();

    if (subjectName == null ||
        subjectName.trim().isEmpty) {
      return;
    }

    await _importDetectedChapters(
      subjectName.trim(),
      selected,
    );
  }

  List<String> _extractChapterNames(String text) {
    final lines = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');

    final result = <String>[];

    for (final rawLine in lines) {
      var line = rawLine.trim();

      if (line.isEmpty) continue;

      // Remove dotted page numbers.
      line = line.replaceFirst(
        RegExp(r'\s+\.{2,}\s*\d+\s*$'),
        '',
      );

      // Remove ending page numbers.
      line = line.replaceFirst(
        RegExp(r'\s+\d+\s*$'),
        '',
      );

      final numberedMatch = RegExp(
        r'^(?:chapter\s*)?(\d{1,3})\s*[\.\):\-–—]?\s+(.+)$',
        caseSensitive: false,
      ).firstMatch(line);

      if (numberedMatch != null) {
        final name =
            numberedMatch.group(2)?.trim() ?? '';

        if (_looksLikeChapterName(name)) {
          result.add(
            _cleanChapterName(name),
          );
        }

        continue;
      }

      final chapterWordMatch = RegExp(
        r'^chapter\s+(\d{1,3})\s*[\.\):\-–—]?\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line);

      if (chapterWordMatch != null) {
        final name =
            chapterWordMatch.group(2)?.trim() ?? '';

        if (_looksLikeChapterName(name)) {
          result.add(
            _cleanChapterName(name),
          );
        }

        continue;
      }

      final zeroNumberMatch = RegExp(
        r'^0*(\d{1,3})\s+(.+)$',
      ).firstMatch(line);

      if (zeroNumberMatch != null) {
        final name =
            zeroNumberMatch.group(2)?.trim() ?? '';

        if (_looksLikeChapterName(name)) {
          result.add(
            _cleanChapterName(name),
          );
        }
      }
    }

    final seen = <String>{};
    final unique = <String>[];

    for (final chapter in result) {
      final key = chapter.toLowerCase();

      if (!seen.contains(key)) {
        seen.add(key);
        unique.add(chapter);
      }
    }

    return unique;
  }

  bool _looksLikeChapterName(String name) {
    if (name.length < 2) {
      return false;
    }

    final lower = name.toLowerCase();

    const ignored = [
      'contents',
      'content',
      'index',
      'page',
      'pages',
      'preface',
      'appendix',
      'answer',
      'answers',
      'exercise',
      'exercises',
      'bibliography',
      'references',
    ];

    return !ignored.contains(lower);
  }

  String _cleanChapterName(String name) {
    var value = name.trim();

    value = value.replaceFirst(
      RegExp(r'^[\-\u2022*]+\s*'),
      '',
    );

    value = value.replaceFirst(
      RegExp(r'\s+\.+\s*\d+\s*$'),
      '',
    );

    return value.trim();
  }

  // ============================================================
  // DETECTED CHAPTER REVIEW
  // ============================================================

  Future<List<String>?> _showDetectedChaptersDialog(
    List<String> chapters,
  ) async {
    final selected =
        List<bool>.filled(chapters.length, true);

    return showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final selectedCount =
                selected.where((value) => value).length;

            return _PremiumDialog(
              icon: Icons.fact_check_rounded,
              title: 'Review Chapters',
              subtitle:
                  '$selectedCount of ${chapters.length} selected',
              maxWidth: 680,
              maxHeight: 720,
              child: Column(
                children: [
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            for (int i = 0;
                                i < selected.length;
                                i++) {
                              selected[i] = true;
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.select_all_rounded,
                          size: 17,
                        ),
                        label:
                            const Text('Select all'),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            for (int i = 0;
                                i < selected.length;
                                i++) {
                              selected[i] = false;
                            }
                          });
                        },
                        child:
                            const Text('Clear'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: ListView.builder(
                      itemCount: chapters.length,
                      itemBuilder: (
                        context,
                        index,
                      ) {
                        final checked =
                            selected[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(
                            bottom: 8,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                              onTap: () {
                                setDialogState(() {
                                  selected[index] =
                                      !selected[index];
                                });
                              },
                              child:
                                  AnimatedContainer(
                                duration:
                                    const Duration(
                                  milliseconds: 150,
                                ),
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 13,
                                  vertical: 11,
                                ),
                                decoration:
                                    BoxDecoration(
                                  color: checked
                                      ? _violet
                                          .withOpacity(
                                          0.08,
                                        )
                                      : AppColors
                                          .surfaceLight,
                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                  border:
                                      Border.all(
                                    color: checked
                                        ? _violet
                                        : AppColors
                                            .cardBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      checked
                                          ? Icons
                                              .check_box_rounded
                                          : Icons
                                              .check_box_outline_blank_rounded,
                                      color: checked
                                          ? _violet
                                          : AppColors
                                              .textMuted,
                                    ),
                                    const SizedBox(
                                      width: 11,
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${index + 1}. ${chapters[index]}',
                                        style:
                                            GoogleFonts
                                                .inter(
                                          color: AppColors
                                              .textPrimary,
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 13),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                        child:
                            const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: selectedCount == 0
                            ? null
                            : () {
                                final result =
                                    <String>[];

                                for (int i = 0;
                                    i <
                                        chapters
                                            .length;
                                    i++) {
                                  if (selected[i]) {
                                    result.add(
                                      chapters[i],
                                    );
                                  }
                                }

                                Navigator.of(
                                  dialogContext,
                                ).pop(result);
                              },
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                        label:
                            const Text('Continue'),
                        style: _primaryButtonStyle(
                          disabled: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ASK SUBJECT
  // ============================================================

  Future<String?> _askSubjectName() async {
    final controller = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return _PremiumDialog(
            icon: Icons.folder_copy_rounded,
            title: 'Choose Subject',
            subtitle:
                'Where should these chapters be added?',
            maxWidth: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogTextField(
                  controller: controller,
                  hint: 'Example: Physics',
                  icon: Icons.auto_stories_rounded,
                  autofocus: true,
                  onSubmitted: () {
                    final value =
                        controller.text.trim();

                    if (value.isNotEmpty) {
                      Navigator.of(dialogContext)
                          .pop(value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext)
                            .pop();
                      },
                      child:
                          const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final value =
                            controller.text.trim();

                        if (value.isEmpty) return;

                        Navigator.of(dialogContext)
                            .pop(value);
                      },
                      style: _primaryButtonStyle(),
                      child:
                          const Text('Add Chapters'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  // ============================================================
  // IMPORT DETECTED CHAPTERS
  // ============================================================

  Future<void> _importDetectedChapters(
    String subjectName,
    List<String> chapters,
  ) async {
    if (_isImporting) return;

    setState(() {
      _isImporting = true;
    });

    try {
      final provider =
          context.read<SyllabusProvider>();

      Subject? subject =
          provider.findSubjectByName(subjectName);

      if (subject == null) {
        subject = await provider.addSubject(
          subjectName,
        );
      }

      int added = 0;

      for (final chapterName in chapters) {
        final existing =
            provider.findChapterByName(
          subjectId: subject.id,
          chapterName: chapterName,
        );

        if (existing != null) {
          continue;
        }

        await provider.addChapter(
          subjectId: subject.id,
          name: chapterName,
        );

        added++;
      }

      if (!mounted) return;

      _showSnackBar(
        added == 0
            ? 'All selected chapters already exist.'
            : '$added chapters added to $subjectName.',
        success: added > 0,
      );
    } catch (_) {
      if (!mounted) return;

      _showSnackBar(
        'Chapter import failed.',
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(top: 26),
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _searchQuery.isNotEmpty
              ? _violet.withOpacity(0.45)
              : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText:
              'Search subjects, chapters or steps...',
          hintStyle: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _violet,
            size: 24,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 19,
                  ),
                ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 19,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(List<Subject> subjects) {
    int chapterCount = 0;
    int completedCount = 0;

    for (final subject in subjects) {
      chapterCount += subject.chapters.length;

      for (final chapter in subject.chapters) {
        if (chapter.isStudyCompleted) {
          completedCount++;
        }
      }
    }

    final progress = chapterCount == 0
        ? 0.0
        : completedCount / chapterCount;

    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _violet.withOpacity(0.14),
            AppColors.cardBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: _violet.withOpacity(0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: _violet.withOpacity(0.13),
              borderRadius:
                  BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: _violet,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${subjects.length} '
                  '${subjects.length == 1 ? 'Subject' : 'Subjects'}'
                  '  •  $chapterCount Chapters',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor:
                        AppColors.surfaceLight,
                    valueColor:
                        AlwaysStoppedAnimation(
                      _violet,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 17),
          Text(
            '${(progress * 100).round()}%',
            style: GoogleFonts.inter(
              color: _violet,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBJECT CARD
  // ============================================================

  Widget _buildSubjectCard(
    Subject subject,
    int index,
  ) {
    final progress = _subjectProgress(subject);

    final completed = subject.chapters
        .where(
          (chapter) => chapter.isStudyCompleted,
        )
        .length;

    final chapterCount = subject.chapters.length;

    final start = (0.20 + index * 0.045)
        .clamp(0.0, 0.55);

    final end = (start + 0.50)
        .clamp(start + 0.05, 1.0);

    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        start,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding:
              const EdgeInsets.only(bottom: 15),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openSubject(subject),
              borderRadius:
                  BorderRadius.circular(23),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius:
                      BorderRadius.circular(23),
                  border: Border.all(
                    color: AppColors.cardBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 9),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration:
                              BoxDecoration(
                            gradient:
                                _premiumGradient,
                            borderRadius:
                                BorderRadius.circular(
                              18,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _violet
                                    .withOpacity(
                                  0.22,
                                ),
                                blurRadius: 17,
                                offset:
                                    const Offset(
                                  0,
                                  7,
                                ),
                              ),
                            ],
                          ),
                          child: Icon(
                            _subjectIcon(
                              subject.name,
                            ),
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.name,
                                maxLines: 1,
                                overflow:
                                    TextOverflow.ellipsis,
                                style:
                                    GoogleFonts.inter(
                                  color: AppColors
                                      .textPrimary,
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _subjectSubtitle(
                                  subject,
                                ),
                                style:
                                    GoogleFonts.inter(
                                  color: AppColors
                                      .textMuted,
                                  fontSize: 11,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        PopupMenuButton<String>(
                          color:
                              AppColors.cardBackground,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteSubject(subject);
                            }
                          },
                          itemBuilder:
                              (context) => [
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
                                    'Delete Subject',
                                    style:
                                        GoogleFonts.inter(
                                      color: AppColors
                                          .textPrimary,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.surfaceLight,
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: const Icon(
                              Icons.more_horiz_rounded,
                              color:
                                  AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 19),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Progress',
                                    style:
                                        GoogleFonts.inter(
                                      color: AppColors
                                          .textMuted,
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${(progress * 100).round()}%',
                                    style:
                                        GoogleFonts.inter(
                                      color: progress >=
                                              1
                                          ? AppColors.success
                                          : _violet,
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                  10,
                                ),
                                child:
                                    LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 7,
                                  backgroundColor:
                                      AppColors
                                          .surfaceLight,
                                  valueColor:
                                      AlwaysStoppedAnimation(
                                    progress >= 1
                                        ? AppColors.success
                                        : _violet,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.surfaceLight,
                            borderRadius:
                                BorderRadius.circular(
                              13,
                            ),
                          ),
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,
                            children: [
                              Icon(
                                Icons
                                    .check_circle_outline_rounded,
                                color: completed ==
                                            chapterCount &&
                                        chapterCount > 0
                                    ? AppColors.success
                                    : AppColors.textMuted,
                                size: 15,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$completed/$chapterCount',
                                style:
                                    GoogleFonts.inter(
                                  color: AppColors
                                      .textSecondary,
                                  fontSize: 10,
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Open subject',
                          style:
                              GoogleFonts.inter(
                            color: _violet,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: _violet,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState({
    required bool searching,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 48,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _violet.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              searching
                  ? Icons.search_off_rounded
                  : Icons.menu_book_rounded,
              color: _violet,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            searching
                ? 'No results found'
                : 'Your syllabus is empty',
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            searching
                ? 'Try a different subject, chapter or step.'
                : 'Add a subject or import an entire book.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (!searching) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddSubjectDialog,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label:
                  const Text('Add Subject'),
              style: _primaryButtonStyle(),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(
        0.0,
        0.45,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.08),
          end: Offset.zero,
        ).animate(animation),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Syllabus',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Build your syllabus. Track every chapter.',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            _headerAction(
              icon: Icons.library_books_rounded,
              label: 'Books',
              onTap: _showBookImportDialog,
            ),
            const SizedBox(width: 9),
            _headerAction(
              icon:
                  Icons.content_paste_search_rounded,
              label: 'Index',
              onTap: _showPasteIndexDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius:
                BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: _violet,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
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

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: _showAddSubjectDialog,
      backgroundColor: _violet,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add_rounded),
      label: Text(
        'Add Subject',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData _subjectIcon(String subject) {
    final lower = subject.toLowerCase();

    if (lower.contains('biology')) {
      return Icons.biotech_rounded;
    }

    if (lower.contains('chemistry')) {
      return Icons.science_rounded;
    }

    if (lower.contains('physics')) {
      return Icons.bolt_rounded;
    }

    if (lower.contains('math')) {
      return Icons.functions_rounded;
    }

    if (lower.contains('english')) {
      return Icons.translate_rounded;
    }

    if (lower.contains('hindi')) {
      return Icons.language_rounded;
    }

    return Icons.auto_stories_rounded;
  }

  // ============================================================
  // DIALOG HELPERS
  // ============================================================

  InputDecoration _dialogInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 12,
      ),
      prefixIcon: Icon(
        icon,
        color: _violet,
      ),
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: _violet.withOpacity(0.7),
        ),
      ),
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 17,
        vertical: 17,
      ),
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool autofocus = false,
    VoidCallback? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      style: GoogleFonts.inter(
        color: AppColors.textPrimary,
      ),
      decoration: _dialogInputDecoration(
        hint: hint,
        icon: icon,
      ),
      onSubmitted: (_) {
        onSubmitted?.call();
      },
    );
  }

  ButtonStyle _primaryButtonStyle({
    bool disabled = false,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: _violet,
      foregroundColor: Colors.white,
      disabledBackgroundColor:
          AppColors.surfaceLight,
      disabledForegroundColor:
          AppColors.textMuted,
      elevation: 0,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(15),
      ),
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
    String message, {
    bool success = true,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          backgroundColor:
              AppColors.cardBackground,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15),
          ),
          content: Row(
            children: [
              Icon(
                success
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,
                color: success
                    ? AppColors.success
                    : AppColors.danger,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.inter(
                    color:
                        AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // ICON BOX
  // ============================================================

  Widget _iconBox(
    IconData icon,
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _premiumGradient,
        borderRadius:
            BorderRadius.circular(
          size * 0.30,
        ),
        boxShadow: [
          BoxShadow(
            color:
                _violet.withOpacity(0.24),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.48,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Consumer<SyllabusProvider>(
      builder: (
        context,
        provider,
        child,
      ) {
        final subjects = provider.subjects;

        final filtered =
            _filteredSubjects(subjects);

        return Scaffold(
          backgroundColor:
              AppColors.background,
          floatingActionButton:
              _buildFab(),
          body: SafeArea(
            child: LayoutBuilder(
              builder:
                  (context, constraints) {
                final isWide =
                    constraints.maxWidth > 850;

                final horizontal =
                    isWide ? 42.0 : 18.0;

                return Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(
                      maxWidth: 1180,
                    ),
                    child:
                        CustomScrollView(
                      physics:
                          const BouncingScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding:
                              EdgeInsets.fromLTRB(
                            horizontal,
                            28,
                            horizontal,
                            110,
                          ),
                          sliver:
                              SliverList(
                            delegate:
                                SliverChildListDelegate(
                              [
                                _buildHeader(),

                                // Extra separation keeps
                                // the search bar from feeling
                                // attached to the header.
                                const SizedBox(height: 2),

                                _buildSearchBar(),

                                _buildSummary(
                                  subjects,
                                ),

                                const SizedBox(
                                  height: 30,
                                ),

                                Row(
                                  children: [
                                    Expanded(
                                      child:
                                          Text(
                                        _searchQuery
                                                .isEmpty
                                            ? 'Your Subjects'
                                            : 'Search Results',
                                        style:
                                            GoogleFonts
                                                .inter(
                                          color: AppColors
                                              .textPrimary,
                                          fontSize: 17,
                                          fontWeight:
                                              FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (_searchQuery
                                        .isNotEmpty)
                                      Text(
                                        '${filtered.length} found',
                                        style:
                                            GoogleFonts
                                                .inter(
                                          color: AppColors
                                              .textMuted,
                                          fontSize: 11,
                                          fontWeight:
                                              FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),

                                const SizedBox(
                                  height: 15,
                                ),

                                if (filtered.isEmpty)
                                  _buildEmptyState(
                                    searching:
                                        _searchQuery
                                            .isNotEmpty,
                                  )
                                else
                                  ...List.generate(
                                    filtered.length,
                                    (index) =>
                                        _buildSubjectCard(
                                      filtered[index],
                                      index,
                                    ),
                                  ),

                                if (_isImporting)
                                  Padding(
                                    padding:
                                        const EdgeInsets
                                            .only(
                                      top: 8,
                                    ),
                                    child:
                                        _importingIndicator(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _importingIndicator() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _violet.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: _violet.withOpacity(0.16),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation(
                _violet,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Text(
            'Importing syllabus...',
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// PREMIUM DIALOG
// ================================================================

class _PremiumDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final double maxWidth;
  final double maxHeight;

  const _PremiumDialog({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.maxWidth = 520,
    this.maxHeight = 620,
  });

  @override
  Widget build(BuildContext context) {
    final violet =
        const Color(0xff7667FF);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 22,
      ),
      child: Container(
        constraints:
            BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        padding:
            const EdgeInsets.all(23),
        decoration: BoxDecoration(
          color:
              AppColors.cardBackground,
          borderRadius:
              BorderRadius.circular(28),
          border: Border.all(
            color:
                violet.withOpacity(0.24),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(
                0.5,
              ),
              blurRadius: 40,
              offset:
                  const Offset(0, 20),
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
                _DialogIcon(
                  icon: icon,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            GoogleFonts.inter(
                          color: AppColors
                              .textPrimary,
                          fontSize: 21,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                      const SizedBox(
                          height: 4),
                      Text(
                        subtitle,
                        style:
                            GoogleFonts.inter(
                          color: AppColors
                              .textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 23),
            Expanded(
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// DIALOG ICON
// ================================================================

class _DialogIcon extends StatelessWidget {
  final IconData icon;

  const _DialogIcon({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    const violet =
        Color(0xff7667FF);
    const indigo =
        Color(0xff4D45C6);

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient:
            const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            indigo,
            violet,
          ],
        ),
        borderRadius:
            BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color:
                violet.withOpacity(0.24),
            blurRadius: 18,
            offset:
                const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
