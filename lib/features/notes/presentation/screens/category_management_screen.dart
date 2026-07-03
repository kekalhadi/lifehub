import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../data/models/note_model.dart';
import '../../../../data/providers/notes_provider.dart';
import 'add_category_screen.dart';

/// Layar kelola kategori: list semua kategori + tambah/edit/hapus
class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(noteCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🗂️', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada kategori\nTap + untuk buat kategori',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          // Default 'Umum' di atas, sisanya di bawah
          final sorted = [...categories]..sort((a, b) {
              if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
              return b.createdAt.compareTo(a.createdAt);
            });

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final cat = sorted[index];
              final color = ColorHelper.fromHex(cat.colorHex);
              return _CategoryTile(category: cat, color: color);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryTile extends ConsumerWidget {
  final NoteCategoryCustom category;
  final Color color;

  const _CategoryTile({required this.category, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Row(
        children: [
          // Color dot
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Name + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: theme.textTheme.titleMedium,
                ),
                if (category.isDefault)
                  Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 11, color: Colors.grey.withOpacity(0.7)),
                      const SizedBox(width: 3),
                      Text(
                        'Default — tidak bisa dihapus',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AddCategoryScreen(categoryToEdit: category),
                ),
              );
            },
          ),
          // Delete (hanya untuk non-default)
          if (!category.isDefault)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.danger),
              tooltip: 'Hapus',
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text(
          'Kategori "${category.name}" akan dihapus.\n'
          'Catatan yang memakai kategori ini akan dipindah ke "Umum".',
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
      ref.read(notesNotifierProvider.notifier).deleteNoteCategory(category.id);
    }
  }
}
