import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/glass.dart';
import '../../../../core/widgets/category_picker.dart';
import '../../../../data/models/note_model.dart';
import '../../../../data/providers/notes_provider.dart';
import 'package:flutter/services.dart';
import 'note_editor_screen.dart';
import 'add_category_screen.dart';
import 'category_management_screen.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  NoteCategoryCustom? _selectedCategory;
  bool _showJournalOnly = false;
  List<String> _selectedTags = [];
  bool _showTagFilter = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = null;
      _showJournalOnly = false;
      _selectedTags = [];
    });
  }

  bool get hasFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategory != null ||
      _showJournalOnly ||
      _selectedTags.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Ambil notes berdasarkan filter kategori (database-level), lalu filter sisanya di memory
    final notesAsync = ref.watch(notesProvider(NoteFilter(
      categoryId: _selectedCategory?.id,
      isJournal: _showJournalOnly ? true : null,
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catatan'),
        actions: [
          if (hasFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Reset', style: TextStyle(fontSize: 13)),
            ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const CategoryManagementScreen()),
            ),
            tooltip: 'Kelola Kategori',
          ),
          IconButton(
            icon: Icon(_showTagFilter ? Icons.tag : Icons.tag_outlined),
            onPressed: () => setState(() => _showTagFilter = !_showTagFilter),
            tooltip: 'Filter berdasarkan Tag',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showTagFilter ? 200 : 120),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Cari catatan...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                  ),
                ),
              ),

              // Category Filter (Custom Categories)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: ref.watch(noteCategoriesProvider).when(
                  loading: () => const SizedBox(height: 30),
                  error: (_, __) => const SizedBox(height: 30),
                  data: (categories) => CategoryPicker(
                    categories: categories,
                    selectedCategory: _selectedCategory,
                    onCategorySelected: (category) => setState(() {
                      _selectedCategory =
                          category?.id == _selectedCategory?.id ? null : category;
                      _showJournalOnly = false;
                    }),
                    onAddNewCategory: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
                      );
                      if (result != null && result is int) {
                        ref.invalidate(noteCategoriesProvider);
                        final cats = await ref.read(noteCategoriesProvider.future);
                        if (cats.isEmpty) return;
                        final newCat = cats.firstWhere(
                          (c) => c.id == result,
                          orElse: () => cats.first,
                        );
                        setState(() => _selectedCategory = newCat);
                      }
                    },
                  ),
                ),
              ),

              // Tag Filter (Multiple Select) — scoped to notes module
              if (_showTagFilter) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: ref.watch(notesTagCountsProvider).when(
                    loading: () => const SizedBox(height: 30, child: CircularProgressIndicator()),
                    error: (_, __) => const SizedBox(height: 30),
                    data: (tagCounts) {
                      if (tagCounts.isEmpty) {
                        return const Text(
                          'Belum ada tag. Buat catatan dengan tag untuk mulai memfilter.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        );
                      }
                      return SizedBox(
                        height: 32,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          itemCount: tagCounts.entries.take(10).length + 1,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (_, i) {
                            if (i == 0) {
                              return _TagFilterChip(
                                label: 'Semua',
                                isSelected: _selectedTags.isEmpty,
                                onTap: () => setState(() => _selectedTags = []),
                              );
                            }
                            final e = tagCounts.entries.take(10).toList()[i - 1];
                            return _TagFilterChip(
                              label: '#${e.key}',
                              isSelected: _selectedTags.contains(e.key),
                              onTap: () {
                                setState(() {
                                  if (_selectedTags.contains(e.key)) {
                                    _selectedTags.remove(e.key);
                                  } else {
                                    _selectedTags.add(e.key);
                                  }
                                });
                              },
                              count: e.value,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notes) {
          // Terapkan filter search & tag di memory
          List<Note> filtered = notes;

          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filtered = filtered
                .where((n) =>
                    n.title.toLowerCase().contains(query) ||
                    n.content.toLowerCase().contains(query))
                .toList();
          }

          if (_selectedTags.isNotEmpty) {
            filtered = filtered
                .where((n) => _selectedTags.any((t) => n.tags.contains(t)))
                .toList();
          }

          if (filtered.isEmpty) {
            return _EmptyNotes(hasFilters: hasFilters);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _NoteListCard(
              note: filtered[index],
              onTap: () => _openEditor(context, filtered[index]),
              onPin: () =>
                  ref.read(notesNotifierProvider.notifier).togglePin(filtered[index]),
              onDelete: () => _confirmDelete(context, filtered[index]),
            ),
          );
        },
      ),
    );
  }

  void _openEditor(BuildContext context, Note? note, {bool isJournal = false}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NoteEditorScreen(note: note, isJournal: isJournal),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Catatan?'),
        content: Text('Catatan "${note.title}" akan dihapus permanen.'),
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
      ref.read(notesNotifierProvider.notifier).deleteNote(note.id);
    }
  }
}

class _NoteListCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onPin;
  final VoidCallback onDelete;

  const _NoteListCard({
    required this.note,
    required this.onTap,
    required this.onPin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoryMap = ref.watch(categoryMapProvider).valueOrNull ?? {};
    final category = resolveCategory(note.categoryId, categoryMap);

    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        onLongPressStart: (details) =>
            _showNoteMenu(context, ref, details.globalPosition, category),
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned) ...[
                    const Icon(Icons.push_pin, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                  ],
                  if (note.isJournal && note.mood != null) ...[
                    Icon(moodIcon(note.mood), size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Tanpa Judul' : note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: onPin,
                    child: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                      color: note.isPinned
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                note.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (note.tags.isNotEmpty)
                    Expanded(
                      child: Text(
                        note.tags.map((t) => '#$t').join(' '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  Text(
                    DateHelper.relativeTime(note.updatedAt),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showNoteMenu(
    BuildContext context,
    WidgetRef ref,
    Offset position,
    dynamic category,
  ) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromPoints(position, position),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(
          value: 'copy',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 18),
              SizedBox(width: 10),
              Text('Salin'),
            ],
          ),
        ),
      ],
    );

    if (selected == 'copy') {
      final title = note.title.isEmpty ? 'Tanpa Judul' : note.title;
      final tagsText = note.tags.isNotEmpty
          ? ' | ${note.tags.map((t) => '#$t').join(' ')}'
          : '';
      final text =
          '* ${category.name}$tagsText\n\n   $title :\n   ${note.content}';

      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan disalin'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _TagFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  const _TagFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: isSelected ? AppColors.black : theme.textTheme.bodyMedium?.color,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.black.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: isSelected ? AppColors.black : Colors.grey,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  final bool hasFilters;

  const _EmptyNotes({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconBox(
            icon: hasFilters ? Icons.search_off_rounded : Icons.edit_note_rounded,
            size: 72,
            iconSize: 36,
            radius: 20,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'Tidak ada catatan yang cocok dengan filter'
                : 'Belum ada catatan\nTap tombol + untuk mulai',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Card flat gelap solid — senada dengan gaya card di Dashboard.
class _FlatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _FlatCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1F),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}