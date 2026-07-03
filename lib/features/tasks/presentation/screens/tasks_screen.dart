import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/models/task_model.dart';
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
        ],
      ),
      body: _DailyTasksTab(showCompleted: _showCompleted),
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

  const _DailyTasksTab({required this.showCompleted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = TaskFilter(onlyStandalone: true, showCompleted: showCompleted);
    final tasksAsync = ref.watch(allTasksStreamProvider(filter));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return const _EmptyTasks();
        }

        // Group by priority
        final highPriority =
        tasks.where((t) => t.priority == TaskPriority.high).toList();
        final medPriority =
        tasks.where((t) => t.priority == TaskPriority.medium).toList();
        final lowPriority =
        tasks.where((t) => t.priority == TaskPriority.low).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            if (highPriority.isNotEmpty) ...[
              _PriorityLabel(
                  label: '🔴 Prioritas Tinggi',
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
                  label: '🟡 Prioritas Sedang',
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
                  label: '🟢 Prioritas Rendah',
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
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOverdue
                  ? AppColors.danger.withOpacity(0.3)
                  : theme.dividerColor,
            ),
          ),
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
    return Text(label, style: theme.textTheme.labelLarge?.copyWith(color: color));
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
          const Text('✅', style: TextStyle(fontSize: 64)),
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