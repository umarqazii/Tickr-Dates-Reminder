import 'package:isar/isar.dart';

// This part is required for the Isar code generator
part 'tickr_event.g.dart';

@collection
class TickrEvent {
  // 1. Local Database ID (Required by Isar to be an integer)
  Id id = Isar.autoIncrement;

  // 2. Cloud Sync ID (A UUID string generated when the event is created)
  // We index this so we can easily find and update it when syncing from Supabase
  @Index(unique: true, replace: true)
  late String syncId;

  // 3. The Event Data
  late String title;
  late DateTime eventDate;
  late bool isRecurring;
  String? notes;

  // 4. Sync Metadata
  late DateTime createdAt;
  late DateTime updatedAt;

  // We use a simple integer for sync status:
  // 0 = pending sync, 1 = synced perfectly
  @Index()
  short syncStatus = 0;

  // Instead of deleting from the database immediately, we mark it as deleted.
  // This tells Supabase to delete it in the cloud on the next sync.
  bool isDeleted = false;
}

// This calculates when the event happens next, relative to today.
extension TickrEventExtension on TickrEvent {
  DateTime get nextOccurrence {
    // If it's a one-time event, the next occurrence is just the event date.
    if (!isRecurring) return eventDate.toLocal();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final localDate = eventDate.toLocal();

    // Guess that it happens this year
    var candidate = DateTime(today.year, localDate.month, localDate.day);

    // If that date has already passed this year, push it to next year
    if (candidate.isBefore(today)) {
      candidate = DateTime(today.year + 1, localDate.month, localDate.day);
    }

    return candidate;
  }

  /// Year difference between [nextOccurrence] and the original [eventDate] year.
  /// `1` means the first anniversary (one calendar year after the original year), etc.
  /// Returns `null` when the upcoming date is still in the original year or earlier.
  int? get anniversaryYear {
    final localOrig = eventDate.toLocal();
    final next = nextOccurrence;
    final years = next.year - localOrig.year;
    if (years < 1) return null;
    return years;
  }
}