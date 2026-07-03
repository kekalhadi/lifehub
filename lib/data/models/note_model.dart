import 'package:isar/isar.dart';

part 'note_model.g.dart';

@collection
class Note {
  Id id = Isar.autoIncrement;

  late String title;

  late String content; // plain text or JSON (quill delta)

  /// Reference ke NoteCategoryCustom (null = kategori default 'Umum')
  @Index()
  int? categoryId;

  late List<String> tags;

  late DateTime createdAt;

  late DateTime updatedAt;

  bool isPinned = false;

  bool isJournal = false;

  String? mood; // 'happy', 'neutral', 'sad', 'excited', 'stressed'

  String? mediaPath; // path to attached image/audio
}

/// Model kategori catatan (default 'Umum' + kategori buatan user)
@collection
class NoteCategoryCustom {
  Id id = Isar.autoIncrement;

  late String name;

  bool isDefault = false;

  late DateTime createdAt;
}

/// Model tag untuk tracking dan autocomplete
@collection
class NoteTag {
  Id id = Isar.autoIncrement;

  late String name; // Nama tag (lowercase)

  late DateTime createdAt;

  int usageCount = 0; // Untuk sorting by popularity
}
