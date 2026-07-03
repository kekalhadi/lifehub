import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../data/models/note_model.dart';
import '../../../../data/providers/notes_provider.dart';
import '../../../../core/widgets/category_picker.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/theme/app_theme.dart';

/// Screen untuk create/edit custom category
class AddCategoryScreen extends ConsumerStatefulWidget {
  final NoteCategoryCustom? categoryToEdit;

  const AddCategoryScreen({super.key, this.categoryToEdit});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late String _selectedColorHex;

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      _nameController = TextEditingController(text: widget.categoryToEdit!.name);
      _selectedColorHex = widget.categoryToEdit!.colorHex;
    } else {
      _nameController = TextEditingController();
      _selectedColorHex = '#6366F1'; // Default color
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveCategory() {
    if (!_formKey.currentState!.validate()) return;

    final category = NoteCategoryCustom()
      ..id = widget.categoryToEdit?.id ?? Isar.autoIncrement
      ..name = _nameController.text.trim()
      ..colorHex = _selectedColorHex
      ..isDefault = widget.categoryToEdit?.isDefault ?? false
      ..createdAt = widget.categoryToEdit?.createdAt ?? DateTime.now();

    ref.read(notesNotifierProvider.notifier).saveNoteCategory(category).then((id) {
      if (id > 0 && mounted) {
        Navigator.of(context).pop(id);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan kategori')),
        );
      }
    });
  }

  void _confirmDelete() {
    if (widget.categoryToEdit == null) return;
    if (widget.categoryToEdit!.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa menghapus kategori bawaan')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Yakin ingin menghapus "${widget.categoryToEdit!.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notesNotifierProvider.notifier).deleteNoteCategory(widget.categoryToEdit!.id);
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Close screen and return deleted
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.categoryToEdit != null;

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
              // Category name
              Text(
                'Nama Kategori',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Kerja, Pribadi, dll',
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

              // Color picker
              Text(
                'Warna',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              CategoryColorPicker(
                selectedColorHex: _selectedColorHex,
                onColorSelected: (color) => setState(() => _selectedColorHex = color),
              ),
              const SizedBox(height: 24),

              // Preview
              Text(
                'Preview',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: ColorHelper.fromHex(_selectedColorHex).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ColorHelper.fromHex(_selectedColorHex),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: ColorHelper.fromHex(_selectedColorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _nameController.text.isEmpty ? 'Nama Kategori' : _nameController.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ColorHelper.fromHex(_selectedColorHex),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveCategory,
        child: const Icon(Icons.check),
      ),
    );
  }
}
