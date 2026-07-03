import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/providers/tasks_provider.dart';

class AddTaskScreen extends ConsumerStatefulWidget {
  final Task? task;
  final int? projectId;

  const AddTaskScreen({super.key, this.task, this.projectId});

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _hasReminder = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    if (task != null) {
      _titleController.text = task.title;
      _descController.text = task.description;
      _priority = task.priority;
      _dueDate = task.dueDate;
      _hasReminder = task.hasReminder;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Tugas' : 'Tugas Baru'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Simpan',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            TextField(
              controller: _titleController,
              autofocus: true,
              style: theme.textTheme.titleLarge,
              decoration: const InputDecoration(
                hintText: 'Nama tugas...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const Divider(height: 24),

            // Description
            Text('Deskripsi', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(hintText: 'Tambah deskripsi...'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Priority
            Text('Prioritas', style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            Row(
              children: TaskPriority.values.map((p) {
                final isSelected = _priority == p;
                final color = _priorityColor(p);
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () => setState(() => _priority = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withOpacity(0.15)
                            : theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _priorityLabel(p),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected ? color : null,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Due date
            Text('Tenggat Waktu', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? DateHelper.formatDate(_dueDate!)
                          : 'Pilih tanggal (opsional)',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: _dueDate != null
                            ? null
                            : theme.hintColor,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close, size: 18),
                      )
                    else
                      const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Reminder toggle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Pengingat', style: theme.textTheme.bodyLarge),
                subtitle: Text('Notifikasi saat mendekati tenggat',
                    style: theme.textTheme.bodyMedium),
                value: _hasReminder,
                activeColor: AppColors.primary,
                onChanged: _dueDate != null
                    ? (v) => setState(() => _hasReminder = v)
                    : null,
              ),
            ),

            const SizedBox(height: 32),

            GlowButton(
              label: isEdit ? 'Simpan Perubahan' : 'Tambah Tugas',
              onPressed: _save,
            ),

            if (isEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _delete,
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger),
                  child: const Text('Hapus Tugas'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tugas tidak boleh kosong'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final task = widget.task ?? Task();
    task.title = _titleController.text.trim();
    task.description = _descController.text.trim();
    task.priority = _priority;
    task.dueDate = _dueDate;
    task.hasReminder = _hasReminder && _dueDate != null;
    task.projectId = widget.projectId;
    if (task.status == TaskStatus.todo || widget.task == null) {
      task.status = TaskStatus.todo;
    }

    await ref.read(tasksNotifierProvider.notifier).saveTask(task);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Tugas?'),
        content: Text('Tugas "${widget.task!.title}" akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref
          .read(tasksNotifierProvider.notifier)
          .deleteTask(widget.task!.id);
      Navigator.of(context).pop();
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low: return AppColors.priorityLow;
    }
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return 'Tinggi';
      case TaskPriority.medium: return 'Sedang';
      case TaskPriority.low: return 'Rendah';
    }
  }
}