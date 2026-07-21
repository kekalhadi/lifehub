import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/profile_model.dart';
import '../models/task_model.dart';
import 'database_provider.dart';

final profileStreamProvider = StreamProvider<UserProfile?>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  yield* isar.userProfiles.where().watch(fireImmediately: true).map((list) => list.isEmpty ? null : list.first);
});

final missedTasksCountProvider = StreamProvider<int>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  yield* isar.tasks
      .filter()
      .isCompletedEqualTo(false)
      .dueDateIsNotNull()
      .and()
      .dueDateLessThan(todayStart)
      .watch(fireImmediately: true)
      .map((tasks) => tasks.length);
});

final missedTasksProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final isar = await ref.watch(isarProvider.future);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  yield* isar.tasks
      .filter()
      .isCompletedEqualTo(false)
      .dueDateIsNotNull()
      .and()
      .dueDateLessThan(todayStart)
      .sortByPriorityDesc()
      .thenByCreatedAtDesc()
      .watch(fireImmediately: true)
      .map((tasks) => tasks.map((t) => {
        'task': t,
        'overdueDays': todayStart.difference(t.dueDate!).inDays,
      }).toList());
});

class ProfileNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      final isar = await ref.read(isarProvider.future);
      profile.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.userProfiles.put(profile);
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> copyAvatarToAppDir(String sourcePath) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${dir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      final ext = sourcePath.split('.').last;
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final destPath = '${avatarDir.path}/$fileName';
      await File(sourcePath).copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, AsyncValue<void>>(
  ProfileNotifier.new,
);
