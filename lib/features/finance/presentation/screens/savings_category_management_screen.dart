import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/app_alert.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/savings_provider.dart';
import 'add_finance_category_screen.dart';

class SavingsCategoryManagementScreen extends ConsumerWidget {
  const SavingsCategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(savingsCategoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategori Tabungan')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Gagal memuat')),
        data: (categories) {
          if (categories.isEmpty) {
            return EmptyStateView(
              icon: Icons.savings_outlined,
              message: 'Belum ada kategori tabungan.\nBuat kategori tabungan pertama Anda.',
              actionLabel: 'Tambah Kategori',
              onAction: () => _addCategory(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _CategoryTile(
              category: categories[i],
              onEdit: () => _addCategory(context, category: categories[i]),
              onDelete: () => _confirmDelete(context, ref, categories[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCategory(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _addCategory(BuildContext context, {SavingsCategory? category}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AddSavingsCategoryScreen(category: category),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, SavingsCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori Tabungan?'),
        content: Text(
          '"${category.name}" beserta histori terkait akan dihapus permanen. Saldo yang terkumpul akan hilang.',
        ),
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
    if (confirmed == true) {
      await ref.read(savingsNotifierProvider.notifier).deleteCategory(category.id);
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final SavingsCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTarget = category.targetAmount != null && category.targetAmount! > 0;
    final percentage = hasTarget
        ? (category.currentAmount / category.targetAmount!).clamp(0.0, 1.0) as double
        : null;
    final isCompleted = percentage != null && percentage >= 1.0;

    return GlassCard(
      onTap: onEdit,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBox(
                icon: tryParseIconData(category.icon) ?? Icons.savings,
                size: 44,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(category.name,
                              style: theme.textTheme.labelLarge,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isCompleted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Tercapai',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                )),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(category.currentAmount),
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (hasTarget) ...[
                          Text(
                            ' / ${CurrencyFormatter.format(category.targetAmount!)}',
                            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(percentage! * 100).toInt()}%',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCompleted ? AppColors.primary : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.edit_outlined),
                            title: const Text('Edit'),
                            onTap: () { Navigator.pop(context); onEdit(); },
                          ),
                          ListTile(
                            leading: Icon(Icons.delete_outline, color: AppColors.danger),
                            title: Text('Hapus', style: TextStyle(color: AppColors.danger)),
                            onTap: () { Navigator.pop(context); onDelete(); },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percentage,
                backgroundColor: AppColors.gray700.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isCompleted ? AppColors.primary : AppColors.secondary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddSavingsCategoryScreen extends ConsumerStatefulWidget {
  final SavingsCategory? category;

  const _AddSavingsCategoryScreen({this.category});

  @override
  ConsumerState<_AddSavingsCategoryScreen> createState() => _AddSavingsCategoryScreenState();
}

class _AddSavingsCategoryScreenState extends ConsumerState<_AddSavingsCategoryScreen> {
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  String _selectedIcon = 'savings';
  DateTime? _targetDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _isEditing = true;
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.icon;
      _targetDate = widget.category!.targetDate;
      if (widget.category!.targetAmount != null && widget.category!.targetAmount! > 0) {
        _targetAmountController.text = widget.category!.targetAmount!.toStringAsFixed(0);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Kategori Tabungan' : 'Tambah Kategori Tabungan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Tabungan', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'mis. Dana Darurat, Motor Baru'),
            ),
            const SizedBox(height: 20),
            Text('Ikon', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            IconPickerGrid(
              selectedIcon: _selectedIcon,
              onIconSelected: (key) => setState(() => _selectedIcon = key),
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            Text('Target Nominal (opsional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: 'Kosongkan jika tanpa target',
              ),
            ),
            const SizedBox(height: 20),
            Text('Target Tanggal (opsional)', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: theme.inputDecorationTheme.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _targetDate != null
                          ? DateHelper.formatDate(_targetDate!)
                          : 'Pilih tanggal',
                      style: theme.textTheme.bodyLarge,
                    ),
                    const Spacer(),
                    if (_targetDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _targetDate = null),
                        child: Icon(Icons.clear, size: 18, color: theme.textTheme.bodyMedium?.color),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            GlowButton(
              label: _isEditing ? 'Simpan' : 'Tambah',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      await AppAlert.show(context, title: 'Nama Kosong', message: 'Masukkan nama tabungan.');
      return;
    }

    final rawTarget = _targetAmountController.text.replaceAll('.', '');
    final double? targetAmount = rawTarget.isNotEmpty ? double.tryParse(rawTarget) : null;

    final category = SavingsCategory()
      ..name = name
      ..icon = _selectedIcon
      ..targetAmount = targetAmount
      ..targetDate = _targetDate;

    if (_isEditing) {
      category.id = widget.category!.id;
      category.currentAmount = widget.category!.currentAmount;
      category.createdAt = widget.category!.createdAt;
    } else {
      category.currentAmount = 0;
      category.createdAt = DateTime.now();
    }

    await ref.read(savingsNotifierProvider.notifier).saveCategory(category);
    if (mounted) Navigator.of(context).pop();
  }
}
