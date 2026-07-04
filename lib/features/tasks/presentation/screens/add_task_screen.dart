import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/tag_autocomplete_field.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/tasks_provider.dart';
import '../../../../data/providers/finance_provider.dart';

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
  final _amountController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  bool _hasReminder = false;
  List<String> _tags = [];

  // Budget integration
  bool _hasBudget = false;
  String _budgetType = 'expense';
  String? _selectedBudgetCategoryName;
  String? _selectedBudgetCategoryIcon;
  String? _selectedBudgetWalletName;

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
      _tags = List.from(task.tags);
      _hasBudget = task.hasBudget;
      _budgetType = task.budgetType ?? 'expense';
      _amountController.text = task.budgetAmount?.toStringAsFixed(0) ?? '';
      _selectedBudgetCategoryName = task.budgetCategoryName;
      _selectedBudgetCategoryIcon = task.budgetCategoryIcon;
      _selectedBudgetWalletName = task.budgetWalletName;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _amountController.dispose();
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

            const SizedBox(height: 20),

            // Tags
            Text('Tag', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TagAutocompleteField(
              selectedTags: _tags,
              onTagsChanged: (tags) => setState(() => _tags = tags),
            ),

            const SizedBox(height: 24),

            // Budget Toggle
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Anggaran', style: theme.textTheme.bodyLarge),
                subtitle: Text('Hubungkan tugas dengan transaksi keuangan',
                    style: theme.textTheme.bodyMedium),
                value: _hasBudget,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _hasBudget = v),
              ),
            ),

            if (_hasBudget) ...[
              const SizedBox(height: 16),

              // Budget Type
              Text('Tipe Anggaran', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: [
                  _BudgetTypeChip(
                    label: 'Expense',
                    icon: Icons.arrow_upward_rounded,
                    isSelected: _budgetType == 'expense',
                    color: AppColors.expense,
                    onTap: () => setState(() => _budgetType = 'expense'),
                  ),
                  const SizedBox(width: 10),
                  _BudgetTypeChip(
                    label: 'Income',
                    icon: Icons.arrow_downward_rounded,
                    isSelected: _budgetType == 'income',
                    color: AppColors.income,
                    onTap: () => setState(() => _budgetType = 'income'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Amount
              Text('Nominal', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Masukkan nominal...',
                  prefixText: 'Rp ',
                ),
              ),

              // Category picker (only for expense)
              if (_budgetType == 'expense') ...[
                const SizedBox(height: 16),
                Text('Kategori Anggaran', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                _BudgetCategoryPicker(
                  selectedName: _selectedBudgetCategoryName,
                  onSelected: (name, icon) {
                    setState(() {
                      _selectedBudgetCategoryName = name;
                      _selectedBudgetCategoryIcon = icon;
                    });
                  },
                ),
              ],

              const SizedBox(height: 16),
              Text('Dompet', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              _WalletPicker(
                selectedName: _selectedBudgetWalletName,
                onSelected: (name) {
                  setState(() => _selectedBudgetWalletName = name);
                },
              ),
            ],

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

    if (_hasBudget) {
      final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nominal anggaran harus diisi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_budgetType == 'expense' && _selectedBudgetCategoryName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kategori anggaran harus dipilih'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final task = widget.task ?? Task();
    task.title = _titleController.text.trim();
    task.description = _descController.text.trim();
    task.priority = _priority;
    task.dueDate = _dueDate;
    task.hasReminder = _hasReminder && _dueDate != null;
    task.projectId = widget.projectId;
    task.tags = _tags;
    if (task.status == TaskStatus.todo || widget.task == null) {
      task.status = TaskStatus.todo;
    }

    // Budget fields
    task.hasBudget = _hasBudget;
    if (_hasBudget) {
      task.budgetAmount = double.tryParse(_amountController.text.replaceAll(',', ''));
      task.budgetType = _budgetType;
      task.budgetCategoryName = _selectedBudgetCategoryName;
      task.budgetCategoryIcon = _selectedBudgetCategoryIcon;
      task.budgetWalletName = _selectedBudgetWalletName ?? 'Uang Tunai';
    } else {
      task.budgetAmount = null;
      task.budgetType = null;
      task.budgetCategoryName = null;
      task.budgetCategoryIcon = null;
      task.budgetWalletName = null;
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

class _BudgetTypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _BudgetTypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : theme.inputDecorationTheme.fillColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? color : null),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isSelected ? color : null,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCategoryPicker extends ConsumerWidget {
  final String? selectedName;
  final void Function(String name, String icon) onSelected;

  const _BudgetCategoryPicker({
    required this.selectedName,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catsAsync = ref.watch(financeCategoriesProvider(TransactionType.expense));

    return catsAsync.when(
      loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox(height: 40),
      data: (categories) {
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: categories.map((cat) {
              final isSelected = selectedName == cat.name;
              return GestureDetector(
                onTap: () => onSelected(cat.name, cat.icon),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    cat.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _WalletPicker extends ConsumerWidget {
  final String? selectedName;
  final void Function(String name) onSelected;

  const _WalletPicker({
    required this.selectedName,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletsAsync = ref.watch(walletsProvider);

    return walletsAsync.when(
      loading: () => const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox(height: 40),
      data: (wallets) {
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: wallets.map((w) {
              final isSelected = selectedName == w.name;
              return GestureDetector(
                onTap: () => onSelected(w.name),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    w.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}