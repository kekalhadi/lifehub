import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import 'database_provider.dart';

// Notes list provider
final notesProvider = FutureProvider.family<List<Note>, NoteFilter>((ref, filter) async {
  final isar = await ref.watch(isarProvider.future);

  Query<Note> query;

  if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
    query = isar.notes
        .filter()
        .titleContains(filter.searchQuery!, caseSensitive: false)
        .or()
        .contentContains(filter.searchQuery!, caseSensitive: false)
        .sortByIsPinnedDesc()
        .thenByUpdatedAtDesc()
        .build();
  } else if (filter.categoryId != null) {
    query = isar.notes
        .filter()
        .categoryIdEqualTo(filter.categoryId!)
        .sortByIsPinnedDesc()
        .thenByUpdatedAtDesc()
        .build();
  } else if (filter.isJournal == true) {
    query = isar.notes
        .filter()
        .isJournalEqualTo(true)
        .sortByUpdatedAtDesc()
        .build();
  } else {
    query = isar.notes
        .where()
        .sortByIsPinnedDesc()
        .thenByUpdatedAtDesc()
        .build();
  }

  return query.findAll();
});

// Recent notes for dashboard
final recentNotesProvider = FutureProvider<List<Note>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return isar.notes.where().sortByUpdatedAtDesc().limit(5).findAll();
});

// Notes notifier for mutations
class NotesNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<int> saveNote(Note note) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      final now = DateTime.now();
      if (note.id == Isar.autoIncrement || note.id == 0) {
        note.createdAt = now;
      }
      note.updatedAt = now;
      int id = 0;
      await isar.writeTxn(() async {
        id = await isar.notes.put(note);
      });
      state = const AsyncValue.data(null);
      ref.invalidate(notesProvider);
      ref.invalidate(recentNotesProvider);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return -1;
    }
  }

  Future<void> deleteNote(int id) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.notes.delete(id);
      });
      state = const AsyncValue.data(null);
      ref.invalidate(notesProvider);
      ref.invalidate(recentNotesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePin(Note note) async {
    note.isPinned = !note.isPinned;
    note.updatedAt = DateTime.now();
    await saveNote(note);
  }

  // ===== Category CRUD =====

  Future<int> saveNoteCategory(NoteCategoryCustom category) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      if (category.id == Isar.autoIncrement || category.id == 0) {
        category.createdAt = DateTime.now();
      }
      int id = 0;
      await isar.writeTxn(() async {
        id = await isar.noteCategoryCustoms.put(category);
      });
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return -1;
    }
  }

  Future<void> deleteNoteCategory(int id) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        // Cegah hapus kategori default 'Umum'
        final category = await isar.noteCategoryCustoms.get(id);
        if (category != null && category.isDefault) {
          throw Exception('Tidak bisa menghapus kategori bawaan');
        }
        // Pindahkan catatan dengan kategori ini ke null (Umum)
        final notes = await isar.notes.filter().categoryIdEqualTo(id).findAll();
        for (final note in notes) {
          note.categoryId = null;
          await isar.notes.put(note);
        }
        await isar.noteCategoryCustoms.delete(id);
      });
      state = const AsyncValue.data(null);
      ref.invalidate(notesProvider);
      ref.invalidate(recentNotesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ===== Tag Management =====

  Future<void> addTag(String tagName) async {
    final isar = await ref.read(isarProvider.future);
    final cleaned = tagName.trim().toLowerCase();

    if (cleaned.isEmpty) return;

    final existing = await isar.noteTags
      .filter()
      .nameEqualTo(cleaned)
      .findFirst();

    if (existing == null) {
      await isar.writeTxn(() async {
        final tag = NoteTag()
          ..name = cleaned
          ..createdAt = DateTime.now()
          ..usageCount = 0;
        await isar.noteTags.put(tag);
      });
    }
  }

  Future<void> incrementTagUsage(String tagName) async {
    final isar = await ref.read(isarProvider.future);
    final cleaned = tagName.trim().toLowerCase();

    await isar.writeTxn(() async {
      final tag = await isar.noteTags
        .filter()
        .nameEqualTo(cleaned)
        .findFirst();

      if (tag != null) {
        tag.usageCount++;
        await isar.noteTags.put(tag);
      }
    });
  }

  Future<void> decrementTagUsage(String tagName) async {
    final isar = await ref.read(isarProvider.future);
    final cleaned = tagName.trim().toLowerCase();

    await isar.writeTxn(() async {
      final tag = await isar.noteTags
        .filter()
        .nameEqualTo(cleaned)
        .findFirst();

      if (tag != null) {
        tag.usageCount = (tag.usageCount - 1).clamp(0, 999999);
        await isar.noteTags.put(tag);
      }
    });
  }

  Future<void> deleteTag(String tagName) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      await isar.noteTags
        .filter()
        .nameEqualTo(tagName.trim().toLowerCase())
        .deleteFirst();
    });
  }

  Future<List<String>> getAllTagNames() async {
    final isar = await ref.read(isarProvider.future);
    final tags = await isar.noteTags.where().findAll();
    return tags.map((t) => t.name).toList();
  }
}

