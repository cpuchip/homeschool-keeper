import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/database/database_service.dart';
import '../../models/log_entry.dart';
import '../../models/student.dart';
import '../../models/subject.dart';
import '../../repositories/log_entry_repository.dart';
import '../../repositories/student_repository.dart';
import '../../repositories/subject_repository.dart';

/// PDF Report types
enum ReportType {
  hoursSummary,
  detailedLogs,
  studentProgress,
}

/// Result of PDF generation
class PdfExportResult {
  final String filePath;
  final String fileName;
  final DateTime generatedAt;

  const PdfExportResult({
    required this.filePath,
    required this.fileName,
    required this.generatedAt,
  });
}

/// Service for generating PDF reports for state compliance
class PdfReportService {
  final DatabaseService _db;
  final LogEntryRepository _logRepo;
  final StudentRepository _studentRepo;
  final SubjectRepository _subjectRepo;

  PdfReportService({
    DatabaseService? db,
    LogEntryRepository? logRepo,
    StudentRepository? studentRepo,
    SubjectRepository? subjectRepo,
  })  : _db = db ?? DatabaseService.instance,
        _logRepo = logRepo ?? LogEntryRepository(),
        _studentRepo = studentRepo ?? StudentRepository(),
        _subjectRepo = subjectRepo ?? SubjectRepository();

