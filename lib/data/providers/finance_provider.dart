import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/finance_model.dart';
import 'database_provider.dart';

final transactionsProvider = FutureProvider.family<List<Transaction>, DateRange>((ref, range) async {
  final isar = await ref.watch(isarProvider.future);
  return isar.transactions
      .filter()
      .dateBetween(range.start, range.end)
      .sortByDateDesc()
      .findAll();
});

final todayTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return isar.transactions
      .filter()
      .dateBetween(start, end)
      .sortByDateDesc()
      .findAll();
});

final monthlySummaryProvider = FutureProvider.family<MonthlySummary, DateRange>((ref, range) async {
  final isar = await ref.watch(isarProvider.future);

  final transactions = await isar.transactions
      .filter()
      .dateBetween(range.start, range.end)
      .findAll();

  double totalIncome = 0;
  double totalExpense = 0;
  double totalAllocated = 0;
  final Map<String, double> expenseByCategory = {};

  for (final t in transactions) {
    if (t.type == TransactionType.income) {
      totalIncome += t.amount;
      totalAllocated += (t.savingsAllocationAmount ?? 0);
    } else {
      totalExpense += t.amount;
      expenseByCategory[t.categoryName] =
          (expenseByCategory[t.categoryName] ?? 0) + t.amount;
    }
  }

  return MonthlySummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    totalAllocated: totalAllocated,
    expenseByCategory: expenseByCategory,
    transactionCount: transactions.length,
  );
});

final fundSourcesProvider = StreamProvider<List<Wallet>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.wallets
      .where()
      .watch(fireImmediately: true);
});

final walletsProvider = fundSourcesProvider;

final financeCategoriesProvider = FutureProvider.family<List<FinanceCategory>, TransactionType>(
    (ref, type) async {
  final isar = await ref.watch(isarProvider.future);
  return isar.financeCategorys.filter().typeEqualTo(type).findAll();
});

final allFinanceCategoriesProvider = StreamProvider<List<FinanceCategory>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.financeCategorys
      .where()
      .watch(fireImmediately: true);
});

final savingsGoalsProvider = FutureProvider<List<Wallet>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return isar.wallets.where().findAll();
});

final budgetStatusProvider = FutureProvider.family<List<BudgetStatus>, DateRange>((ref, range) async {
  final isar = await ref.watch(isarProvider.future);

  final categories = await isar.financeCategorys
      .filter()
      .typeEqualTo(TransactionType.expense)
      .budgetLimitIsNotNull()
      .findAll();

  final transactions = await isar.transactions
      .filter()
      .typeEqualTo(TransactionType.expense)
      .dateBetween(range.start, range.end)
      .findAll();

  final Map<String, double> spentByCategory = {};
  for (final t in transactions) {
    spentByCategory[t.categoryName] = (spentByCategory[t.categoryName] ?? 0) + t.amount;
  }

  return categories.map((cat) {
    final spent = spentByCategory[cat.name] ?? 0;
    return BudgetStatus(
      categoryId: cat.id,
      categoryName: cat.name,
      categoryIcon: cat.icon,
      budget: cat.budgetLimit!,
      spent: spent,
    );
  }).toList();
});

enum ExpenseTrendTimeframe { week, month1, month3, month6, year1, all }

