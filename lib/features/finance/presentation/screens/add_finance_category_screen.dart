import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icons.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/category_picker.dart';
import '../../../../data/models/finance_model.dart';
import '../../../../data/providers/finance_provider.dart';

/// Layar buat/edit kategori finance.
/// [type] menentukan tipe kategori (income/expense) — hanya dipakai saat buat.
/// [categoryToEdit] != null → mode edit.
class AddFinanceCategoryScreen extends ConsumerStatefulWidget {
  final TransactionType type;
  final FinanceCategory? categoryToEdit;

  const AddFinanceCategoryScreen({
    super.key,
    this.type = TransactionType.expense,
    this.categoryToEdit,
  });

  @override
  ConsumerState<AddFinanceCategoryScreen> createState() =>
      _AddFinanceCategoryScreenState();
}

class _AddFinanceCategoryScreenState
    extends ConsumerState<AddFinanceCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColorHex;
  late TransactionType _type;

  @override
  void initState() {
    super.initState();
    final cat = widget.categoryToEdit;
    if (cat != null) {
      _nameController = TextEditingController(text: cat.name);
      _selectedIcon = cat.icon;
      _selectedColorHex = cat.colorHex;
      _type = cat.type;
    } else {
      _nameController = TextEditingController();
      _selectedIcon = 'category';
      _selectedColorHex = '#6366F1';
      _type = widget.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final cat = FinanceCategory()
      ..id = widget.categoryToEdit?.id ?? Isar.autoIncrement
      ..name = _nameController.text.trim()
      ..icon = _selectedIcon
      ..colorHex = _selectedColorHex
      ..type = _type
      ..budgetLimit = widget.categoryToEdit?.budgetLimit
      ..isDefault = widget.categoryToEdit?.isDefault ?? false;

    ref
        .read(financeNotifierProvider.notifier)
        .saveFinanceCategory(cat)
        .then((id) {
      if (id > 0 && mounted) {
        Navigator.of(context).pop(id);
      } else if (mounted) {
        _showSnack('Gagal menyimpan kategori');
      }
    });
  }

  void _confirmDelete() {
    final cat = widget.categoryToEdit;
    if (cat == null) return;
    if (cat.isDefault) {
      _showSnack('Tidak bisa menghapus kategori bawaan');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text(
          'Yakin ingin menghapus "${cat.name}"?\n'
          'Transaksi lama yang memakai kategori ini tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(financeNotifierProvider.notifier)
                  .deleteFinanceCategory(cat.id);
              Navigator.of(context).pop(); // dialog
              Navigator.of(context).pop(true); // screen
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.categoryToEdit != null;
    final previewColor = ColorHelper.fromHex(_selectedColorHex);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Kategori' : 'Kategori Baru'),
        actions: [
          if (isEditing && !widget.categoryToEdit!.isDefault)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
              tooltip: 'Hapus kategori',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== Preview =====
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: previewColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: previewColor, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: CategoryIcon(
                    icon: _selectedIcon,
                    size: 32,
                    color: previewColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ===== Name =====
              Text('Nama Kategori', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Makanan, Transportasi, dll',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama kategori tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ===== Type (hanya saat buat) =====
              if (!isEditing) ...[
                Text('Tipe', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.inputDecorationTheme.fillColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TypeChip(
                          label: 'Pemasukan',
                          icon: Icons.south_west,
                          isSelected: _type == TransactionType.income,
                          color: AppColors.income,
                          onTap: () =>
                              setState(() => _type = TransactionType.income),
                        ),
                      ),
                      Expanded(
                        child: _TypeChip(
                          label: 'Pengeluaran',
                          icon: Icons.north_east,
                          isSelected: _type == TransactionType.expense,
                          color: AppColors.expense,
                          onTap: () =>
                              setState(() => _type = TransactionType.expense),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ===== Icon picker =====
              Text('Ikon', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              IconPickerGrid(
                selectedIcon: _selectedIcon,
                onIconSelected: (key) => setState(() => _selectedIcon = key),
                color: previewColor,
              ),
              const SizedBox(height: 24),

              // ===== Color picker =====
              Text('Warna', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              CategoryColorPicker(
                selectedColorHex: _selectedColorHex,
                onColorSelected: (hex) =>
                    setState(() => _selectedColorHex = hex),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.check),
      ),
    );
  }
}

// ─── Icon Picker Grid ──────────────────────────────────────────────────────────

/// Grid pilihan ikon dari [kCategoryIcons].
class IconPickerGrid extends StatelessWidget {
  final String selectedIcon;
  final ValueChanged<String> onIconSelected;
  final Color color;

  const IconPickerGrid({
    super.key,
    required this.selectedIcon,
    required this.onIconSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icons = kCategoryIcons.entries.toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        itemCount: icons.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
        ),
        itemBuilder: (_, i) {
          final entry = icons[i];
          final isSelected = entry.key == selectedIcon;
          return GestureDetector(
            onTap: () => onIconSelected(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                entry.value,
                size: 22,
                color: isSelected ? color : theme.iconTheme.color,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Type Chip ─────────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
