import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/providers/tasks_provider.dart';
import '../../../../data/providers/database_provider.dart';
import 'add_task_screen.dart';

class KanbanScreen extends ConsumerStatefulWidget {
  final Project? project;

  const KanbanScreen({super.key, this.project});

  @override
  ConsumerState<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends ConsumerState<KanbanScreen> {
  int? _draggedTaskId;
  TaskStatus? _draggedFromStatus;

  // NEW: kolom mana yang sedang "aktif" (terkunci untuk scroll internal).
  // Hanya satu kolom yang bisa aktif dalam satu waktu.
  TaskStatus? _activeScrollStatus;

  void _activateColumn(TaskStatus status) {
    setState(() {
      _activeScrollStatus = _activeScrollStatus == status ? null : status;
    });
  }

  void _deactivateAll() {
    if (_activeScrollStatus != null) {
      setState(() => _activeScrollStatus = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.project?.title ?? 'Kanban Board';

    // NEW: GestureDetector terluar — tap di area kosong (header/app bar,
    // celah antar kolom, dsb) akan melepas status aktif kolom manapun.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _deactivateAll,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AddTaskScreen(projectId: widget.project?.id),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KanbanColumn(
                status: TaskStatus.todo,
                label: 'To Do',
                color: AppColors.primary,
                icon: Icons.radio_button_unchecked,
                projectId: widget.project?.id,
                draggedTaskId: _draggedTaskId,
                draggedFromStatus: _draggedFromStatus,
                isActive: _activeScrollStatus == TaskStatus.todo,
                onActivate: () => _activateColumn(TaskStatus.todo),
                onDragStarted: (taskId) {
                  setState(() {
                    _draggedTaskId = taskId;
                    _draggedFromStatus = TaskStatus.todo;
                  });
                },
                onDragEnded: () {
                  setState(() {
                    _draggedTaskId = null;
                    _draggedFromStatus = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              _KanbanColumn(
                status: TaskStatus.inProgress,
                label: 'In Progress',
                color: AppColors.warning,
                icon: Icons.timelapse_rounded,
                projectId: widget.project?.id,
                draggedTaskId: _draggedTaskId,
                draggedFromStatus: _draggedFromStatus,
                isActive: _activeScrollStatus == TaskStatus.inProgress,
                onActivate: () => _activateColumn(TaskStatus.inProgress),
                onDragStarted: (taskId) {
                  setState(() {
                    _draggedTaskId = taskId;
                    _draggedFromStatus = TaskStatus.inProgress;
                  });
                },
                onDragEnded: () {
                  setState(() {
                    _draggedTaskId = null;
                    _draggedFromStatus = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              _KanbanColumn(
                status: TaskStatus.done,
                label: 'Done',
                color: AppColors.secondary,
                icon: Icons.check_circle_outline_rounded,
                projectId: widget.project?.id,
                draggedTaskId: _draggedTaskId,
                draggedFromStatus: _draggedFromStatus,
                isActive: _activeScrollStatus == TaskStatus.done,
                onActivate: () => _activateColumn(TaskStatus.done),
                onDragStarted: (taskId) {
                  setState(() {
                    _draggedTaskId = taskId;
                    _draggedFromStatus = TaskStatus.done;
                  });
                },
                onDragEnded: () {
                  setState(() {
                    _draggedTaskId = null;
                    _draggedFromStatus = null;
                  });
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
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
  final int? draggedTaskId;
  final TaskStatus? draggedFromStatus;
  final bool isActive; // NEW
  final VoidCallback onActivate; // NEW
  final ValueChanged<int> onDragStarted;
  final VoidCallback onDragEnded;

  const _KanbanColumn({
    required this.status,
    required this.label,
    required this.color,
    required this.icon,
    this.projectId,
    this.draggedTaskId,
    this.draggedFromStatus,
    required this.isActive,
    required this.onActivate,
    required this.onDragStarted,
    required this.onDragEnded,
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

    return DragTarget<Map<String, dynamic>>(
      key: ValueKey('column_$status'),
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data['taskId'] == draggedTaskId && draggedFromStatus == status) {
          return false;
        }
        return true;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        final taskId = data['taskId'] as int;
        _moveTask(ref, taskId, status);
        onDragEnded();
      },
      onLeave: (_) {},
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        // NEW: tap di dalam kolom (header / background) mengaktifkan kolom
        // ini. Karena ini GestureDetector "anak", tap di sini tidak akan
        // memicu GestureDetector deaktivasi di level Scaffold.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onActivate,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(0, isActive ? -3 : 0, 0),
            decoration: BoxDecoration(
              color: isHovering
                  ? color.withOpacity(0.12)
                  : color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHovering
                    ? color.withOpacity(0.5)
                    : isActive
                        ? Colors.grey.shade400.withOpacity(0.7)
                        : color.withOpacity(0.2),
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Column header
                Container(
                  width: double.infinity,
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
                      // NEW: indikator aktif
                      // if (isActive) ...[
                      //   Container(
                      //     padding: const EdgeInsets.symmetric(
                      //         horizontal: 6, vertical: 2),
                      //     margin: const EdgeInsets.only(right: 6),
                      //     decoration: BoxDecoration(
                      //       color: color,
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: Row(
                      //       mainAxisSize: MainAxisSize.min,
                      //       children: [
                      //         const Icon(
                      //           Icons.swipe_vertical_rounded,
                      //           size: 10,
                      //           color: Colors.white,
                      //         ),
                      //         const SizedBox(width: 3),
                      //         Text(
                      //           'Aktif',
                      //           style: theme.textTheme.bodyMedium?.copyWith(
                      //             fontSize: 9,
                      //             color: Colors.white,
                      //             fontWeight: FontWeight.w700,
                      //           ),
                      //         ),
                      //       ],
                      //     ),
                      //   ),
                      // ],
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

                // Task cards — constrained height. Scroll internal hanya
                // aktif saat kolom "aktif" (physics), tapi card tetap bisa
                // di-tap/drag kapan pun, aktif ataupun tidak.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: tasksAsync.when(
                    loading: () => const SizedBox(
                      height: 60,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    error: (e, _) => SizedBox(
                      height: 60,
                      child: Center(child: Text('Error: $e')),
                    ),
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return SizedBox(
                          height: 60,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                isHovering ? 'Lepas di sini' : 'Tidak ada\ntugas',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  color: isHovering ? color : null,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                        shrinkWrap: true,
                        physics: isActive
                            ? const AlwaysScrollableScrollPhysics()
                            : const NeverScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final task = tasks[i];
                          if (task.id == draggedTaskId && draggedFromStatus == status) {
                            return Opacity(
                              opacity: 0.3,
                              child: _KanbanCard(task: task, columnColor: color),
                            );
                          }
                          return _DraggableKanbanCard(
                            task: task,
                            columnColor: color,
                            onDragStarted: () => onDragStarted(task.id),
                            onDragEnded: onDragEnded,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _moveTask(WidgetRef ref, int taskId, TaskStatus newStatus) async {
    final isar = await ref.read(isarProvider.future);
    final task = await isar.tasks.get(taskId);
    if (task != null && task.status != newStatus) {
      await ref.read(tasksNotifierProvider.notifier).updateStatus(task, newStatus);
    }
  }
}

class _DraggableKanbanCard extends StatelessWidget {
  final Task task;
  final Color columnColor;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;

  const _DraggableKanbanCard({
    required this.task,
    required this.columnColor,
    required this.onDragStarted,
    required this.onDragEnded,
  });

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Map<String, dynamic>>(
      data: {'taskId': task.id},
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: columnColor, width: 1),
          ),
          child: Text(
            task.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _KanbanCard(task: task, columnColor: columnColor),
      ),
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnded(),
      onDraggableCanceled: (_, __) => onDragEnded(),
      child: _KanbanCard(task: task, columnColor: columnColor),
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
      child: GlassCard(
        // margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        radius: 10,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
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
                ),
                const SizedBox(width: 4),
                Icon(Icons.drag_indicator_rounded, size: 16, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3)),
              ],
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
                  'Tahan & geser',
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

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low: return AppColors.priorityLow;
    }
  }
}