final expenseTrendProvider = FutureProvider.family<ExpenseTrendData, ExpenseTrendTimeframe>((ref, timeframe) async {
  final isar = await ref.watch(isarProvider.future);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 23, 59, 59);

  DateTime start;
  switch (timeframe) {
    case ExpenseTrendTimeframe.week:
      start = today.subtract(const Duration(days: 6));
      start = DateTime(start.year, start.month, start.day);
    case ExpenseTrendTimeframe.month1:
      start = DateTime(now.year, now.month - 1, now.day);
    case ExpenseTrendTimeframe.month3:
      start = DateTime(now.year, now.month - 3, now.day);
    case ExpenseTrendTimeframe.month6:
      start = DateTime(now.year, now.month - 6, now.day);
    case ExpenseTrendTimeframe.year1:
      start = DateTime(now.year - 1, now.month, now.day);
    case ExpenseTrendTimeframe.all:
      start = DateTime(2020);
  }

  final transactions = await isar.transactions
      .filter()
      .typeEqualTo(TransactionType.expense)
      .dateBetween(start, today)
      .sortByDate()
      .findAll();

  if (transactions.isEmpty) {
    return ExpenseTrendData(labels: [], values: [], total: 0);
  }

  final isDaily = timeframe == ExpenseTrendTimeframe.week;
  final isMonthly = timeframe == ExpenseTrendTimeframe.year1 || timeframe == ExpenseTrendTimeframe.all;

  final Map<String, double> grouped = {};
  for (final t in transactions) {
    String key;
    if (isDaily) {
      key = '${t.date.day}/${t.date.month}';
    } else if (isMonthly) {
      key = '${t.date.month}/${t.date.year}';
    } else {
      key = '${t.date.day}/${t.date.month}';
    }
    grouped[key] = (grouped[key] ?? 0) + t.amount;
  }

  final labels = grouped.keys.toList();
  final values = grouped.values.toList();
  final total = values.fold(0.0, (a, b) => a + b);

  return ExpenseTrendData(labels: labels, values: values, total: total);
});

class FinanceNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> addTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      transaction.createdAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.transactions.put(transaction);

        // Update fund source balance
        if (transaction.fundSourceId != null) {
          final fundSource = await isar.wallets.get(transaction.fundSourceId!);
          if (fundSource != null) {
            if (transaction.type == TransactionType.income) {
              final allocation = transaction.savingsAllocationAmount ?? 0;
              fundSource.balance += (transaction.amount - allocation);
            } else if (transaction.sourceType == 'balance') {
              fundSource.balance -= transaction.amount;
            }
            await isar.wallets.put(fundSource);
          }
        }

        // Savings allocation (income)
        if (transaction.type == TransactionType.income &&
            transaction.savingsCategoryId != null &&
            transaction.savingsAllocationAmount != null &&
            transaction.savingsAllocationAmount! > 0) {
          final savingsCat = await isar.savingsCategorys.get(transaction.savingsCategoryId!);
          if (savingsCat != null) {
            savingsCat.currentAmount += transaction.savingsAllocationAmount!;
            await isar.savingsCategorys.put(savingsCat);
          }
          final ledger = SavingsLedger()
            ..savingsCategoryId = transaction.savingsCategoryId!
            ..type = 'allocation'
            ..amount = transaction.savingsAllocationAmount!
            ..relatedTransactionId = transaction.id
            ..createdAt = DateTime.now();
          await isar.savingsLedgers.put(ledger);
        }

        // Savings withdrawal (expense)
        if (transaction.type == TransactionType.expense &&
            transaction.sourceType == 'savings' &&
            transaction.savingsCategoryId != null) {
          final savingsCat = await isar.savingsCategorys.get(transaction.savingsCategoryId!);
          if (savingsCat != null) {
            savingsCat.currentAmount -= transaction.amount;
            await isar.savingsCategorys.put(savingsCat);
          }
          final ledger = SavingsLedger()
            ..savingsCategoryId = transaction.savingsCategoryId!
            ..type = 'withdrawal'
            ..amount = transaction.amount
            ..relatedTransactionId = transaction.id
            ..createdAt = DateTime.now();
          await isar.savingsLedgers.put(ledger);
        }
      });
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteTransaction(Transaction transaction) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        // Reverse fund source balance
        if (transaction.fundSourceId != null) {
          final fundSource = await isar.wallets.get(transaction.fundSourceId!);
          if (fundSource != null) {
            if (transaction.type == TransactionType.income) {
              final allocation = transaction.savingsAllocationAmount ?? 0;
              fundSource.balance -= (transaction.amount - allocation);
            } else if (transaction.sourceType == 'balance') {
              fundSource.balance += transaction.amount;
            }
            await isar.wallets.put(fundSource);
          }
        }

        // Reverse savings allocation
        if (transaction.type == TransactionType.income &&
            transaction.savingsCategoryId != null &&
            transaction.savingsAllocationAmount != null &&
            transaction.savingsAllocationAmount! > 0) {
          final savingsCat = await isar.savingsCategorys.get(transaction.savingsCategoryId!);
          if (savingsCat != null) {
            savingsCat.currentAmount -= transaction.savingsAllocationAmount!;
            await isar.savingsCategorys.put(savingsCat);
          }
        }

        // Reverse savings withdrawal
        if (transaction.type == TransactionType.expense &&
            transaction.sourceType == 'savings' &&
            transaction.savingsCategoryId != null) {
          final savingsCat = await isar.savingsCategorys.get(transaction.savingsCategoryId!);
          if (savingsCat != null) {
            savingsCat.currentAmount += transaction.amount;
            await isar.savingsCategorys.put(savingsCat);
          }
        }

        // Delete ledger entries
        final ledgerEntries = await isar.savingsLedgers
            .filter()
            .relatedTransactionIdEqualTo(transaction.id)
            .findAll();
        if (ledgerEntries.isNotEmpty) {
          await isar.savingsLedgers.deleteAll(ledgerEntries.map((e) => e.id).toList());
        }

        await isar.transactions.delete(transaction.id);
      });
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ===== Fund Source CRUD =====

  Future<int> saveFundSource(Wallet fundSource) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      int id = 0;
      await isar.writeTxn(() async {
        id = await isar.wallets.put(fundSource);
      });
      state = const AsyncValue.data(null);
      ref.invalidate(fundSourcesProvider);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return -1;
    }
  }

  Future<void> deleteFundSource(int id) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.wallets.delete(id);
      });
      state = const AsyncValue.data(null);
      ref.invalidate(fundSourcesProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ===== Category CRUD =====

  Future<int> saveFinanceCategory(FinanceCategory category) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      int id = 0;
      await isar.writeTxn(() async {
        id = await isar.financeCategorys.put(category);
      });
      state = const AsyncValue.data(null);
      _invalidateCategories();
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return -1;
    }
  }

  Future<void> deleteFinanceCategory(int id) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.financeCategorys.delete(id);
      });
      state = const AsyncValue.data(null);
      _invalidateCategories();
      _invalidateBudgets();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _invalidateCategories() {
    ref.invalidate(financeCategoriesProvider(TransactionType.expense));
    ref.invalidate(financeCategoriesProvider(TransactionType.income));
    ref.invalidate(allFinanceCategoriesProvider);
  }

  // ===== Budget CRUD =====

  Future<void> setBudget(int categoryId, double amount) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final cat = await isar.financeCategorys.get(categoryId);
      if (cat != null) {
        cat.budgetLimit = amount;
        await isar.financeCategorys.put(cat);
      }
    });
    _invalidateBudgets();
  }

  Future<void> removeBudget(int categoryId) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final cat = await isar.financeCategorys.get(categoryId);
      if (cat != null) {
        cat.budgetLimit = null;
        await isar.financeCategorys.put(cat);
      }
    });
    _invalidateBudgets();
  }

  void _invalidateBudgets() {
    ref.invalidate(budgetStatusProvider);
    ref.invalidate(financeCategoriesProvider(TransactionType.expense));
  }

  void _invalidateAll() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(todayTransactionsProvider);
    ref.invalidate(monthlySummaryProvider);
    ref.invalidate(fundSourcesProvider);
    ref.invalidate(budgetStatusProvider);
  }
}

final financeNotifierProvider = NotifierProvider<FinanceNotifier, AsyncValue<void>>(
  FinanceNotifier.new,
);

class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  static DateRange thisMonth() {
    final now = DateTime.now();
    return DateRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

class MonthlySummary {
  final double totalIncome;
  final double totalExpense;
  final double totalAllocated;
  final Map<String, double> expenseByCategory;
  final int transactionCount;

  double get balance => totalIncome - totalExpense - totalAllocated;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalAllocated,
    required this.expenseByCategory,
    required this.transactionCount,
  });
}

class BudgetStatus {
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final double budget;
  final double spent;

  double get percentage => budget > 0 ? (spent / budget).clamp(0, 1) : 0;
  bool get isOverBudget => spent > budget;
  bool get isNearLimit => percentage >= 0.8 && !isOverBudget;

  const BudgetStatus({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.budget,
    required this.spent,
  });
}

class ExpenseTrendData {
  final List<String> labels;
  final List<double> values;
  final double total;

  const ExpenseTrendData({
    required this.labels,
    required this.values,
    required this.total,
  });
}
