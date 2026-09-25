import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../core/database/database_service.dart';
import '../../core/database/hive_entities.dart';

/// Export formats supported
enum ExportFormat {
  json,
  csv,
}

/// Export result containing file path and metadata
class ExportResult {
  final String filePath;
  final String fileName;
  final int studentCount;
  final int subjectCount;
  final int logCount;
  final DateTime exportedAt;

  const ExportResult({
    required this.filePath,
    required this.fileName,
    required this.studentCount,
    required this.subjectCount,
    required this.logCount,
    required this.exportedAt,
  });
}

/// Import result with summary of what was imported
class ImportResult {
  final int studentsImported;
  final int subjectsImported;
  final int logsImported;
  final List<String> errors;
  final bool success;

  const ImportResult({
    required this.studentsImported,
    required this.subjectsImported,
    required this.logsImported,
    required this.errors,
    required this.success,
  });
}

/// Service for exporting and importing data
class ExportImportService {
  final DatabaseService _db;

  ExportImportService({DatabaseService? db})
      : _db = db ?? DatabaseService.instance;

  /// Export all data to JSON file
  Future<ExportResult> exportToJson({
    String? schoolYear,
    bool includeAllYears = true,
  }) async {
    final data = _gatherExportData(
      schoolYear: schoolYear,
      includeAllYears: includeAllYears,
    );

    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final fileName = 'homeschool_logs_export_$timestamp.json';

    final directory = await _getExportDirectory();
    final filePath = '${directory.path}/$fileName';

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final file = File(filePath);
    await file.writeAsString(jsonString);

    return ExportResult(
      filePath: filePath,
      fileName: fileName,
      studentCount: (data['students'] as List).length,
      subjectCount: (data['subjects'] as List).length,
      logCount: (data['logs'] as List).length,
      exportedAt: DateTime.now(),
    );
  }

  /// Export logs to CSV file (for state submission)
  Future<ExportResult> exportToCsv({
    String? schoolYear,
    String? studentId,
  }) async {
    final year = schoolYear ?? _db.familySettings.currentSchoolYear;
    var logs = _db.logEntriesBox.values.where((l) => l.schoolYear == year);

    if (studentId != null) {
      logs = logs.where((l) => l.studentId == studentId);
    }

    final logsList = logs.toList()..sort((a, b) => a.date.compareTo(b.date));

    // Build CSV content
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'Date,Student,Subject,Hours,Location Type,Location Name,Description,School Year',
    );

