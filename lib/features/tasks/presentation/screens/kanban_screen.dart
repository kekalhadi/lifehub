import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/providers/tasks_provider.dart';
import 'add_task_screen.dart';

class KanbanScreen extends ConsumerWidget {
  final Project? project;

  const KanbanScreen({super.key, this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = project?.title ?? 'Kanban Board';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AddTaskScreen(projectId: project?.id),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _KanbanColumn(
            status: TaskStatus.todo,
            label: 'To Do',
            color: AppColors.primary,
            icon: Icons.radio_button_unchecked,
            projectId: project?.id,
          ),
          _KanbanColumn(
            status: TaskStatus.inProgress,
            label: 'In Progress',
            color: AppColors.warning,
            icon: Icons.timelapse_rounded,
            projectId: project?.id,
          ),
          _KanbanColumn(
            status: TaskStatus.done,
            label: 'Done',
            color: AppColors.secondary,
            icon: Icons.check_circle_outline_rounded,
            projectId: project?.id,
          ),
        ],
      ),
    );
  }
}

class _KanbanColumn extends ConsumerWidget {
  final TaskStatus status;
  final String label;
  final Color color;
  final IconData icon;
  final int? projectId;

  const _KanbanColumn({
    required this.status,
    required this.label,
    required this.color,
    required this.icon,
    this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = TaskFilter(
      projectId: projectId,
      onlyStandalone: projectId == null,
      showCompleted: true,
      status: status,
    );
    final tasksAsync = ref.watch(allTasksStreamProvider(filter));

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column header
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color, fontSize: 12,
                      ),
                    ),
                  ),
                  tasksAsync.when(
                    data: (tasks) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tasks.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            // Task cards
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Tidak ada\ntugas',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    itemBuilder: (_, i) => _KanbanCard(
                      task: tasks[i],
                      columnColor: color,
                    ),
                  );
                },
              ),
            ),

            // Add button
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        AddTaskScreen(projectId: projectId),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: color.withOpacity(0.2),
                        style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: color, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Tambah',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanCard extends ConsumerWidget {
  final Task task;
  final Color columnColor;

  const _KanbanCard({required this.task, required this.columnColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final priorityColor = _priorityColor(task.priority);
    final isOverdue = task.dueDate != null &&
        DateHelper.isOverdue(task.dueDate!) &&
        !task.isCompleted;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AddTaskScreen(task: task)),
      ),
      onLongPress: () => _showStatusPicker(context, ref),
      child: GlassCard(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        radius: 10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (task.dueDate != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 10,
                    color: isOverdue
                        ? AppColors.danger
                        : theme.textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    DateHelper.formatShortDate(task.dueDate!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 10,
                      color: isOverdue ? AppColors.danger : null,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: priorityColor,
                  ),
                ),
                Text(
                  'Hold untuk pindah',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 9,
                    color: theme.textTheme.bodyMedium?.color
                        ?.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pindah ke kolom',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...TaskStatus.values.map((s) {
              final isCurrent = task.status == s;
              return ListTile(
                leading: Icon(
                  _statusIcon(s),
                  color: isCurrent ? _statusColor(s) : null,
                ),
                title: Text(_statusLabel(s)),
                trailing: isCurrent
                    ? const Icon(Icons.check, color: AppColors.secondary)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  ref
                      .read(tasksNotifierProvider.notifier)
                      .updateStatus(task, s);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low: return AppColors.priorityLow;
    }
  }

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo: return AppColors.primary;
      case TaskStatus.inProgress: return AppColors.warning;
      case TaskStatus.done: return AppColors.secondary;
    }
  }

  IconData _statusIcon(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo: return Icons.radio_button_unchecked;
      case TaskStatus.inProgress: return Icons.timelapse_rounded;
      case TaskStatus.done: return Icons.check_circle_outline_rounded;
    }
  }

  String _statusLabel(TaskStatus s) {
    switch (s) {
      case TaskStatus.todo: return 'To Do';
      case TaskStatus.inProgress: return 'In Progress';
      case TaskStatus.done: return 'Done';
    }
  }
}