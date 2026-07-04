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

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _showCompleted = false;
  List<String> _selectedTags = [];
  bool _showTagFilter = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_kanban_outlined),
            tooltip: 'Kanban Board',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const KanbanScreen()),
            ),
          ),
          IconButton(
            icon: Icon(_showCompleted
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            tooltip: _showCompleted ? 'Sembunyikan selesai' : 'Tampilkan selesai',
            onPressed: () => setState(() => _showCompleted = !_showCompleted),
          ),
          IconButton(
            icon: Icon(_showTagFilter ? Icons.tag : Icons.tag_outlined),
            onPressed: () => setState(() => _showTagFilter = !_showTagFilter),
            tooltip: 'Filter berdasarkan Tag',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showTagFilter) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: ref.watch(tasksTagCountsProvider).when(
                loading: () => const SizedBox(
                    height: 30, child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(height: 30),
                data: (tagCounts) {
                  if (tagCounts.isEmpty) {
                    return const Text(
                      'Belum ada tag. Buat tugas dengan tag untuk mulai memfilter.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    );
                  }
                  return SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.zero,
                      itemCount: tagCounts.entries.take(10).length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        if (i == 0) {
                          return _TagFilterChip(
                            label: 'Semua',
                            isSelected: _selectedTags.isEmpty,
                            onTap: () => setState(() => _selectedTags = []),
                          );
                        }
                        final e = tagCounts.entries.take(10).toList()[i - 1];
                        return _TagFilterChip(
                          label: '#${e.key}',
                          isSelected: _selectedTags.contains(e.key),
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
          ],
          Expanded(
            child: _DailyTasksTab(
              showCompleted: _showCompleted,
              selectedTags: _selectedTags,
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

// ─── Daily Tasks Tab ──────────────────────────────────────────────────────────

class _DailyTasksTab extends ConsumerWidget {
  final bool showCompleted;
  final List<String> selectedTags;

  const _DailyTasksTab({required this.showCompleted, required this.selectedTags});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = TaskFilter(onlyStandalone: true, showCompleted: showCompleted);
    final tasksAsync = ref.watch(allTasksStreamProvider(filter));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        List<Task> filtered = tasks;

        if (selectedTags.isNotEmpty) {
          filtered = filtered
              .where((t) => selectedTags.any((tag) => t.tags.contains(tag)))
              .toList();
        }

        if (filtered.isEmpty) {
          return const _EmptyTasks();
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
  const _EmptyTasks();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconBox(
            icon: Icons.task_alt_outlined,
            size: 72,
            iconSize: 36,
            radius: 20,
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada tugas hari ini\nTap + untuk tambah tugas',
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
