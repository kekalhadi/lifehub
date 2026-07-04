import 'package:isar/isar.dart';

part 'task_model.g.dart';

enum TaskPriority { low, medium, high }

enum TaskStatus { todo, inProgress, done }

@collection
class Task {
  Id id = Isar.autoIncrement;

  late String title;

  String description = '';

  @enumerated
  late TaskPriority priority;

  @enumerated
  TaskStatus status = TaskStatus.todo;

  bool isCompleted = false;

  DateTime? dueDate;

  late DateTime createdAt;

  DateTime? completedAt;

  int? projectId; // null = standalone daily task

  late List<String> tags;

  bool hasReminder = false;

  DateTime? reminderTime;

  // Budget integration fields
  bool hasBudget = false;

  double? budgetAmount;

  String? budgetType; // 'income' or 'expense'

  String? budgetCategoryName;

  String? budgetCategoryIcon;

  String? budgetWalletName;
}

@collection
class Project {
  Id id = Isar.autoIncrement;

  late String title;

  String description = '';

  late String icon;

  late DateTime createdAt;

  bool isArchived = false;
}