import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/providers/notes_provider.dart';
import '../../../../data/providers/tasks_provider.dart';
import 'add_task_screen.dart';
import 'kanban_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> _selectedTags = [];
  bool _showTagFilter = false;
  TaskPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedPriority = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  TaskStatus? get _currentStatus {
    if (_tabController.index == 0) return null;
    if (_tabController.index == 1) return TaskStatus.todo;
    if (_tabController.index == 2) return TaskStatus.inProgress;
    if (_tabController.index == 3) return TaskStatus.done;
    return null;
  }

  bool get hasFilters =>
      _selectedTags.isNotEmpty || _selectedPriority != null;

  void _clearFilters() {
    setState(() {
      _selectedTags = [];
      _selectedPriority = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas'),
        actions: [
          if (hasFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Reset', style: TextStyle(fontSize: 13)),
            ),
          IconButton(
            icon: const Icon(Icons.view_kanban_outlined),
            tooltip: 'Kanban Board',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KanbanScreen()),
            ),
          ),
          IconButton(
            icon: Icon(_showTagFilter ? Icons.tag : Icons.tag_outlined),
            onPressed: () => setState(() => _showTagFilter = !_showTagFilter),
            tooltip: 'Filter berdasarkan Tag',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Column(
            children: [
              // Status Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: TabBar(
                  controller: _tabController,
                  labelColor: theme.textTheme.bodyLarge?.color,
                  unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  tabs: const [
                    Tab(text: 'Semua'),
                    Tab(text: 'To Do'),
                    Tab(text: 'In Progress'),
                    Tab(text: 'Done'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Tag Filter
          if (_showTagFilter) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: ref
                  .watch(tasksTagCountsProvider(_currentStatus))
                  .when(
                    loading: () => const SizedBox(
                        height: 32, child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(height: 32),
                    data: (tagCounts) {
                      if (tagCounts.isEmpty) {
                        return const Text(
                          'Belum ada tag.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey),
                        );
                      }
                      return SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          itemCount:
                              tagCounts.entries.take(10).length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 6),
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return _TagFilterChip(
                                label: 'Semua',
                                isSelected: _selectedTags.isEmpty,
                                onTap: () => setState(
                                    () => _selectedTags = []),
                              );
                            }
                            final e = tagCounts.entries
                                .take(10)
                                .toList()[i - 1];
                            return _TagFilterChip(
                              label: '#${e.key}',
                              isSelected:
                                  _selectedTags.contains(e.key),
                              onTap: () {
                                setState(() {
                                  if (_selectedTags.contains(e.key)) {
                                    _selectedTags.remove(e.key);
                                  } else {
                                    _selectedTags.add(e.key);
                                  }
                                });
                              },
                              count: e.value,
                            );
                          },
                        ),
                      );
                    },
                  ),
            ),
            const SizedBox(height: 4),
          ],

          // Priority Dropdown (kanan bawah)
          Padding(
            padding: EdgeInsets.only(
              top: _showTagFilter ? 8 : 12,
              right: 16,
              bottom: 4,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: _PriorityDropdown(
                selected: _selectedPriority,
                onChanged: (v) =>
                    setState(() => _selectedPriority = v),
              ),
            ),
          ),
          Expanded(
            child: _TaskListTab(
              status: _currentStatus,
              showCompleted:
                  _currentStatus == null || _currentStatus == TaskStatus.done,
              selectedTags: _selectedTags,
              selectedPriority: _selectedPriority,
              hasFilters: hasFilters,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'tasks_fab',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddTaskScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Priority Dropdown ─────────────────────────────────────────────────────

class _PriorityDropdown extends StatelessWidget {
  final TaskPriority? selected;
  final ValueChanged<TaskPriority?> onChanged;

  const _PriorityDropdown({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final items = <TaskPriority?>[
      null,
      TaskPriority.high,
      TaskPriority.medium,
      TaskPriority.low,
    ];

    final labels = {
      null: 'Semua Prioritas',
      TaskPriority.high: 'Prioritas Tinggi',
      TaskPriority.medium: 'Prioritas Sedang',
      TaskPriority.low: 'Prioritas Rendah',
    };

    final colors = {
      null: null,
      TaskPriority.high: AppColors.priorityHigh,
      TaskPriority.medium: AppColors.priorityMedium,
      TaskPriority.low: AppColors.priorityLow,
    };

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected != null
              ? colors[selected]!.withOpacity(0.4)
              : theme.dividerColor.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskPriority?>(
          value: selected,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
          items: items.map((p) {
            final color = colors[p];
            final hasPriority = p != null;
            return DropdownMenuItem<TaskPriority?>(
              value: p,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPriority) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    Icon(Icons.tune_rounded,
                        size: 16, color: theme.textTheme.bodyMedium?.color),
                    const SizedBox(width: 8),
                  ],
                  Text(labels[p]!),
                ],
              ),
            );
          }).toList(),
          onChanged: (v) => onChanged(v),
        ),
      ),
    );
  }
}