  /// Generate Hours Summary Report for state compliance
  Future<PdfExportResult> generateHoursSummaryReport({
    String? schoolYear,
    String? studentId,
  }) async {
    final year = schoolYear ?? _db.familySettings.currentSchoolYear;
    final pdf = pw.Document();

    // Get data
    final students = studentId != null
        ? [_studentRepo.getById(studentId)].whereType<Student>().toList()
        : _studentRepo.getAll();
    final subjects = _subjectRepo.getAll();

    // Family info
    const familyName = 'Homeschool Hours Report';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader(familyName, year),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildReportInfo(year),
          pw.SizedBox(height: 20),
          ...students.map(
            (student) => _buildStudentSummary(
              student,
              subjects,
              year,
            ),
          ),
          pw.SizedBox(height: 30),
          _buildTotalsSummary(students, year),
          pw.SizedBox(height: 30),
          _buildSubjectBreakdown(subjects, students, year),
          pw.SizedBox(height: 40),
          _buildSignatureLine(),
        ],
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final fileName = 'hours_summary_${year}_$timestamp.pdf';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return PdfExportResult(
      filePath: filePath,
      fileName: fileName,
      generatedAt: DateTime.now(),
    );
  }

  /// Generate Detailed Logs Report
  Future<PdfExportResult> generateDetailedLogsReport({
    String? schoolYear,
    String? studentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final year = schoolYear ?? _db.familySettings.currentSchoolYear;
    final pdf = pw.Document();

    // Get logs
    List<LogEntry> logs;
    if (startDate != null && endDate != null) {
      logs = _logRepo.getByDateRange(startDate, endDate, studentId: studentId);
    } else if (studentId != null) {
      logs = _logRepo.getByStudent(studentId, schoolYear: year);
    } else {
      logs = _logRepo.getBySchoolYear(year);
    }

    // Sort by date
    logs.sort((a, b) => a.date.compareTo(b.date));

    final students = _studentRepo.getAll();
    final subjects = _subjectRepo.getAll();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildHeader('Detailed Activity Log', year),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 20),
          _buildReportInfo(year),
          pw.SizedBox(height: 20),
          _buildLogsTable(logs, students, subjects),
          pw.SizedBox(height: 20),
          _buildLogsSummary(logs),
        ],
      ),
    );

    // Save PDF
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
    final fileName = 'detailed_logs_${year}_$timestamp.pdf';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return PdfExportResult(
      filePath: filePath,
      fileName: fileName,
      generatedAt: DateTime.now(),
    );
  }

  // === WIDGET BUILDERS ===

  pw.Widget _buildHeader(String title, String schoolYear) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'School Year: $schoolYear',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by Home School Logs',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            DateFormat('MM/dd/yyyy').format(DateTime.now()),
            style: const pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildReportInfo(String schoolYear) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Report Information',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text('School Year: $schoolYear'),
              ),
              pw.Expanded(
                child: pw.Text(
                  'Generated: ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStudentSummary(
    Student student,
    List<Subject> subjects,
    String schoolYear,
  ) {
    final logs = _logRepo.getByStudent(student.id, schoolYear: schoolYear);
    final totalHours = logs.fold<double>(0, (sum, l) => sum + l.hours);

    // Group by subject
    final hoursBySubject = <String, double>{};
    for (final log in logs) {
      hoursBySubject[log.subjectId] =
          (hoursBySubject[log.subjectId] ?? 0) + log.hours;
    }

    // Core vs elective hours
    double coreHours = 0;
    double electiveHours = 0;
    for (final entry in hoursBySubject.entries) {
      final subject = subjects.firstWhere(
        (s) => s.id == entry.key,
        orElse: () => Subject(
          id: '',
          familyId: '',
          name: 'Unknown',
          type: 'elective',
          color: '#000000',
          isDefault: false,
          sortOrder: 0,
          active: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (subject.type == 'core') {
        coreHours += entry.value;
      } else {
        electiveHours += entry.value;
      }
    }

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                student.name,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Grade: ${student.gradeLevel}',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildStatBox('Total Hours', totalHours.toStringAsFixed(1)),
              pw.SizedBox(width: 10),
              _buildStatBox('Core Hours', coreHours.toStringAsFixed(1)),
              pw.SizedBox(width: 10),
              _buildStatBox('Elective Hours', electiveHours.toStringAsFixed(1)),
              pw.SizedBox(width: 10),
              _buildStatBox('Log Entries', logs.length.toString()),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildStatBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildTotalsSummary(List<Student> students, String schoolYear) {
    double totalHours = 0;
    int totalLogs = 0;

    for (final student in students) {
      final logs = _logRepo.getByStudent(student.id, schoolYear: schoolYear);
      totalHours += logs.fold<double>(0, (sum, l) => sum + l.hours);
      totalLogs += logs.length;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text(
                totalHours.toStringAsFixed(1),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text('Total Hours'),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                totalLogs.toString(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text('Log Entries'),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                students.length.toString(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
              pw.Text('Students'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSubjectBreakdown(
    List<Subject> subjects,
    List<Student> students,
    String schoolYear,
  ) {
    // Aggregate hours by subject across all students
    final hoursBySubject = <String, double>{};
    for (final student in students) {
      final logs = _logRepo.getByStudent(student.id, schoolYear: schoolYear);
      for (final log in logs) {
        hoursBySubject[log.subjectId] =
            (hoursBySubject[log.subjectId] ?? 0) + log.hours;
      }
    }

    // Sort by hours descending
    final sortedEntries = hoursBySubject.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Hours by Subject',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Subject',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Type',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Hours',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
            ...sortedEntries.map((entry) {
              final subject = subjects.firstWhere(
                (s) => s.id == entry.key,
                orElse: () => Subject(
                  id: '',
                  familyId: '',
                  name: 'Unknown',
                  type: 'elective',
                  color: '#000000',
                  isDefault: false,
                  sortOrder: 0,
                  active: true,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );
              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(subject.name),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      subject.type == 'core' ? 'Core' : 'Elective',
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(entry.value.toStringAsFixed(1)),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildLogsTable(
    List<LogEntry> logs,
    List<Student> students,
    List<Subject> subjects,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(0.8),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Date',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Student',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Subject',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Hours',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(
                'Description',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        ...logs.map((log) {
          final student = students.firstWhere(
            (s) => s.id == log.studentId,
            orElse: () => Student(
              id: '',
              familyId: '',
              name: 'Unknown',
              gradeLevel: '',
              active: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          final subject = subjects.firstWhere(
            (s) => s.id == log.subjectId,
            orElse: () => Subject(
              id: '',
              familyId: '',
              name: 'Unknown',
              type: 'elective',
              color: '#000000',
              isDefault: false,
              sortOrder: 0,
              active: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  DateFormat('MM/dd/yy').format(log.date),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  student.name,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  subject.name,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  log.hours.toStringAsFixed(1),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(6),
                child: pw.Text(
                  log.description.length > 50
                      ? '${log.description.substring(0, 50)}...'
                      : log.description,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildLogsSummary(List<LogEntry> logs) {
    final totalHours = logs.fold<double>(0, (sum, l) => sum + l.hours);
    final dateRange = logs.isNotEmpty
        ? '${DateFormat('MM/dd/yyyy').format(logs.first.date)} - ${DateFormat('MM/dd/yyyy').format(logs.last.date)}'
        : 'No logs';

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          pw.Column(
            children: [
              pw.Text(
                logs.length.toString(),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Total Entries'),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                totalHours.toStringAsFixed(1),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text('Total Hours'),
            ],
          ),
          pw.Column(
            children: [
              pw.Text(
                dateRange,
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text('Date Range'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSignatureLine() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Parent/Guardian Certification',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'I certify that the above information is accurate and complete to the best of my knowledge.',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 30),
        pw.Row(
          children: [
            pw.Expanded(
              flex: 2,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black),
                      ),
                    ),
                    height: 20,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Signature',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 40),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(color: PdfColors.black),
                      ),
                    ),
                    height: 20,
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
