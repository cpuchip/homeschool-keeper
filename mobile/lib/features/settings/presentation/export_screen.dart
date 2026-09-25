import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../providers/students_provider.dart';
import '../../export/export_import_service.dart';
import '../../export/pdf_report_service.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  bool _isLoading = false;
  String? _selectedStudentId;
  String _selectedReportType = 'hours_summary';

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentsProvider);
    final students = studentsState.activeStudents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Reports'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // PDF Reports Section
            _buildSectionCard(
              title: 'PDF Reports',
              subtitle: 'Generate compliance reports for state submission',
              icon: Icons.picture_as_pdf,
              iconColor: Colors.red,
              children: [
                // Report Type Selection
                const Text(
                  'Report Type',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'hours_summary',
                      label: Text('Hours Summary'),
                      icon: Icon(Icons.summarize),
                    ),
                    ButtonSegment(
                      value: 'detailed_logs',
                      label: Text('Detailed Logs'),
                      icon: Icon(Icons.list_alt),
                    ),
                  ],
                  selected: {_selectedReportType},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedReportType = selection.first);
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Filter by Student (optional)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedStudentId,
                  decoration: const InputDecoration(
                    hintText: 'All students',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All students'),
                    ),
                    ...students.map(
                      (s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStudentId = value);
                  },
                ),
                const SizedBox(height: 20),

                // Generate Button
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isLoading ? null : _generatePdfReport,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.picture_as_pdf),
                        label: Text(
                          _isLoading ? 'Generating...' : 'Generate PDF',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // CSV Export Section
            _buildSectionCard(
              title: 'CSV Export',
              subtitle: 'Export log entries to spreadsheet format',
              icon: Icons.table_chart,
              iconColor: Colors.green,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.download),
                  title: const Text('Export All Logs'),
                  subtitle: const Text('Current school year'),
                  trailing: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _isLoading ? null : _exportCsv,
                  ),
                  onTap: _isLoading ? null : _exportCsv,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // JSON Backup Section
            _buildSectionCard(
              title: 'Full Backup',
              subtitle: 'Export all data as JSON for backup',
              icon: Icons.backup,
              iconColor: Colors.blue,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cloud_download),
                  title: const Text('Export Full Backup'),
                  subtitle: const Text('All students, subjects, and logs'),
                  trailing: IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _isLoading ? null : _exportJsonBackup,
                  ),
                  onTap: _isLoading ? null : _exportJsonBackup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withValues(alpha: 0.1),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Future<void> _generatePdfReport() async {
    setState(() => _isLoading = true);

    try {
      final pdfService = PdfReportService();
      PdfExportResult result;

      if (_selectedReportType == 'hours_summary') {
        result = await pdfService.generateHoursSummaryReport(
          studentId: _selectedStudentId,
        );
      } else {
        result = await pdfService.generateDetailedLogsReport(
          studentId: _selectedStudentId,
        );
      }

      if (!mounted) return;

      // Show action dialog
      _showExportCompleteDialog(
        context,
        fileName: result.fileName,
        filePath: result.filePath,
        isPdf: true,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _isLoading = true);

    try {
      final exportService = ExportImportService();
      final result = await exportService.exportToCsv(
        studentId: _selectedStudentId,
      );

      if (!mounted) return;

      _showExportCompleteDialog(
        context,
        fileName: result.fileName,
        filePath: result.filePath,
        isPdf: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportJsonBackup() async {
    setState(() => _isLoading = true);

    try {
      final exportService = ExportImportService();
      final result = await exportService.exportToJson();

      if (!mounted) return;

      _showExportCompleteDialog(
        context,
        fileName: result.fileName,
        filePath: result.filePath,
        isPdf: false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export backup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showExportCompleteDialog(
    BuildContext context, {
    required String fileName,
    required String filePath,
    required bool isPdf,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            SizedBox(width: 8),
            Text('Export Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: $fileName'),
            const SizedBox(height: 8),
            Text(
              'Saved to: $filePath',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (isPdf)
            TextButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                // Open print preview
                final file = File(filePath);
                await Printing.layoutPdf(
                  onLayout: (_) => file.readAsBytes(),
                );
              },
              icon: const Icon(Icons.print),
              label: const Text('Print'),
            ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Share file
              await Share.shareXFiles(
                [XFile(filePath)],
                subject: fileName,
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }
}