// ─── Task List Tab ─────────────────────────────────────────────────────────

class _TaskListTab extends ConsumerWidget {
  final TaskStatus? status;
  final bool showCompleted;
  final List<String> selectedTags;
  final TaskPriority? selectedPriority;
  final bool hasFilters;

  const _TaskListTab({
    required this.status,
    required this.showCompleted,
    required this.selectedTags,
    required this.selectedPriority,
    required this.hasFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = TaskFilter(
      onlyStandalone: true,
      showCompleted: showCompleted,
      status: status,
    );
    final tasksAsync = ref.watch(allTasksStreamProvider(filter));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        List<Task> filtered = tasks;

        if (selectedPriority != null) {
          filtered =
              filtered.where((t) => t.priority == selectedPriority).toList();
        }

        if (selectedTags.isNotEmpty) {
          filtered = filtered
              .where((t) => selectedTags.any((tag) => t.tags.contains(tag)))
              .toList();
        }

        if (filtered.isEmpty) {
          return _EmptyTasks(hasFilters: hasFilters);
        }

        final highPriority =
            filtered.where((t) => t.priority == TaskPriority.high).toList();
        final medPriority =
            filtered.where((t) => t.priority == TaskPriority.medium).toList();
        final lowPriority =
            filtered.where((t) => t.priority == TaskPriority.low).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            if (highPriority.isNotEmpty) ...[
              _PriorityLabel(
                  label: 'Prioritas Tinggi',
                  color: AppColors.priorityHigh),
              const SizedBox(height: 8),
              ...highPriority.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TaskCard(task: t),
                  )),
              const SizedBox(height: 8),
            ],
            if (medPriority.isNotEmpty) ...[
              _PriorityLabel(
                  label: 'Prioritas Sedang',
                  color: AppColors.priorityMedium),
              const SizedBox(height: 8),
              ...medPriority.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TaskCard(task: t),
                  )),
              const SizedBox(height: 8),
            ],
            if (lowPriority.isNotEmpty) ...[
              _PriorityLabel(
                  label: 'Prioritas Rendah',
                  color: AppColors.priorityLow),
              const SizedBox(height: 8),
              ...lowPriority.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _TaskCard(task: t),
                  )),
            ],
          ],
        );
      },
    );
  }
}

// ─── Shared Task Card ─────────────────────────────────────────────────────────

class _TaskCard extends ConsumerWidget {
  final Task task;
  final bool showProject;

  const _TaskCard({required this.task, this.showProject = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final priorityColor = _priorityColor(task.priority);
    final isOverdue = task.dueDate != null &&
        DateHelper.isOverdue(task.dueDate!) &&
        !task.isCompleted;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      onDismissed: (_) =>
          ref.read(tasksNotifierProvider.notifier).deleteTask(task.id),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
              builder: (_) => AddTaskScreen(task: task)),
        ),
        child: GlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => ref
                    .read(tasksNotifierProvider.notifier)
                    .toggleComplete(task),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: task.isCompleted
                          ? AppColors.secondary
                          : priorityColor,
                      width: 2,
                    ),
                    color: task.isCompleted
                        ? AppColors.secondary
                        : Colors.transparent,
                  ),
                  child: task.isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                        color: task.isCompleted
                            ? theme.textTheme.bodyMedium?.color
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.description.isNotEmpty)
                      Text(
                        task.description,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (task.tags.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        task.tags.map((t) => '#$t').join(' '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (task.dueDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 12,
                            color: isOverdue
                                ? AppColors.danger
                                : theme.textTheme.bodyMedium?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateHelper.formatDate(task.dueDate!),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              color: isOverdue ? AppColors.danger : null,
                              fontWeight: isOverdue ? FontWeight.w600 : null,
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 4),
                            Text(
                              '• Lewat!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: priorityColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high: return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low: return AppColors.priorityLow;
    }
  }
}

class _PriorityLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelLarge?.copyWith(color: color)),
      ],
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  final bool hasFilters;

  const _EmptyTasks({this.hasFilters = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconBox(
            icon: hasFilters
                ? Icons.search_off_rounded
                : Icons.task_alt_outlined,
            size: 72,
            iconSize: 36,
            radius: 20,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'Tidak ada tugas yang cocok dengan filter'
                : 'Tidak ada tugas hari ini\nTap + untuk tambah tugas',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
class _TagFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _TagFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: isSelected ? AppColors.black : theme.textTheme.bodyMedium?.color,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.black.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: isSelected ? AppColors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Card flat gelap solid — senada dengan gaya card di Dashboard & Catatan.
class _FlatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _FlatCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1F),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
