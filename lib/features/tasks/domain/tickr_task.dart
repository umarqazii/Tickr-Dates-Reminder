import 'package:isar/isar.dart';

part 'tickr_task.g.dart';

@collection
class TickrTask {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String syncId;

  late String title;

  // Unlike TickrEvent which just needs a date, this needs the exact time
  late DateTime dueDateTime;

  // A boolean to check off the task without deleting it
  bool isCompleted = false;

  String? notes;

  // Sync Metadata (Mirroring your proven setup)
  late DateTime createdAt;
  late DateTime updatedAt;

  @Index()
  short syncStatus = 0;
  bool isDeleted = false;
}