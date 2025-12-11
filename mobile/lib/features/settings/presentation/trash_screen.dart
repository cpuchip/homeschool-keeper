import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/student.dart';
import '../../../models/subject.dart';
import '../../../providers/logs_provider.dart';
import '../../../providers/students_provider.dart';
import '../../../providers/subjects_provider.dart';
import '../../../repositories/student_repository.dart';
import '../../../repositories/subject_repository.dart';

/// Provider for accessing repositories in Trash screen
final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository();
});

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deletedStudents = ref.watch(studentRepositoryProvider).getDeleted();
    final deletedSubjects = ref.watch(subjectRepositoryProvider).getDeleted();
    final totalDeleted = deletedStudents.length + deletedSubjects.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Trash ($totalDeleted)'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Students (${deletedStudents.length})',
              icon: const Icon(Icons.person_outline),
            ),
            Tab(
              text: 'Subjects (${deletedSubjects.length})',
              icon: const Icon(Icons.book_outlined),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _DeletedStudentsList(students: deletedStudents),
          _DeletedSubjectsList(subjects: deletedSubjects),
        ],
      ),
    );
  }
}

class _DeletedStudentsList extends ConsumerWidget {
  final List<Student> students;

  const _DeletedStudentsList({required this.students});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'No deleted students',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final logCount =
            ref.read(logEntryRepositoryProvider).countByStudent(student.id);

        return _DeletedItemCard(
          icon: Icons.person,
          title: student.name,
          subtitle: 'Grade ${student.gradeLevel}',
          logCount: logCount,
          onRestore: () async {
            await ref.read(studentsProvider.notifier).updateStudent(
                  student.id,
                  active: true,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${student.name} restored')),
              );
            }
          },
          onPermanentDelete: () => _confirmPermanentDelete(
            context,
            ref,
            type: 'student',
            name: student.name,
            logCount: logCount,
            onConfirm: () async {
              await ref.read(studentRepositoryProvider).hardDelete(student.id);
              // Also delete associated logs if any
              if (logCount > 0) {
                // Note: You may want to implement this in production
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${student.name} permanently deleted'),
                  ),
                );
                // Force refresh
                (context as Element).markNeedsBuild();
              }
            },
          ),
        );
      },
    );
  }
}

class _DeletedSubjectsList extends ConsumerWidget {
  final List<Subject> subjects;

  const _DeletedSubjectsList({required this.subjects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'No deleted subjects',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subject = subjects[index];
        final logCount =
            ref.read(logEntryRepositoryProvider).countBySubject(subject.id);

        return _DeletedItemCard(
          icon: Icons.book,
          iconColor: _parseColor(subject.color),
          title: subject.name,
          subtitle: subject.type == 'core' ? 'Core subject' : 'Elective',
          logCount: logCount,
          onRestore: () async {
            await ref.read(subjectsProvider.notifier).updateSubject(
                  subject.id,
                  active: true,
                );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${subject.name} restored')),
              );
            }
          },
          onPermanentDelete: () => _confirmPermanentDelete(
            context,
            ref,
            type: 'subject',
            name: subject.name,
            logCount: logCount,
            onConfirm: () async {
              await ref.read(subjectRepositoryProvider).hardDelete(subject.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${subject.name} permanently deleted'),
                  ),
                );
                // Force refresh
                (context as Element).markNeedsBuild();
              }
            },
          ),
        );
      },
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

class _DeletedItemCard extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final int logCount;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  const _DeletedItemCard({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.logCount,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  (iconColor ?? theme.colorScheme.primary).withValues(
                alpha: 0.2,
              ),
              child: Icon(icon, color: iconColor ?? theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (logCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$logCount log${logCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Restore',
              onPressed: onRestore,
              color: Colors.green,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Delete permanently',
              onPressed: onPermanentDelete,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

void _confirmPermanentDelete(
  BuildContext context,
  WidgetRef ref, {
  required String type,
  required String name,
  required int logCount,
  required VoidCallback onConfirm,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Permanently Delete $name?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This action cannot be undone.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('The $type will be permanently removed from your device.'),
          if (logCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This $type has $logCount associated log${logCount == 1 ? '' : 's'}. '
                      'Consider restoring instead to preserve your records.',
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete Forever'),
        ),
      ],
    ),
  );
}
