import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/providers.dart';

class QuickLogScreen extends ConsumerStatefulWidget {
  const QuickLogScreen({super.key});

  @override
  ConsumerState<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends ConsumerState<QuickLogScreen> {
  final Set<String> _selectedStudentIds = {};
  String? _selectedSubjectId;
  double _hours = 1.0;
  bool _isAtHome = true;
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final studentsState = ref.read(studentsProvider);
      if (studentsState.students.isEmpty && !studentsState.isLoading) {
        ref.read(studentsProvider.notifier).loadStudents();
      }
      final subjectsState = ref.read(subjectsProvider);
      if (subjectsState.subjects.isEmpty && !subjectsState.isLoading) {
        ref.read(subjectsProvider.notifier).loadSubjects();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedStudentIds.isEmpty || _selectedSubjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one student and a subject')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await ref.read(logsProvider.notifier).createMultiStudentLog(
        studentIds: _selectedStudentIds.toList(),
        subjectId: _selectedSubjectId!,
        date: DateTime.now(),
        hours: _hours,
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        locationType: _isAtHome ? 'home' : 'other',
      );

      if (mounted) {
        if (result != null && result.isNotEmpty) {
          final studentCount = result.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                studentCount == 1
                    ? 'Log entry created!'
                    : 'Created $studentCount log entries!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          ref.read(statsProvider.notifier).loadFamilyStats();
          context.go('/dashboard');
        } else {
          final error = ref.read(logsProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create log: ${error ?? "Unknown error"}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create log: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentsProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final students = studentsState.activeStudents;
    final subjects = subjectsState.activeSubjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Log'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student selector (multi-select with chips)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Students',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (students.length > 1)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (_selectedStudentIds.length == students.length) {
                                  _selectedStudentIds.clear();
                                } else {
                                  _selectedStudentIds.clear();
                                  _selectedStudentIds.addAll(students.map((s) => s.id));
                                }
                              });
                            },
                            child: Text(
                              _selectedStudentIds.length == students.length
                                  ? 'Clear All'
                                  : 'Select All',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (studentsState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (students.isEmpty)
                      const Text(
                        'No students yet. Add a student first.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: students.map((student) {
                          final isSelected = _selectedStudentIds.contains(student.id);
                          return FilterChip(
                            label: Text(student.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedStudentIds.add(student.id);
                                } else {
                                  _selectedStudentIds.remove(student.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    if (_selectedStudentIds.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_selectedStudentIds.length} students selected - will create ${_selectedStudentIds.length} log entries',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subject selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (subjectsState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (subjects.isEmpty)
                      const Text(
                        'No subjects yet. Add a subject first.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subjects.map((subject) {
                          final isSelected = _selectedSubjectId == subject.id;
                          return FilterChip(
                            label: Text(subject.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSubjectId = selected ? subject.id : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Hours slider
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Duration',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${_hours.toStringAsFixed(1)} hours',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _hours,
                      min: 0.25,
                      max: 8,
                      divisions: 31,
                      label: '${_hours.toStringAsFixed(1)} hours',
                      onChanged: (value) {
                        setState(() => _hours = value);
                      },
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('15 min'),
                        Text('8 hours'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // At home toggle
            Card(
              child: SwitchListTile(
                title: const Text('At Home'),
                subtitle: const Text('Did this take place at your home location?'),
                value: _isAtHome,
                onChanged: (value) {
                  setState(() => _isAtHome = value);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes (optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'What did you work on?',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Log Entry'),
            ),
          ],
        ),
      ),
    );
  }
}
