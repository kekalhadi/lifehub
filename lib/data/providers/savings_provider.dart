import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/finance_model.dart';
import 'database_provider.dart';

final savingsCategoriesProvider = StreamProvider<List<SavingsCategory>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.savingsCategorys
      .where()
      .sortByCreatedAtDesc()
      .watch(fireImmediately: true);
});

final savingsLedgerProvider = StreamProvider.family<List<SavingsLedger>, int>((ref, categoryId) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.savingsLedgers
      .filter()
      .savingsCategoryIdEqualTo(categoryId)
      .sortByCreatedAtDesc()
      .watch(fireImmediately: true);
});

final savingsCategoryProvider = StreamProvider.family<SavingsCategory?, int>((ref, id) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.savingsCategorys
      .filter()
      .idEqualTo(id)
      .watch(fireImmediately: true)
      .map((list) => list.isEmpty ? null : list.first);
});

final oldestSavingsCategoriesProvider = StreamProvider<List<SavingsCategory>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.savingsCategorys
      .where()
      .sortByCreatedAt()
      .watch(fireImmediately: true)
      .map((list) => list.take(1).toList());
});

class SavingsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<int> saveCategory(SavingsCategory category) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      int id = 0;
      await isar.writeTxn(() async {
        id = await isar.savingsCategorys.put(category);
      });
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return -1;
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.savingsCategorys.delete(categoryId);
        final ledger = await isar.savingsLedgers
            .filter()
            .savingsCategoryIdEqualTo(categoryId)
            .findAll();
        if (ledger.isNotEmpty) {
          await isar.savingsLedgers.deleteAll(ledger.map((e) => e.id).toList());
        }
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addLedger(SavingsLedger ledger) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      await isar.savingsLedgers.put(ledger);
    });
  }

  Future<void> deleteLedgerByTransaction(int transactionId) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final entries = await isar.savingsLedgers
          .filter()
          .relatedTransactionIdEqualTo(transactionId)
          .findAll();
      if (entries.isNotEmpty) {
        await isar.savingsLedgers.deleteAll(entries.map((e) => e.id).toList());
      }
    });
  }
}

final savingsNotifierProvider = NotifierProvider<SavingsNotifier, AsyncValue<void>>(
  SavingsNotifier.new,
);
