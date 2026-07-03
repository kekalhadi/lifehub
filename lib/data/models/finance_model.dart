import 'package:isar/isar.dart';

part 'finance_model.g.dart';

enum TransactionType { income, expense }

enum WalletType { cash, bank, ewallet }

@collection
class FinanceCategory {
  Id id = Isar.autoIncrement;

  late String name;

  late String icon; // emoji or icon name

  late String colorHex;

  @enumerated
  late TransactionType type;

  double? budgetLimit; // monthly budget for expense categories

  bool isDefault = false;
}

@collection
class Wallet {
  Id id = Isar.autoIncrement;

  late String name;

  late String icon;

  late String colorHex;

  @enumerated
  late WalletType type;

  double balance = 0;
}

@collection
class Transaction {
  Id id = Isar.autoIncrement;

  late double amount;

  @enumerated
  late TransactionType type;

  late String categoryName;

  late String categoryIcon;

  late String categoryColorHex;

  late String walletName;

  String note = '';

  late DateTime date;

  late DateTime createdAt;

  bool isRecurring = false;

  String? recurringInterval; // 'monthly', 'weekly'
}

@collection
class SavingsGoal {
  Id id = Isar.autoIncrement;

  late String title;

  late String icon;

  late double targetAmount;

  double currentAmount = 0;

  late DateTime targetDate;

  late DateTime createdAt;

  bool isCompleted = false;
}