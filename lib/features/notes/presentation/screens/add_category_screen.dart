import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../../../data/models/note_model.dart';
import '../../../../data/providers/notes_provider.dart';
import '../../../../core/theme/app_theme.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  final NoteCategoryCustom? categoryToEdit;

  const AddCategoryScreen({super.key, this.categoryToEdit});

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.categoryToEdit?.name ?? '',
    );
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
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
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
