import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/finance_model.dart';
import 'database_provider.dart';

// All transactions with optional date filter
final transactionsProvider = FutureProvider.family<List<Transaction>, DateRange>((ref, range) async {
  final isar = await ref.watch(isarProvider.future);
  return isar.transactions
      .filter()
      .dateBetween(range.start, range.end)
      .sortByDateDesc()
      .findAll();
});

// Today's transactions for dashboard
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

// Monthly summary for current month
final monthlySummaryProvider = FutureProvider<MonthlySummary>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final transactions = await isar.transactions
      .filter()
      .dateBetween(start, end)
      .findAll();

  double totalIncome = 0;
  double totalExpense = 0;
  final Map<String, double> expenseByCategory = {};
  final Map<String, String> categoryColors = {};

  for (final t in transactions) {
    if (t.type == TransactionType.income) {
      totalIncome += t.amount;
    } else {
      totalExpense += t.amount;
      expenseByCategory[t.categoryName] =
          (expenseByCategory[t.categoryName] ?? 0) + t.amount;
      categoryColors[t.categoryName] = t.categoryColorHex;
    }
  }

  return MonthlySummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    expenseByCategory: expenseByCategory,
    categoryColors: categoryColors,
    transactionCount: transactions.length,
  );
});

// Wallets provider
final walletsProvider = FutureProvider<List<Wallet>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return isar.wallets.where().findAll();
});

// Finance categories provider
final financeCategoriesProvider = FutureProvider.family<List<FinanceCategory>, TransactionType>(
      (ref, type) async {
    final isar = await ref.watch(isarProvider.future);
    return isar.financeCategorys.filter().typeEqualTo(type).findAll();
  },
);

// Savings goals provider
final savingsGoalsProvider = FutureProvider<List<SavingsGoal>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return isar.savingsGoals.where().sortByCreatedAtDesc().findAll();
});

// Budget status for current month
final budgetStatusProvider = FutureProvider<List<BudgetStatus>>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

  final categories = await isar.financeCategorys
      .filter()
      .typeEqualTo(TransactionType.expense)
      .budgetLimitIsNotNull()
      .findAll();

  final transactions = await isar.transactions
      .filter()
      .typeEqualTo(TransactionType.expense)
      .dateBetween(start, end)
      .findAll();

  final Map<String, double> spentByCategory = {};
  for (final t in transactions) {
    spentByCategory[t.categoryName] = (spentByCategory[t.categoryName] ?? 0) + t.amount;
  }

  return categories.map((cat) {
    final spent = spentByCategory[cat.name] ?? 0;
    return BudgetStatus(
      categoryName: cat.name,
      categoryIcon: cat.icon,
      categoryColorHex: cat.colorHex,
      budget: cat.budgetLimit!,
      spent: spent,
    );
  }).toList();
});

// Finance mutations
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
        // Update wallet balance
        final wallets = await isar.wallets.where().findAll();
        final wallet = wallets.firstWhere(
              (w) => w.name == transaction.walletName,
          orElse: () => wallets.first,
        );
        if (transaction.type == TransactionType.income) {
          wallet.balance += transaction.amount;
        } else {
          wallet.balance -= transaction.amount;
        }
        await isar.wallets.put(wallet);
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
        await isar.transactions.delete(transaction.id);
        // Reverse wallet balance change
        final wallets = await isar.wallets.where().findAll();
        final wallet = wallets.firstWhere(
              (w) => w.name == transaction.walletName,
          orElse: () => wallets.first,
        );
        if (transaction.type == TransactionType.income) {
          wallet.balance -= transaction.amount;
        } else {
          wallet.balance += transaction.amount;
        }
        await isar.wallets.put(wallet);
      });
      state = const AsyncValue.data(null);
      _invalidateAll();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateWalletBalance(int walletId, double newBalance) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final wallet = await isar.wallets.get(walletId);
      if (wallet != null) {
        wallet.balance = newBalance;
        await isar.wallets.put(wallet);
      }
    });
    ref.invalidate(walletsProvider);
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    final isar = await ref.read(isarProvider.future);
    goal.createdAt = DateTime.now();
    await isar.writeTxn(() async {
      await isar.savingsGoals.put(goal);
    });
    ref.invalidate(savingsGoalsProvider);
  }

  Future<void> updateSavingsProgress(int goalId, double amount) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final goal = await isar.savingsGoals.get(goalId);
      if (goal != null) {
        goal.currentAmount = amount;
        goal.isCompleted = amount >= goal.targetAmount;
        await isar.savingsGoals.put(goal);
      }
    });
    ref.invalidate(savingsGoalsProvider);
  }

  void _invalidateAll() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(todayTransactionsProvider);
    ref.invalidate(monthlySummaryProvider);
    ref.invalidate(walletsProvider);
    ref.invalidate(budgetStatusProvider);
  }
}

final financeNotifierProvider = NotifierProvider<FinanceNotifier, AsyncValue<void>>(
  FinanceNotifier.new,
);

// Data classes
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
  final Map<String, double> expenseByCategory;
  final Map<String, String> categoryColors;
  final int transactionCount;

  double get balance => totalIncome - totalExpense;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.expenseByCategory,
    required this.categoryColors,
    required this.transactionCount,
  });
}

class BudgetStatus {
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final double budget;
  final double spent;

  double get percentage => budget > 0 ? (spent / budget).clamp(0, 1) : 0;
  bool get isOverBudget => spent > budget;
  bool get isNearLimit => percentage >= 0.8 && !isOverBudget;

  const BudgetStatus({
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.budget,
    required this.spent,
  });
}