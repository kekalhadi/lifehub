import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/category_icons.dart';
import '../models/note_model.dart';
import '../models/finance_model.dart';
import '../models/task_model.dart';
import '../models/profile_model.dart';

final isarProvider = FutureProvider<Isar>((ref) async {
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open(
    [
      NoteSchema,
      NoteCategoryCustomSchema,
      NoteTagSchema,
      FinanceCategorySchema,
      WalletSchema,
      TransactionSchema,
      SavingsCategorySchema,
      SavingsLedgerSchema,
      TaskSchema,
      ProjectSchema,
      UserProfileSchema,
    ],
    directory: dir.path,
    name: 'lifehub_db',
  );
  await _seedDefaultData(isar);
  return isar;
});

/// Migrasi kategori catatan: pastikan tepat satu kategori default 'Umum'.
/// Bersihkan kategori default lama (v1: Kerja, Ide, Pribadi, Jurnal, Lainnya)
/// supaya user hanya melihat 'Umum' + kategori yang mereka buat sendiri.
/// Catatan yang memakai kategori lama dipindahkan ke 'Umum'.
Future<void> _migrateNoteCategories(Isar isar) async {
  final allCats = await isar.noteCategoryCustoms.where().findAll();
  final defaults = allCats.where((c) => c.isDefault).toList();

  // Cari kategori 'Umum' (default)
  NoteCategoryCustom? umum;
  for (final c in defaults) {
    if (c.name.toLowerCase() == 'umum') {
      umum = c;
      break;
    }
  }

  await isar.writeTxn(() async {
    // Buat 'Umum' jika belum ada
    int umumId;
    if (umum == null) {
      final newUmum = NoteCategoryCustom()
        ..name = 'Umum'
        ..isDefault = true
        ..createdAt = DateTime.now();
      umumId = await isar.noteCategoryCustoms.put(newUmum);
    } else {
      umumId = umum.id;
    }

    // Hapus kategori default lama (selain 'Umum') dan pindahkan catatannya
    for (final old in defaults) {
      if (old.id == umumId) continue;
      final notes = await isar.notes.filter().categoryIdEqualTo(old.id).findAll();
      for (final n in notes) {
        n.categoryId = umumId;
        await isar.notes.put(n);
      }
      await isar.noteCategoryCustoms.delete(old.id);
    }
  });
}

/// Migrasi emoji lama → nama ikon untuk kategori finance, transaksi, dan dompet.
/// Idempoten: hanya konversi nilai yang ada di [kEmojiToIconKey].
Future<void> _migrateFinanceIcons(Isar isar) async {
  await isar.writeTxn(() async {
    // Kategori finance
    final categories = await isar.financeCategorys.where().findAll();
    bool catChanged = false;
    for (final cat in categories) {
      if (!isIconKey(cat.icon)) {
        final migrated = migrateEmojiToKey(cat.icon);
        if (migrated != cat.icon) {
          cat.icon = migrated;
          catChanged = true;
        }
      }
    }
    if (catChanged) {
      await isar.financeCategorys.putAll(categories);
    }

    // Transaksi
    final transactions = await isar.transactions.where().findAll();
    bool txnChanged = false;
    for (final t in transactions) {
      if (!isIconKey(t.categoryIcon)) {
        final migrated = migrateEmojiToKey(t.categoryIcon);
        if (migrated != t.categoryIcon) {
          t.categoryIcon = migrated;
          txnChanged = true;
        }
      }
    }
    if (txnChanged) {
      await isar.transactions.putAll(transactions);
    }

    // Dompet
    final wallets = await isar.wallets.where().findAll();
    bool walletChanged = false;
    for (final w in wallets) {
      if (!isIconKey(w.icon)) {
        final migrated = migrateEmojiToKey(w.icon);
        if (migrated != w.icon) {
          w.icon = migrated;
          walletChanged = true;
        }
      }
    }
    if (walletChanged) {
      await isar.wallets.putAll(wallets);
    }
  });
}

Future<void> _seedDefaultData(Isar isar) async {
  // === Note categories: migrasi ke single default 'Umum' ===
  // Selalu jalan (idempotent) agar perubahan schema terlihat walau ada data lama.
  await _migrateNoteCategories(isar);

  // === Migrasi emoji lama → nama ikon (finance) ===
  await _migrateFinanceIcons(isar);

  // Seed default wallets — REMOVED: user creates their own fund sources
  // Seed default profile if empty (singleton)
   final profileCount = await isar.userProfiles.count();
   if (profileCount == 0) {
     await isar.writeTxn(() async {
       final profile = UserProfile()
         ..name = ''
         ..bio = ''
         ..updatedAt = DateTime.now();
       await isar.userProfiles.put(profile);
     });
   }
}