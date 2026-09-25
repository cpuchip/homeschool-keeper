import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../models/log_entry.dart';
import '../../../providers/logs_provider.dart';
import '../../../providers/students_provider.dart';
import '../../../providers/subjects_provider.dart';
import '../../work_samples/work_sample_widget.dart';

/// Screen for viewing and editing a single log entry, including work sample attachments.
class LogDetailScreen extends ConsumerStatefulWidget {
  final String logId;

  const LogDetailScreen({super.key, required this.logId});

  @override
  ConsumerState<LogDetailScreen> createState() => _LogDetailScreenState();
}

class _LogDetailScreenState extends ConsumerState<LogDetailScreen> {
  late TextEditingController _hoursController;
  late TextEditingController _descriptionController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _hoursController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initControllers(LogEntry log) {
    if (_hoursController.text.isEmpty) {
      _hoursController.text = log.hours.toString();
      _descriptionController.text = log.description;
    }
  }

  Future<void> _saveChanges(LogEntry log) async {
    final hours = double.tryParse(_hoursController.text);
    if (hours == null || hours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number of hours')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await ref.read(logsProvider.notifier).updateLog(
            log.id,
            hours: hours,
            description: _descriptionController.text,
          );

      if (mounted) {
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Log updated successfully')),
          );
          setState(() => _isEditing = false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update log'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(logsProvider);
    final studentsState = ref.watch(studentsProvider);
    final subjectsState = ref.watch(subjectsProvider);

    // Find the log entry
    final log = logsState.logs.where((l) => l.id == widget.logId).firstOrNull;

    if (log == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Log Details')),
        body: const Center(child: Text('Log not found')),
      );
    }

    _initControllers(log);

    // Find student and subject names
    final student = studentsState.students.where((s) => s.id == log.studentId).firstOrNull;
    final subject = subjectsState.subjects.where((s) => s.id == log.subjectId).firstOrNull;

    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _hoursController.text = log.hours.toString();
                  _descriptionController.text = log.description;
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card with subject and student
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _parseColor(subject?.color ?? '#3B82F6'),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject?.name ?? 'Unknown Subject',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student?.name ?? 'Unknown Student',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          Text(
                            dateFormat.format(log.date),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
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
              ),
            ),
            const SizedBox(height: 16),

            // Hours section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hours',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextField(
                        controller: _hoursController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          suffixText: 'hours',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      )
                    else
                      Text(
                        '${log.hours} hours',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_isEditing)
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'What did you work on?',
                        ),
                        maxLines: 4,
                      )
                    else
                      Text(
                        log.description.isNotEmpty
                            ? log.description
                            : 'No description',
                        style: log.description.isNotEmpty
                            ? Theme.of(context).textTheme.bodyLarge
                            : Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Work Samples section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: WorkSampleAttachments(
                  logEntryId: log.id,
                  groupId: log.groupId,
                  studentId: log.studentId,
                  familyId: log.familyId,
                  uploadedBy: log.studentId, // TODO: Get actual user ID
                  readOnly: false,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location info
            Card(
              child: ListTile(
                leading: Icon(
                  log.locationType == 'home' ? Icons.home : Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  log.locationType == 'home' ? 'At Home' : 'Other Location',
                ),
                subtitle: log.locationName != null
                    ? Text(log.locationName!)
                    : null,
              ),
            ),

            // Save button when editing
            if (_isEditing) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : () => _saveChanges(log),
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save Changes'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);
    } catch (_) {
      return Colors.blue;
    }
  }
}