    // Data rows
    for (final log in logsList) {
      final student = _db.studentsBox.get(log.studentId);
      final subject = _db.subjectsBox.get(log.subjectId);

      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(log.date)},'
        '"${_escapeCsv(student?.name ?? 'Unknown')}",'
        '"${_escapeCsv(subject?.name ?? 'Unknown')}",'
        '${log.hours},'
        '"${_escapeCsv(log.locationType)}",'
        '"${_escapeCsv(log.locationName ?? '')}",'
        '"${_escapeCsv(log.description)}",'
        '${log.schoolYear}',
      );
    }

    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final fileName = 'homeschool_logs_$year$timestamp.csv';

    final directory = await _getExportDirectory();
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return ExportResult(
      filePath: filePath,
      fileName: fileName,
      studentCount: logs.map((l) => l.studentId).toSet().length,
      subjectCount: logs.map((l) => l.subjectId).toSet().length,
      logCount: logsList.length,
      exportedAt: DateTime.now(),
    );
  }

  /// Import data from JSON file
  Future<ImportResult> importFromJson(String filePath) async {
    final errors = <String>[];
    var studentsImported = 0;
    var subjectsImported = 0;
    var logsImported = 0;

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(
          studentsImported: 0,
          subjectsImported: 0,
          logsImported: 0,
          errors: ['File not found: $filePath'],
          success: false,
        );
      }

      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Import students
      if (data['students'] != null) {
        for (final studentJson in data['students'] as List) {
          try {
            final entity = StudentEntity.fromJson(
              studentJson as Map<String, dynamic>,
            );
            // Check if already exists
            if (_db.studentsBox.get(entity.id) == null) {
              entity.needsSync = true; // Mark as needing sync
              await _db.studentsBox.put(entity.id, entity);
              studentsImported++;
            }
          } catch (e) {
            errors.add('Error importing student: $e');
          }
        }
      }

      // Import subjects
      if (data['subjects'] != null) {
        for (final subjectJson in data['subjects'] as List) {
          try {
            final entity = SubjectEntity.fromJson(
              subjectJson as Map<String, dynamic>,
            );
            if (_db.subjectsBox.get(entity.id) == null) {
              entity.needsSync = true;
              await _db.subjectsBox.put(entity.id, entity);
              subjectsImported++;
            }
          } catch (e) {
            errors.add('Error importing subject: $e');
          }
        }
      }

      // Import logs
      if (data['logs'] != null) {
        for (final logJson in data['logs'] as List) {
          try {
            final entity = LogEntryEntity.fromJson(
              logJson as Map<String, dynamic>,
            );
            if (_db.logEntriesBox.get(entity.id) == null) {
              entity.needsSync = true;
              await _db.logEntriesBox.put(entity.id, entity);
              logsImported++;
            }
          } catch (e) {
            errors.add('Error importing log: $e');
          }
        }
      }

      // Import settings if present
      if (data['settings'] != null) {
        try {
          final settingsJson = data['settings'] as Map<String, dynamic>;
          final settings = _db.familySettings;
          if (settingsJson['hourIncrement'] != null) {
            settings.hourIncrement =
                (settingsJson['hourIncrement'] as num).toDouble();
          }
          if (settingsJson['annualTargetHours'] != null) {
            settings.annualTargetHours =
                (settingsJson['annualTargetHours'] as num).toDouble();
          }
          if (settingsJson['state'] != null) {
            settings.state = settingsJson['state'] as String;
          }
          await settings.save();
        } catch (e) {
          errors.add('Error importing settings: $e');
        }
      }

      return ImportResult(
        studentsImported: studentsImported,
        subjectsImported: subjectsImported,
        logsImported: logsImported,
        errors: errors,
        success: errors.isEmpty,
      );
    } catch (e) {
      return ImportResult(
        studentsImported: studentsImported,
        subjectsImported: subjectsImported,
        logsImported: logsImported,
        errors: [...errors, 'Import failed: $e'],
        success: false,
      );
    }
  }

  /// Gather all data for export
  Map<String, dynamic> _gatherExportData({
    String? schoolYear,
    bool includeAllYears = true,
  }) {
    final students = _db.studentsBox.values.map((s) => s.toJson()).toList();
    final subjects = _db.subjectsBox.values.map((s) => s.toJson()).toList();

    List<Map<String, dynamic>> logs;
    if (includeAllYears) {
      logs = _db.logEntriesBox.values.map((l) => l.toJson()).toList();
    } else {
      final year = schoolYear ?? _db.familySettings.currentSchoolYear;
      logs = _db.logEntriesBox.values
          .where((l) => l.schoolYear == year)
          .map((l) => l.toJson())
          .toList();
    }

    final settings = {
      'hourIncrement': _db.familySettings.hourIncrement,
      'currentSchoolYear': _db.familySettings.currentSchoolYear,
      'annualTargetHours': _db.familySettings.annualTargetHours,
      'state': _db.familySettings.state,
    };

    return {
      'exportVersion': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'settings': settings,
      'students': students,
      'subjects': subjects,
      'logs': logs,
    };
  }

  /// Get export directory (app's documents folder)
  Future<Directory> _getExportDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${documentsDir.path}/exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Escape CSV special characters
  String _escapeCsv(String value) {
    return value.replaceAll('"', '""');
  }

  /// List available export files
  Future<List<FileSystemEntity>> listExports() async {
    final directory = await _getExportDirectory();
    if (!await directory.exists()) {
      return [];
    }
    return directory.listSync().where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => b.path.compareTo(a.path)); // Newest first
  }

  /// Delete an export file
  Future<bool> deleteExport(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
