import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/log_entry.dart';
import '../../../providers/logs_provider.dart';
import '../../../providers/students_provider.dart';
import '../../../providers/subjects_provider.dart';

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(logsProvider.notifier).loadLogs(),
      ref.read(studentsProvider.notifier).loadStudents(),
      ref.read(subjectsProvider.notifier).loadSubjects(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(logsProvider);
    final studentsState = ref.watch(studentsProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final logs = logsState.sortedByDate;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Logs'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // TODO: Show filter options
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () {
                    // TODO: Show calendar view
                  },
                ),
              ],
            ),
            if (logsState.isLoading && logs.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (logs.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No logs yet',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your log entries will appear here',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final log = logs[index];
                      // Find student and subject names
                      final student = studentsState.students
                          .where((s) => s.id == log.studentId)
                          .firstOrNull;
                      final subject = subjectsState.subjects
                          .where((s) => s.id == log.subjectId)
                          .firstOrNull;

                      return _LogCard(
                        log: log,
                        studentName: student?.name ?? 'Unknown',
                        subjectName: subject?.name ?? 'Unknown',
                        subjectColor: subject?.color ?? '#3B82F6',
                      );
                    },
                    childCount: logs.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LogCard extends ConsumerWidget {
  final LogEntry log;
  final String studentName;
  final String subjectName;
  final String subjectColor;

  const _LogCard({
    required this.log,
    required this.studentName,
    required this.subjectName,
    required this.subjectColor,
  });

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(subjectColor);
    final dateFormat = DateFormat('MMM d, yyyy');
    final hoursText = log.hours == 1 ? '1 hour' : '${log.hours} hours';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        studentName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hoursText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      dateFormat.format(log.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showEditDialog(context, ref, log, studentName, subjectName);
                    } else if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Log'),
                          content: const Text(
                              'Are you sure you want to delete this log entry?',),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref.read(logsProvider.notifier).deleteLog(log.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
            if (log.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                log.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (log.locationType != 'home') ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log.locationName ?? LocationType.displayName(log.locationType),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    LogEntry log,
    String studentName,
    String subjectName,
  ) {
    final hoursController = TextEditingController(text: log.hours.toString());
    final descriptionController = TextEditingController(text: log.description);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Log Entry'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info display (read-only)
              Text(
                '$subjectName • $studentName',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                DateFormat('MMMM d, yyyy').format(log.date),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              
              // Hours input
              TextField(
                controller: hoursController,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              
              // Description input
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final hours = double.tryParse(hoursController.text);
              if (hours == null || hours <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid number of hours')),
                );
                return;
              }
              
              Navigator.pop(context);
              
              final result = await ref.read(logsProvider.notifier).updateLog(
                log.id,
                hours: hours,
                description: descriptionController.text,
              );
              
              if (result != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Log updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