final notesNotifierProvider = NotifierProvider<NotesNotifier, AsyncValue<void>>(
  NotesNotifier.new,
);

// ===== Custom Note Categories =====

// All categories stream
final noteCategoriesProvider = StreamProvider<List<NoteCategoryCustom>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.noteCategoryCustoms
    .where()
    .sortByCreatedAtDesc()
    .watch(fireImmediately: true);
});

// Map categoryId -> NoteCategoryCustom untuk lookup cepat di UI
final categoryMapProvider = FutureProvider<Map<int, NoteCategoryCustom>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final cats = await isar.noteCategoryCustoms.where().findAll();
  return {for (final c in cats) c.id: c};
});

// Default category 'Umum' untuk nilai default saat membuat catatan
final defaultCategoryProvider = FutureProvider<NoteCategoryCustom?>((ref) async {
  final cats = await ref.watch(noteCategoriesProvider.future);
  return cats.firstWhere(
    (c) => c.isDefault,
    orElse: () => cats.isNotEmpty ? cats.first : null!,
  );
});

// ===== Tags =====

// All tags stream (sorted by usage)
final allTagsProvider = StreamProvider<List<NoteTag>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.noteTags
    .where()
    .sortByUsageCountDesc()
    .watch(fireImmediately: true);
});

// Tag search by prefix (for autocomplete)
final tagSearchProvider = StreamProvider.family<List<NoteTag>, String>((ref, query) async* {
  final isar = await ref.watch(isarProvider.future);
  final q = query.toLowerCase().trim();

  if (q.isEmpty) {
    yield* isar.noteTags
      .where()
      .sortByUsageCountDesc()
      .watch(fireImmediately: true);
  } else {
    yield* isar.noteTags
      .filter()
      .nameContains(q, caseSensitive: false)
      .sortByUsageCountDesc()
      .watch(fireImmediately: true);
  }
});

// Notes filtered by multiple tags
final notesByTagsProvider = FutureProvider.family<List<Note>, List<String>>((ref, tags) async {
  final isar = await ref.watch(isarProvider.future);

  if (tags.isEmpty) {
    return isar.notes.where().sortByUpdatedAtDesc().findAll();
  }

  // Get all notes and filter manually (Isar doesn't support complex OR queries well)
  final allNotes = await isar.notes.where().findAll();
  return allNotes
    .where((note) => tags.any((tag) => note.tags.contains(tag)))
    .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});

/// Tag usage counts scoped to **Notes** module only.
final notesTagCountsProvider = StreamProvider<Map<String, int>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);

  await for (final _ in isar.notes.where().watch(fireImmediately: true)) {
    final notes = await isar.notes.where().findAll();
    final Map<String, int> counts = {};
    for (final note in notes) {
      for (final tag in note.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    counts.removeWhere((_, v) => v == 0);
    final sorted = Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    yield sorted;
  }
});

/// Tag usage counts scoped to **Tasks** module only, filtered by status tab.
final tasksTagCountsProvider =
    StreamProvider.family<Map<String, int>, TaskStatus?>((ref, status) async* {
  final isar = await ref.watch(isarProvider.future);

  await for (final _ in isar.tasks.where().watch(fireImmediately: true)) {
    final tasks = await isar.tasks.where().findAll();
    final Map<String, int> counts = {};
    for (final task in tasks) {
      if (status != null && task.status != status) continue;
      for (final tag in task.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    counts.removeWhere((_, v) => v == 0);
    final sorted = Map.fromEntries(
      counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
    yield sorted;
  }
});

class NoteFilter {
  final String? searchQuery;
  final int? categoryId;
  final bool? isJournal;

  const NoteFilter({this.searchQuery, this.categoryId, this.isJournal});

  @override
  bool operator ==(Object other) =>
      other is NoteFilter &&
          other.searchQuery == searchQuery &&
          other.categoryId == categoryId &&
          other.isJournal == isJournal;

  @override
  int get hashCode => Object.hash(searchQuery, categoryId, isJournal);
}

/// Helper: resolve kategori dari categoryId. null / tidak ditemukan -> kategori default 'Umum'
NoteCategoryCustom resolveCategory(
  int? categoryId,
  Map<int, NoteCategoryCustom> map,
) {
  if (categoryId != null && map.containsKey(categoryId)) {
    return map[categoryId]!;
  }
  return map.values.firstWhere(
    (c) => c.isDefault,
    orElse: () => map.values.first,
  );
}
