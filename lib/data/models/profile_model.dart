import 'package:isar/isar.dart';

part 'profile_model.g.dart';

@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  String name = '';

  String? avatarPath;

  String bio = '';

  DateTime updatedAt = DateTime.now();
}
