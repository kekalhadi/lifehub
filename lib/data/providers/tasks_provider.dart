import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/task_model.dart';
import '../models/finance_model.dart';
import 'database_provider.dart';
import 'finance_provider.dart';

// Stream-based — otomatis reactive
final allTasksStreamProvider = StreamProvider.family<List<Task>, TaskFilter>((ref, filter) async* {
  final isar = await ref.watch(isarProvider.future);

  Query<Task> buildQuery() {
    var q = isar.tasks.filter();

    if (filter.projectId != null) {
      if (!filter.showCompleted) {
        return q
            .projectIdEqualTo(filter.projectId!)
            .and()
            .isCompletedEqualTo(false)
            .sortByPriorityDesc()
            .thenByCreatedAtDesc()
            .build();
      }
      return q
          .projectIdEqualTo(filter.projectId!)
          .sortByPriorityDesc()
          .thenByCreatedAtDesc()
          .build();
    }

    if (filter.status != null) {
      return q
          .statusEqualTo(filter.status!)
          .sortByPriorityDesc()
          .thenByCreatedAtDesc()
          .build();
    }

    if (filter.onlyStandalone) {
      if (!filter.showCompleted) {
        return q
            .projectIdIsNull()
            .and()
            .isCompletedEqualTo(false)
            .sortByPriorityDesc()
            .thenByCreatedAtDesc()
            .build();
      }
      return q
          .projectIdIsNull()
          .sortByPriorityDesc()
          .thenByCreatedAtDesc()
          .build();
    }

    if (!filter.showCompleted) {
      return q
          .isCompletedEqualTo(false)
          .sortByPriorityDesc()
          .thenByCreatedAtDesc()
          .build();
    }

    return isar.tasks
        .where()
        .sortByPriorityDesc()
        .thenByCreatedAtDesc()
        .build();
  }

  yield* buildQuery().watch(fireImmediately: true);
});

// Today tasks stream
final todayTasksStreamProvider = StreamProvider<List<Task>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  yield* isar.tasks
      .filter()
      .isCompletedEqualTo(false)
      .group((q) => q
      .dueDateBetween(todayStart, todayEnd)
      .or()
      .projectIdIsNull())
      .sortByPriorityDesc()
      .thenByCreatedAtDesc()
      .watch(fireImmediately: true);
});

// Due today count
final dueTodayCountProvider = StreamProvider<int>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

  yield* isar.tasks
      .filter()
      .isCompletedEqualTo(false)
      .dueDateBetween(todayStart, todayEnd)
      .watch(fireImmediately: true)
      .map((tasks) => tasks.length);
});

// Projects stream
final projectsStreamProvider = StreamProvider<List<Project>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.projects
      .filter()
      .isArchivedEqualTo(false)
      .sortByCreatedAtDesc()
      .watch(fireImmediately: true);
});

// Task mutations
class TasksNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<int> saveTask(Task task) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      if (task.id == Isar.autoIncrement || task.id == 0) {
        task.createdAt = DateTime.now();
      }
      int id = 0;
      await isar.writeTxn(() async {
        id = await isar.tasks.put(task);
      });
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return -1;
    }
  }

  Future<void> toggleComplete(Task task) async {
    final wasCompleted = task.isCompleted;
    task.isCompleted = !task.isCompleted;
    if (task.isCompleted) {
      task.status = TaskStatus.done;
      task.completedAt = DateTime.now();
    } else {
      task.status = TaskStatus.todo;
      task.completedAt = null;
    }
    await saveTask(task);

    if (task.isCompleted && !wasCompleted && task.hasBudget && task.budgetAmount != null) {
      await _createBudgetTransaction(task);
    }
    if (wasCompleted && !task.isCompleted) {
      await _removeBudgetTransaction(task.id);
    }
  }

  Future<void> updateStatus(Task task, TaskStatus status) async {
    final wasCompleted = task.isCompleted;
    task.status = status;
    if (status == TaskStatus.done) {
      task.isCompleted = true;
      task.completedAt = DateTime.now();
    } else {
      task.isCompleted = false;
      task.completedAt = null;
    }
    await saveTask(task);

    if (status == TaskStatus.done && !wasCompleted && task.hasBudget && task.budgetAmount != null) {
      await _createBudgetTransaction(task);
    }
    if (wasCompleted && status != TaskStatus.done) {
      await _removeBudgetTransaction(task.id);
    }
  }

  Future<void> _createBudgetTransaction(Task task) async {
    try {
      final isar = await ref.read(isarProvider.future);
      final existing = await isar.transactions
          .filter()
          .taskIdEqualTo(task.id)
          .findFirst();
      if (existing != null) return;

      final txnType = task.budgetType == 'income'
          ? TransactionType.income
          : TransactionType.expense;

      final transaction = Transaction()
        ..amount = task.budgetAmount!
        ..type = txnType
        ..categoryName = task.budgetCategoryName ?? ''
        ..categoryIcon = task.budgetCategoryIcon ?? 'inventory_2'
        ..walletName = task.budgetWalletName ?? 'Uang Tunai'
        ..note = 'Otomatis dari tugas: ${task.title}'
        ..date = DateTime.now()
        ..taskId = task.id;

      await ref.read(financeNotifierProvider.notifier).addTransaction(transaction);
    } catch (_) {}
  }

  Future<void> _removeBudgetTransaction(int taskId) async {
    try {
      final isar = await ref.read(isarProvider.future);
      final existing = await isar.transactions
          .filter()
          .taskIdEqualTo(taskId)
          .findFirst();
      if (existing != null) {
        await ref.read(financeNotifierProvider.notifier).deleteTransaction(existing);
      }
    } catch (_) {}
  }

  Future<void> deleteTask(int id) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      await isar.writeTxn(() async {
        await isar.tasks.delete(id);
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<int> saveProject(Project project) async {
    final isar = await ref.read(isarProvider.future);
    if (project.id == Isar.autoIncrement || project.id == 0) {
      project.createdAt = DateTime.now();
    }
    int id = 0;
    await isar.writeTxn(() async {
      id = await isar.projects.put(project);
    });
    return id;
  }

  Future<void> deleteProject(int id) async {
    final isar = await ref.read(isarProvider.future);
    await isar.writeTxn(() async {
      final tasks = await isar.tasks.filter().projectIdEqualTo(id).findAll();
      await isar.tasks.deleteAll(tasks.map((t) => t.id).toList());
      await isar.projects.delete(id);
    });
  }
}

final tasksNotifierProvider = NotifierProvider<TasksNotifier, AsyncValue<void>>(
  TasksNotifier.new,
);

class TaskFilter {
  final int? projectId;
  final bool onlyStandalone;
  final bool showCompleted;
  final TaskStatus? status;

  const TaskFilter({
    this.projectId,
    this.onlyStandalone = false,
    this.showCompleted = false,
    this.status,
  });

  @override
  bool operator ==(Object other) =>
      other is TaskFilter &&
          other.projectId == projectId &&
          other.onlyStandalone == onlyStandalone &&
          other.showCompleted == showCompleted &&
          other.status == status;

  @override
  int get hashCode => Object.hash(projectId, onlyStandalone, showCompleted, status);
}