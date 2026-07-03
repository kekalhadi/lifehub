import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
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
        ..colorHex = '#64748B'
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

Future<void> _seedDefaultData(Isar isar) async {
  // === Note categories: migrasi ke single default 'Umum' ===
  // Selalu jalan (idempotent) agar perubahan schema terlihat walau ada data lama.
  await _migrateNoteCategories(isar);

  // Seed default finance categories if empty
  final catCount = await isar.financeCategorys.count();
  if (catCount == 0) {
    await isar.writeTxn(() async {
      final expenseCategories = [
        FinanceCategory()
          ..name = 'Makanan & Minuman'
          ..icon = '🍜'
          ..colorHex = '#EF4444'
          ..type = TransactionType.expense
          ..budgetLimit = 1000000
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Transportasi'
          ..icon = '🚗'
          ..colorHex = '#F59E0B'
          ..type = TransactionType.expense
          ..budgetLimit = 500000
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Belanja'
          ..icon = '🛒'
          ..colorHex = '#8B5CF6'
          ..type = TransactionType.expense
          ..budgetLimit = 800000
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Hiburan'
          ..icon = '🎮'
          ..colorHex = '#EC4899'
          ..type = TransactionType.expense
          ..budgetLimit = 300000
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Kesehatan'
          ..icon = '💊'
          ..colorHex = '#10B981'
          ..type = TransactionType.expense
          ..budgetLimit = 500000
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Pendidikan'
          ..icon = '📚'
          ..colorHex = '#06B6D4'
          ..type = TransactionType.expense
          ..budgetLimit = 500000
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Tagihan'
          ..icon = '🧾'
          ..colorHex = '#64748B'
          ..type = TransactionType.expense
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Lainnya'
          ..icon = '📦'
          ..colorHex = '#94A3B8'
          ..type = TransactionType.expense
          ..isDefault = true,
      ];
      final incomeCategories = [
        FinanceCategory()
          ..name = 'Gaji'
          ..icon = '💼'
          ..colorHex = '#10B981'
          ..type = TransactionType.income
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Freelance'
          ..icon = '💻'
          ..colorHex = '#6366F1'
          ..type = TransactionType.income
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Investasi'
          ..icon = '📈'
          ..colorHex = '#F59E0B'
          ..type = TransactionType.income
          ..isDefault = true,
        FinanceCategory()
          ..name = 'Lainnya'
          ..icon = '💰'
          ..colorHex = '#10B981'
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
          ..icon = '💵'
          ..colorHex = '#10B981'
          ..type = WalletType.cash
          ..balance = 0,
        Wallet()
          ..name = 'Rekening Bank'
          ..icon = '🏦'
          ..colorHex = '#6366F1'
          ..type = WalletType.bank
          ..balance = 0,
        Wallet()
          ..name = 'E-Wallet'
          ..icon = '📱'
          ..colorHex = '#F59E0B'
          ..type = WalletType.ewallet
          ..balance = 0,
      ];
      await isar.wallets.putAll(wallets);
    });
  }
}