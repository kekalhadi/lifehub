import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/category_picker.dart';
import '../../../../core/widgets/tag_autocomplete_field.dart';
import '../../../../data/models/note_model.dart';
import '../../../../data/providers/notes_provider.dart';
import 'add_category_screen.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  final bool isJournal;

  const NoteEditorScreen({super.key, this.note, this.isJournal = false});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  late bool _isJournal;
  String? _mood;
  List<String> _tags = [];
  bool _isPinned = false;
  bool _hasChanges = false;

  // Kategori yang dipilih (null belum di-set -> akan default ke 'Umum')
  int? _selectedCategoryId;
  bool _categoryInitialized = false;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _isJournal = note?.isJournal ?? widget.isJournal;
    _mood = note?.mood;
    _tags = List.from(note?.tags ?? []);
    _isPinned = note?.isPinned ?? false;
    _titleController.text = note?.title ?? '';
    _contentController.text = note?.content ?? '';
    _selectedCategoryId = note?.categoryId;

    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() => setState(() => _hasChanges = true);

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.note == null;

    // Inisialisasi kategori default 'Umum' saat list kategori pertama kali dimuat
    final categoriesAsync = ref.watch(noteCategoriesProvider);
    categoriesAsync.whenData((categories) {
      if (!_categoryInitialized) {
        if (_selectedCategoryId == null) {
          final def = categories.where((c) => c.isDefault).firstOrNull ?? categories.firstOrNull;
          if (def != null) _selectedCategoryId = def.id;
        }
        _categoryInitialized = true;
      }
    });

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _hasChanges) {
          final save = await _showSaveDialog();
          if (save == true) await _save();
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isJournal ? 'Jurnal Harian' : (isNew ? 'Catatan Baru' : 'Edit Catatan')),
          actions: [
            IconButton(
              icon: Icon(
                _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                color: _isPinned ? AppColors.warning : null,
              ),
              onPressed: () => setState(() {
                _isPinned = !_isPinned;
                _hasChanges = true;
              }),
            ),
            TextButton(
              onPressed: _save,
              child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.w700)),
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
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 22),
                decoration: const InputDecoration(
                  hintText: 'Judul...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 4),

              // Date
              Text(
                DateHelper.formatDateTime(DateTime.now()),
                style: theme.textTheme.bodyMedium,
              ),

              const Divider(height: 24),

              // Mood picker (journal only)
              if (_isJournal) ...[
                Text('Suasana Hati', style: theme.textTheme.labelLarge),
                const SizedBox(height: 10),
                Row(
                  children: kMoods.map((m) {
                    final isSelected = _mood == m.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _mood = m.key;
                          _hasChanges = true;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.secondaryLight
                                : theme.inputDecorationTheme.fillColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.secondary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(m.icon,
                                  size: 22,
                                  color: isSelected
                                      ? AppColors.secondary
                                      : AppColors.iconColor),
                              const SizedBox(height: 2),
                              Text(m.label,
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Category picker
              Text('Kategori', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Text('Gagal memuat kategori'),
                data: (categories) {
                  final selected = categories
                      .where((c) => c.id == _selectedCategoryId)
                      .firstOrNull;
                  return CategoryPicker(
                    categories: categories,
                    selectedCategory: selected,
                    onCategorySelected: (category) {
                      setState(() {
                        _selectedCategoryId = category?.id;
                        _hasChanges = true;
                      });
                    },
                    onAddNewCategory: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddCategoryScreen()),
                      );
                      if (result != null && result is int) {
                        setState(() {
                          _selectedCategoryId = result;
                          _hasChanges = true;
                        });
                      }
                    },
                  );
                },
              ),

              const SizedBox(height: 20),

              // Tags with autocomplete
              Text('Tag', style: theme.textTheme.labelLarge),
              const SizedBox(height: 12),
              TagAutocompleteField(
                selectedTags: _tags,
                onTagsChanged: (tags) {
                  setState(() {
                    _tags = tags;
                    _hasChanges = true;
                  });
                },
              ),

              const Divider(height: 24),

              // Content
              TextField(
                controller: _contentController,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                decoration: const InputDecoration(
                  hintText: 'Mulai menulis...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
                minLines: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final note = widget.note ?? Note();
    note.title = _titleController.text.trim();
    note.content = _contentController.text;
    note.categoryId = _selectedCategoryId;
    note.tags = _tags;
    note.isPinned = _isPinned;
    note.isJournal = _isJournal;
    note.mood = _mood;

    // Update usage counter untuk semua tag yang dipilih
    for (final tag in _tags) {
      await ref.read(notesNotifierProvider.notifier).incrementTagUsage(tag);
    }

    await ref.read(notesNotifierProvider.notifier).saveNote(note);
    setState(() => _hasChanges = false);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool?> _showSaveDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Simpan Catatan?'),
        content: const Text('Ada perubahan yang belum disimpan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abaikan'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
