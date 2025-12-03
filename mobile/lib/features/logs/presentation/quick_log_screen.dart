import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class QuickLogScreen extends ConsumerStatefulWidget {
  const QuickLogScreen({super.key});

  @override
  ConsumerState<QuickLogScreen> createState() => _QuickLogScreenState();
}

class _QuickLogScreenState extends ConsumerState<QuickLogScreen> {
  String? _selectedStudent;
  String? _selectedSubject;
  double _hours = 1.0;
  bool _isAtHome = true;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedStudent == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a student and subject')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // TODO: Implement actual log creation API call
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Log entry created!')),
        );
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create log: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Log'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Student selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Student',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    // TODO: Replace with actual student list
                    DropdownButtonFormField<String>(
                      value: _selectedStudent,
                      decoration: const InputDecoration(
                        hintText: 'Select a student',
                      ),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Add a student first')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStudent = value);
                      },
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
                    // TODO: Replace with actual subject list
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Reading',
                        'Math',
                        'Science',
                        'Social Studies',
                        'Language Arts',
                      ].map((subject) {
                        final isSelected = _selectedSubject == subject;
                        return FilterChip(
                          label: Text(subject),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSubject = selected ? subject : null;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('15 min'),
                        const Text('8 hours'),
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
              onPressed: _isLoading ? null : _handleSubmit,
              icon: _isLoading
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
