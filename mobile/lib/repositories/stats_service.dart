import '../core/database/database_service.dart';
import '../models/stats.dart';

/// Service for calculating stats from local Hive data
class LocalStatsService {
  final DatabaseService _db;

  LocalStatsService({DatabaseService? db})
      : _db = db ?? DatabaseService.instance;

  /// Calculate family stats from local data
  FamilyStats getFamilyStats({String? schoolYear}) {
    final year = schoolYear ?? _db.familySettings.currentSchoolYear;
    final targetHours = _db.familySettings.annualTargetHours;

    // Get all students
    final students = _db.studentsBox.values.where((s) => s.active).toList();

    // Get all logs for the school year
    final logs =
        _db.logEntriesBox.values.where((l) => l.schoolYear == year).toList();

    // Calculate stats per student
    final studentStats = <StudentStats>[];
    double totalFamilyHours = 0;
    int totalLogCount = 0;

    for (final student in students) {
      final studentLogs = logs.where((l) => l.studentId == student.id).toList();
      final studentHours = studentLogs.fold(0.0, (sum, l) => sum + l.hours);

      // Calculate hours by subject
      final hoursBySubject = <SubjectHours>[];
      final subjectHoursMap = <String, double>{};

      for (final log in studentLogs) {
        subjectHoursMap[log.subjectId] =
            (subjectHoursMap[log.subjectId] ?? 0) + log.hours;
      }

      for (final entry in subjectHoursMap.entries) {
        final subject = _db.subjectsBox.get(entry.key);
        if (subject != null) {
          final subjectTarget = subject.targetHours ??
              targetHours / 5; // Default: split target across ~5 subjects
          hoursBySubject.add(SubjectHours(
            subjectId: subject.id,
            subjectName: subject.name,
            color: subject.color,
            hours: entry.value,
            targetHours: subject.targetHours,
            progress: subjectTarget > 0
                ? (entry.value / subjectTarget * 100).clamp(0, 100)
                : 0,
          ),
        );
        }
      }

      // Sort by hours descending
      hoursBySubject.sort((a, b) => b.hours.compareTo(a.hours));

      studentStats.add(
        StudentStats(
          studentId: student.id,
          studentName: student.name,
          totalHours: studentHours,
          hoursBySubject: hoursBySubject,
          logCount: studentLogs.length,
          schoolYear: year,
        ),
      );

      totalFamilyHours += studentHours;
      totalLogCount += studentLogs.length;
    }

    // Sort students by name
    studentStats.sort((a, b) => a.studentName.compareTo(b.studentName));

    return FamilyStats(
      totalHours: totalFamilyHours,
      totalLogCount: totalLogCount,
      schoolYear: year,
      students: studentStats,
    );
  }

  /// Get stats for a specific student
  StudentStats? getStudentStats(String studentId, {String? schoolYear}) {
    final year = schoolYear ?? _db.familySettings.currentSchoolYear;
    final targetHours = _db.familySettings.annualTargetHours;

    final student = _db.studentsBox.get(studentId);
    if (student == null) return null;

    final logs = _db.logEntriesBox.values
        .where((l) => l.studentId == studentId && l.schoolYear == year)
        .toList();

    final totalHours = logs.fold(0.0, (sum, l) => sum + l.hours);

    // Calculate hours by subject
    final hoursBySubject = <SubjectHours>[];
    final subjectHoursMap = <String, double>{};

    for (final log in logs) {
      subjectHoursMap[log.subjectId] =
          (subjectHoursMap[log.subjectId] ?? 0) + log.hours;
    }

    for (final entry in subjectHoursMap.entries) {
      final subject = _db.subjectsBox.get(entry.key);
      if (subject != null) {
        final subjectTarget = subject.targetHours ?? targetHours / 5;
        hoursBySubject.add(SubjectHours(
          subjectId: subject.id,
          subjectName: subject.name,
          color: subject.color,
          hours: entry.value,
          targetHours: subject.targetHours,
          progress: subjectTarget > 0
              ? (entry.value / subjectTarget * 100).clamp(0, 100)
              : 0,
        ),
      );
      }
    }

    // Sort by hours descending
    hoursBySubject.sort((a, b) => b.hours.compareTo(a.hours));

    return StudentStats(
      studentId: student.id,
      studentName: student.name,
      totalHours: totalHours,
      hoursBySubject: hoursBySubject,
      logCount: logs.length,
      schoolYear: year,
    );
  }
}
