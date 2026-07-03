import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/finance_provider.dart';
import 'add_finance_category_screen.dart';

/// Layar Create/Edit Anggaran.
/// - [editing] == null  → mode buat: pilih kategori + masukkan nominal.
/// - [editing] != null  → mode edit: nominal diisi sebelumnya, kategori read-only.
class AddBudgetScreen extends ConsumerStatefulWidget {
  final BudgetStatus? editing;

  const AddBudgetScreen({super.key, this.editing});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _amountController = TextEditingController();
  FinanceCategory? _selectedCategory;

  bool get _isEditing => widget.editing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _amountController.text = widget.editing!.budget.toInt().toString();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync =
        ref.watch(financeCategoriesProvider(TransactionType.expense));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Anggaran' : 'Tambah Anggaran'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Hapus Anggaran',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Category =====
            Text('Kategori Pengeluaran', style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            if (_isEditing && widget.editing != null)
              _readOnlyCategoryChip(theme, widget.editing!)
            else
              categoriesAsync.when(
                loading: () =>
                    const CircularProgressIndicator(strokeWidth: 2),
                error: (_, __) => const Text('Gagal memuat kategori'),
                data: (categories) {
                  // Hanya tampilkan kategori yang BELUM punya anggaran.
                  final available =
                      categories.where((c) => c.budgetLimit == null).toList();
                  if (available.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Semua kategori pengeluaran sudah memiliki anggaran.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...available.map((cat) {
                        final isSelected = _selectedCategory?.id == cat.id;
                        return _CategoryChip(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                        );
                      }),
                      // Tombol tambah kategori baru
                      GestureDetector(
                        onTap: _addNewCategory,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: theme.inputDecorationTheme.fillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Baru',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),

            const SizedBox(height: 28),

            // ===== Amount =====
            Text('Batas Anggaran (per bulan)',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: theme.textTheme.displayMedium?.copyWith(
                color: AppColors.expense,
              ),
              decoration: const InputDecoration(
                prefixText: 'Rp ',
                hintText: '0',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anggaran berlaku bulan ini dan direset otomatis tiap bulan.',
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),

            const SizedBox(height: 32),

            // ===== Save =====
            GlowButton(
              label: _isEditing ? 'Simpan Perubahan' : 'Buat Anggaran',
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _readOnlyCategoryChip(ThemeData theme, BudgetStatus budget) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CategoryIcon(icon: budget.categoryIcon, size: 20),
          const SizedBox(width: 8),
          Text(
            budget.categoryName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewCategory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddFinanceCategoryScreen(
          type: TransactionType.expense,
        ),
      ),
    );
    // Setelah kembali, refresh state agar daftar kategori terbaru muncul.
    if (mounted) setState(() {});
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showSnack('Masukkan jumlah anggaran');
      return;
    }
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      _showSnack('Jumlah harus lebih dari 0');
      return;
    }

    int categoryId;
    if (_isEditing) {
      categoryId = widget.editing!.categoryId;
    } else {
      if (_selectedCategory == null) {
        _showSnack('Pilih kategori pengeluaran');
        return;
      }
      categoryId = _selectedCategory!.id;
    }

    await ref
        .read(financeNotifierProvider.notifier)
        .setBudget(categoryId, amount);

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (!_isEditing) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Anggaran?'),
        content: Text(
          'Anggaran untuk "${widget.editing!.categoryName}" akan dihapus. '
          'Kategori tetap tersedia, hanya batas anggarannya yang dihilangkan.',
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
      await ref
          .read(financeNotifierProvider.notifier)
          .removeBudget(widget.editing!.categoryId);
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final FinanceCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryIcon(
                icon: category.icon,
                size: 18,
                color: isSelected ? AppColors.primary : null),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
