import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/providers/profile_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final missedAsync = ref.watch(missedTasksProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifikasi'),
      ),
      body: missedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text('Gagal memuat notifikasi',
              style: theme.textTheme.bodyMedium),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surface,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 32,
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Semua tugas sudah selesai!',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tidak ada tugas yang terlewat.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final task = item['task'] as Task;
              final overdueDays = item['overdueDays'] as int;

              return _MissedTaskCard(task: task, overdueDays: overdueDays);
            },
          );
        },
      ),
    );
  }
}

class _MissedTaskCard extends StatelessWidget {
  final Task task;
  final int overdueDays;

  const _MissedTaskCard({required this.task, required this.overdueDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _priorityIcon(task.priority),
                color: Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 12,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Terlewat $overdueDays hari',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.gray400,
                          fontSize: 11,
                        ),
                      ),
                      if (task.dueDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('d MMM', 'id_ID').format(task.dueDate!),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _priorityLabel(task.priority),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _priorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Icons.flag;
      case TaskPriority.medium:
        return Icons.flag_outlined;
      case TaskPriority.low:
        return Icons.outlined_flag;
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'Tinggi';
      case TaskPriority.medium:
        return 'Sedang';
      case TaskPriority.low:
        return 'Rendah';
    }
  }
}
