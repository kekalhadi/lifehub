import 'package:isar/isar.dart';

part 'finance_model.g.dart';

enum TransactionType { income, expense }

@collection
class FinanceCategory {
  Id id = Isar.autoIncrement;

  late String name;

  late String icon;

  @enumerated
  late TransactionType type;

  double? budgetLimit;

  bool isDefault = false;
}

@collection
class Wallet {
  Id id = Isar.autoIncrement;

  late String name;

  late String icon;

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

  String walletName = '';

  String fundSourceName = '';

  int? fundSourceId;

  String sourceType = 'balance';

  int? savingsCategoryId;

  String? savingsCategoryName;

  double? savingsAllocationAmount;

  String note = '';

  late DateTime date;

  late DateTime createdAt;

  bool isRecurring = false;

  String? recurringInterval;

  int? taskId;
}

@collection
class SavingsCategory {
  Id id = Isar.autoIncrement;

  late String name;

  late String icon;

  double? targetAmount;

  DateTime? targetDate;

  double currentAmount = 0;

  late DateTime createdAt;
}

@collection
class SavingsLedger {
  Id id = Isar.autoIncrement;

  late int savingsCategoryId;

  late String type;

  late double amount;

  int? relatedTransactionId;

  late DateTime createdAt;
}
