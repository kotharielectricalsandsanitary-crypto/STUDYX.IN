import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../theme/app_colors.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabScale;

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
  // ADD TASK DIALOG
  // ============================================================

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    DateTime? deadline;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
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
                      AppColors.cardBackground.withOpacity(0.94),
                      AppColors.background,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 45,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 35,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withOpacity(0.28),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_task_rounded,
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
                                'Create Task',
                                style: GoogleFonts.inter(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Add something you want to accomplish.',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
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

                    // ==================================================
                    // TASK NAME
                    // ==================================================

                    Text(
                      'Task name',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: titleController,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'e.g. Complete Biology revision',
                        prefixIcon: const Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==================================================
                    // DEADLINE
                    // ==================================================

                    Text(
                      'Deadline',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    InkWell(
                      onTap: () async {
                        final now = DateTime.now();

                        final selected = await showDatePicker(
                          context: dialogContext,
                          initialDate: deadline ?? now,
                          firstDate: DateTime(
                            now.year,
                            now.month,
                            now.day,
                          ),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: Theme.of(context)
                                    .colorScheme
                                    .copyWith(
                                      primary: AppColors.primary,
                                      surface:
                                          AppColors.cardBackground,
                                    ),
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (selected != null) {
                          setDialogState(() {
                            deadline = selected;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: deadline == null
                              ? AppColors.surfaceLight
                              : AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: deadline == null
                                ? AppColors.cardBorder
                                : AppColors.primary.withOpacity(0.30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withOpacity(0.10),
                                borderRadius:
                                    BorderRadius.circular(11),
                              ),
                              child: Icon(
                                Icons.calendar_month_rounded,
                                size: 18,
                                color: deadline == null
                                    ? AppColors.textMuted
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deadline == null
                                        ? 'Choose deadline'
                                        : _formatFullDate(deadline!),
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: deadline == null
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    deadline == null
                                        ? 'When should this task be completed?'
                                        : _deadlineDescription(
                                            deadline!,
                                          ),
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // ACTIONS
                    // ==================================================

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final title =
                                  titleController.text.trim();

                              if (title.isEmpty) {
                                _showMessage(
                                  'Please enter a task name.',
                                );
                                return;
                              }

                              if (deadline == null) {
                                _showMessage(
                                  'Please select a deadline.',
                                );
                                return;
                              }

                              final taskProvider =
                                  context.read<TaskProvider>();

                              Navigator.of(dialogContext).pop();

                              await taskProvider.createTask(
                                title: title,
                                deadline: deadline!,
                              );

                              if (!mounted) return;

                              _showMessage(
                                'Task created successfully.',
                              );
                            },
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 17,
                            ),
                            label: const Text('Create Task'),
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
    ).then((_) {
      titleController.dispose();
    });
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }

  bool _isToday(DateTime date) {
    return _dateOnly(date) == _dateOnly(DateTime.now());
  }

  bool _isTomorrow(DateTime date) {
    final tomorrow = _dateOnly(
      DateTime.now().add(
        const Duration(days: 1),
      ),
    );

    return _dateOnly(date) == tomorrow;
  }

  bool _isOverdue(DateTime date) {
    return _dateOnly(date).isBefore(
      _dateOnly(DateTime.now()),
    );
  }

  // ============================================================
  // SORT
  // ============================================================

  List<TaskModel> _sortTasks(List<TaskModel> tasks) {
    final result = [...tasks];

    result.sort((a, b) {
      final aDate = _dateOnly(a.deadline);
      final bDate = _dateOnly(b.deadline);
      final today = _dateOnly(DateTime.now());

      int category(DateTime date) {
        if (date.isBefore(today)) return 0;
        if (date == today) return 1;
        if (date == today.add(const Duration(days: 1))) return 2;
        return 3;
      }

      final categoryCompare =
          category(aDate).compareTo(category(bDate));

      if (categoryCompare != 0) {
        return categoryCompare;
      }

      final priorityCompare =
          b.priority.compareTo(a.priority);

      if (priorityCompare != 0) {
        return priorityCompare;
      }

      return a.deadline.compareTo(b.deadline);
    });

    return result;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final isDesktop = width >= 1000;
    final horizontalPadding = isDesktop ? 34.0 : 18.0;

    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        final pendingTasks = provider.pendingTasks;
        final tasks = _sortTasks(pendingTasks);

        return Scaffold(
          backgroundColor: Colors.transparent,

          body: SafeArea(
            child: tasks.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      18,
                      horizontalPadding,
                      120,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 1150,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            _buildPageHeader(provider),

                            const SizedBox(height: 22),

                            _buildTaskSummary(provider),

                            const SizedBox(height: 24),

                            ..._buildTaskSections(
                              tasks,
                              provider,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),

          floatingActionButton: ScaleTransition(
            scale: _fabScale,
            child: _buildFloatingActionButton(),
          ),
        );
      },
    );
  }

  // ============================================================
  // PAGE HEADER
  // ============================================================

  Widget _buildPageHeader(TaskProvider provider) {
    final pending = provider.pendingTasks.length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.primary.withOpacity(0.25),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.task_alt_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Tasks',
                    style: GoogleFonts.inter(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pending == 0
                    ? 'Everything is completed.'
                    : '$pending task${pending == 1 ? '' : 's'} waiting for you.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        _headerCountBadge(pending),
      ],
    );
  }

  Widget _headerCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 7),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildTaskSummary(TaskProvider provider) {
    final pending = provider.pendingTasks;

    final overdue =
        pending.where((task) => _isOverdue(task.deadline)).length;

    final today =
        pending.where((task) => _isToday(task.deadline)).length;

    final upcoming = pending.where((task) {
      return !_isOverdue(task.deadline) &&
          !_isToday(task.deadline);
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.10),
            AppColors.cardBackground.withOpacity(0.88),
            AppColors.background.withOpacity(0.45),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.13),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 450;

          if (compact) {
            return Wrap(
              spacing: 18,
              runSpacing: 15,
              children: [
                _summaryItem(
                  'Pending',
                  '$pending',
                  Icons.pending_actions_rounded,
                  AppColors.primary,
                ),
                _summaryItem(
                  'Today',
                  '$today',
                  Icons.today_rounded,
                  AppColors.accent,
                ),
                _summaryItem(
                  'Overdue',
                  '$overdue',
                  Icons.warning_amber_rounded,
                  AppColors.danger,
                ),
                _summaryItem(
                  'Upcoming',
                  '$upcoming',
                  Icons.calendar_month_rounded,
                  AppColors.success,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: _summaryItem(
                  'Pending',
                  '$pending',
                  Icons.pending_actions_rounded,
                  AppColors.primary,
                ),
              ),
              _summaryVerticalDivider(),
              Expanded(
                child: _summaryItem(
                  'Today',
                  '$today',
                  Icons.today_rounded,
                  AppColors.accent,
                ),
              ),
              _summaryVerticalDivider(),
              Expanded(
                child: _summaryItem(
                  'Overdue',
                  '$overdue',
                  Icons.warning_amber_rounded,
                  AppColors.danger,
                ),
              ),
              _summaryVerticalDivider(),
              Expanded(
                child: _summaryItem(
                  'Upcoming',
                  '$upcoming',
                  Icons.calendar_month_rounded,
                  AppColors.success,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.09),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: color.withOpacity(0.12),
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryVerticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.cardBorder,
    );
  }

  // ============================================================
  // TASK SECTIONS
  // ============================================================

  List<Widget> _buildTaskSections(
    List<TaskModel> tasks,
    TaskProvider provider,
  ) {
    final overdue = tasks
        .where((task) => _isOverdue(task.deadline))
        .toList();

    final today = tasks
        .where((task) => _isToday(task.deadline))
        .toList();

    final tomorrow = tasks
        .where((task) => _isTomorrow(task.deadline))
        .toList();

    final upcoming = tasks.where((task) {
      return !_isOverdue(task.deadline) &&
          !_isToday(task.deadline) &&
          !_isTomorrow(task.deadline);
    }).toList();

    final widgets = <Widget>[];

    if (overdue.isNotEmpty) {
      widgets.add(
        _buildSection(
          title: 'Overdue',
          subtitle: 'Needs your attention',
          icon: Icons.warning_amber_rounded,
          color: AppColors.danger,
          tasks: overdue,
          provider: provider,
        ),
      );
    }

    if (today.isNotEmpty) {
      widgets.add(
        _buildSection(
          title: 'Today',
          subtitle: 'Focus on these first',
          icon: Icons.today_rounded,
          color: AppColors.primary,
          tasks: today,
          provider: provider,
        ),
      );
    }

    if (tomorrow.isNotEmpty) {
      widgets.add(
        _buildSection(
          title: 'Tomorrow',
          subtitle: 'Prepare ahead',
          icon: Icons.event_rounded,
          color: AppColors.warning,
          tasks: tomorrow,
          provider: provider,
        ),
      );
    }

    if (upcoming.isNotEmpty) {
      widgets.add(
        _buildSection(
          title: 'Upcoming',
          subtitle: 'Plan your next moves',
          icon: Icons.calendar_month_rounded,
          color: AppColors.accent,
          tasks: upcoming,
          provider: provider,
        ),
      );
    }

    return widgets;
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<TaskModel> tasks,
    required TaskProvider provider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 2,
            right: 2,
            bottom: 12,
          ),
          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: color.withOpacity(0.13),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.09),
                            borderRadius:
                                BorderRadius.circular(7),
                          ),
                          child: Text(
                            '${tasks.length}',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        ...List.generate(
          tasks.length,
          (index) {
            final task = tasks[index];

            return _AnimatedTaskCard(
              key: ValueKey(task.id),
              index: index,
              child: _buildTaskCard(
                task,
                provider,
              ),
            );
          },
        ),

        const SizedBox(height: 13),
      ],
    );
  }

  // ============================================================
  // TASK CARD
  // ============================================================

  Widget _buildTaskCard(
    TaskModel task,
    TaskProvider provider,
  ) {
    final overdue = _isOverdue(task.deadline);
    final today = _isToday(task.deadline);
    final tomorrow = _isTomorrow(task.deadline);

    final priorityColor = _priorityColor(task.priority);

    final accentColor = overdue
        ? AppColors.danger
        : today
            ? AppColors.primary
            : tomorrow
                ? AppColors.warning
                : AppColors.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.cardBackground.withOpacity(0.82),
            AppColors.background.withOpacity(0.28),
          ],
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: overdue
              ? AppColors.danger.withOpacity(0.22)
              : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ==================================================
              // ACCENT LINE
              // ==================================================

              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 3,
                decoration: BoxDecoration(
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),

              // ==================================================
              // CONTENT
              // ==================================================

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    8,
                    13,
                    10,
                    13,
                  ),
                  child: Row(
                    children: [
                      // ==================================================
                      // CHECKBOX
                      // ==================================================

                      _PremiumTaskCheckbox(
                        onChanged: (value) {
                          if (value == true) {
                            provider.toggleTask(
                              task.id,
                              true,
                            );
                          }
                        },
                      ),

                      const SizedBox(width: 10),

                      // ==================================================
                      // TASK INFORMATION
                      // ==================================================

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight:
                                    FontWeight.w700,
                                color:
                                    AppColors.textPrimary,
                                height: 1.3,
                                letterSpacing: -0.1,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Wrap(
                              spacing: 7,
                              runSpacing: 6,
                              children: [
                                _deadlineBadge(
                                  task.deadline,
                                  overdue: overdue,
                                  today: today,
                                  tomorrow: tomorrow,
                                ),
                                _priorityBadge(
                                  task.priority,
                                  priorityColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 5),

                      // ==================================================
                      // DELETE
                      // ==================================================

                      _iconActionButton(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        tooltip: 'Delete task',
                        onTap: () {
                          _confirmDelete(
                            task.id,
                            task.title,
                            provider,
                          );
                        },
                      ),
                    ],
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
  // DEADLINE BADGE
  // ============================================================

  Widget _deadlineBadge(
    DateTime deadline, {
    required bool overdue,
    required bool today,
    required bool tomorrow,
  }) {
    final color = overdue
        ? AppColors.danger
        : today
            ? AppColors.primary
            : tomorrow
                ? AppColors.warning
                : AppColors.textSecondary;

    final icon = overdue
        ? Icons.warning_amber_rounded
        : today
            ? Icons.today_rounded
            : tomorrow
                ? Icons.event_rounded
                : Icons.calendar_today_outlined;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.11),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            _deadlineText(deadline),
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRIORITY BADGE
  // ============================================================

  Widget _priorityBadge(
    int priority,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.11),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bolt_rounded,
            size: 11,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            'Priority $priority',
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 440,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0.82,
                  end: 1,
                ),
                duration: const Duration(
                  milliseconds: 700,
                ),
                curve: Curves.easeOutBack,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary.withOpacity(0.16),
                        AppColors.accent.withOpacity(0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(31),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.primary.withOpacity(0.12),
                        blurRadius: 35,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Text(
                'No Pending Tasks',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.7,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                'Your task list is clear. Create a new task and keep your study plan moving.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: _showAddTaskDialog,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text('Create Task'),
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        icon: const Icon(
          Icons.add_rounded,
          size: 20,
        ),
        label: Text(
          'Add Task',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ICON BUTTON
  // ============================================================

  Widget _iconActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: color.withOpacity(0.06),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: color.withOpacity(0.10),
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color: color.withOpacity(0.82),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRIORITY COLOR
  // ============================================================

  Color _priorityColor(int priority) {
    if (priority >= 8) {
      return AppColors.danger;
    }

    if (priority >= 5) {
      return AppColors.warning;
    }

    return AppColors.success;
  }

  // ============================================================
  // DEADLINE TEXT
  // ============================================================

  String _deadlineText(DateTime deadline) {
    if (_isOverdue(deadline)) {
      return 'Overdue • ${deadline.day}/${deadline.month}';
    }

    if (_isToday(deadline)) {
      return 'Today';
    }

    if (_isTomorrow(deadline)) {
      return 'Tomorrow';
    }

    return '${deadline.day}/${deadline.month}/${deadline.year}';
  }

  String _formatFullDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _deadlineDescription(DateTime deadline) {
    if (_isToday(deadline)) {
      return 'Due today';
    }

    if (_isTomorrow(deadline)) {
      return 'Due tomorrow';
    }

    if (_isOverdue(deadline)) {
      return 'This deadline has passed';
    }

    final difference =
        _dateOnly(deadline).difference(
      _dateOnly(DateTime.now()),
    );

    return 'Due in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
  }

  // ============================================================
  // DELETE
  // ============================================================

  void _confirmDelete(
    String taskId,
    String taskTitle,
    TaskProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cardBackground,
                  AppColors.background,
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.danger.withOpacity(0.18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.45),
                  blurRadius: 40,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: AppColors.danger.withOpacity(0.13),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                    size: 25,
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  'Delete Task?',
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Are you sure you want to delete this task?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 13),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    taskTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 21),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        onPressed: () async {
                          await provider.deleteTask(taskId);

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }

                          if (!mounted) return;

                          _showMessage(
                            'Task deleted.',
                          );
                        },
                        child: const Text('Delete'),
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
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
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
// ANIMATED TASK CARD
// ============================================================================

class _AnimatedTaskCard extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedTaskCard({
    super.key,
    required this.index,
    required this.child,
  });

  @override
  State<_AnimatedTaskCard> createState() =>
      _AnimatedTaskCardState();
}

class _AnimatedTaskCardState
    extends State<_AnimatedTaskCard>
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
      duration: Duration(
        milliseconds: 420 + (widget.index * 60),
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _scale = Tween<double>(
      begin: 0.97,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      Duration(
        milliseconds: widget.index * 45,
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

// ============================================================================
// PREMIUM CHECKBOX
// ============================================================================

class _PremiumTaskCheckbox extends StatefulWidget {
  final ValueChanged<bool?> onChanged;

  const _PremiumTaskCheckbox({
    required this.onChanged,
  });

  @override
  State<_PremiumTaskCheckbox> createState() =>
      _PremiumTaskCheckboxState();
}

class _PremiumTaskCheckboxState
    extends State<_PremiumTaskCheckbox> {
  bool _checked = false;

  void _toggle() {
    if (_checked) return;

    setState(() {
      _checked = true;
    });

    widget.onChanged(true);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _checked
              ? AppColors.primary
              : AppColors.background.withOpacity(0.65),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _checked
                ? AppColors.primary
                : AppColors.cardBorder,
            width: 1.2,
          ),
          boxShadow: _checked
              ? [
                  BoxShadow(
                    color:
                        AppColors.primary.withOpacity(0.30),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _checked
              ? const Icon(
                  Icons.check_rounded,
                  key: ValueKey('checked'),
                  color: Colors.white,
                  size: 18,
                )
              : const SizedBox(
                  key: ValueKey('empty'),
                ),
        ),
      ),
    );
  }
}