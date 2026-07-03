import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/category_icons.dart';
import '../models/note_model.dart';
import '../models/finance_model.dart';
import '../models/task_model.dart';

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
      SavingsGoalSchema,
      TaskSchema,
      ProjectSchema,
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

  // Seed default finance categories if empty
  final catCount = await isar.financeCategorys.count();
  if (catCount == 0) {
    await isar.writeTxn(() async {
      final expenseCategories = [
        FinanceCategory()
          ..name = 'Makanan & Minuman'
          ..icon = 'ramen_dining'
          ..type = TransactionType.expense
          ..budgetLimit = 1000000
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Transportasi'
          ..icon = 'directions_car'
          ..type = TransactionType.expense
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Belanja'
          ..icon = 'shopping_cart'
          ..type = TransactionType.expense
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Hiburan'
          ..icon = 'sports_esports'
          ..type = TransactionType.expense
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Kesehatan'
          ..icon = 'medication'
          ..type = TransactionType.expense
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Pendidikan'
          ..icon = 'menu_book'
          ..type = TransactionType.expense
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Tagihan'
          ..icon = 'receipt_long'
          ..type = TransactionType.expense
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Lainnya'
          ..icon = 'inventory_2'
          ..type = TransactionType.expense
          ..isDefault = true,
      ];
      final incomeCategories = [
        FinanceCategory()
          ..name = 'Gaji'
          ..icon = 'work'
          ..type = TransactionType.income
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Freelance'
          ..icon = 'laptop'
          ..type = TransactionType.income
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Investasi'
          ..icon = 'trending_up'
          ..type = TransactionType.income
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Lainnya'
          ..icon = 'savings'
          ..type = TransactionType.income
          ..isDefault = true,
      ];
      await isar.financeCategorys.putAll([...expenseCategories, ...incomeCategories]);
    });
  }

  // Seed default wallets if empty
  final walletCount = await isar.wallets.count();
  if (walletCount == 0) {
    await isar.writeTxn(() async {
      final wallets = [
        Wallet()
          ..name = 'Uang Tunai'
          ..icon = 'payments'
          ..type = WalletType.cash
          ..balance = 0,
        Wallet()
          ..name = 'Rekening Bank'
          ..icon = 'account_balance'
          ..type = WalletType.bank
          ..balance = 0,
        Wallet()
          ..name = 'E-Wallet'
          ..icon = 'smartphone'
          ..type = WalletType.ewallet
          ..balance = 0,
      ];
      await isar.wallets.putAll(wallets);
    });
  }
}