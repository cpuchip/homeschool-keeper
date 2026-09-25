import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_entry.freezed.dart';
part 'log_entry.g.dart';

/// LogEntry model representing a single log of hours for a student and subject
@freezed
class LogEntry with _$LogEntry {
  const factory LogEntry({
    required String id,
    required String familyId,
    String? organizationId,
    required String studentId,
    required String subjectId,
    String? groupId, // Links multiple log entries created together (multi-student)
    required DateTime date,
    required double hours,
    required String description,
    required String locationType,
    String? locationId,
    String? locationName,
    required String submittedBy,
    required String status,
    required String schoolYear,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _LogEntry;

  factory LogEntry.fromJson(Map<String, dynamic> json) => _$LogEntryFromJson(json);
}

/// Location types
class LocationType {
  static const String home = 'home';
  static const String fieldTrip = 'field_trip';
  static const String coOp = 'co_op';
  static const String online = 'online';
  static const String other = 'other';

  static const List<String> all = [home, fieldTrip, coOp, online, other];

  static String displayName(String type) {
    switch (type) {
      case home:
        return 'Home';
      case fieldTrip:
        return 'Field Trip';
      case coOp:
        return 'Co-Op';
      case online:
        return 'Online';
      case other:
        return 'Other';
      default:
        return type;
    }
  }
}

/// Log statuses
class LogStatus {
  static const String approved = 'approved';
  static const String pending = 'pending';
}
