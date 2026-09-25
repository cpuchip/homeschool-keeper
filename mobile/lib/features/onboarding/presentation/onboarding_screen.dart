import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../models/student.dart';
import '../../../models/subject.dart';
import '../../../providers/students_provider.dart';
import '../../../providers/subjects_provider.dart';
import '../../../providers/sync_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 0;
  final int _totalSteps = 3;
  bool _isLoading = false;

  // Step 1: School Year
  late DateTime _schoolYearStart;
  late DateTime _schoolYearEnd;
  double _hourIncrement = 0.25;

  // Step 2: Subjects
  final List<_SubjectItem> _availableSubjects = [];
  final Set<String> _selectedSubjects = {};
  final _newSubjectController = TextEditingController();
  String _newSubjectType = 'elective';

  // Step 3: Students
  final List<_StudentItem> _students = [_StudentItem()];

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
  }

  void _initializeDefaults() {
    // Set default school year
    final now = DateTime.now();
    final year = now.month >= 8 ? now.year : now.year - 1;
    _schoolYearStart = DateTime(year, 8, 1);
    _schoolYearEnd = DateTime(year + 1, 5, 31);

    // Initialize default subjects
    _availableSubjects.addAll([
      _SubjectItem(name: 'Math', type: 'core', color: '#10B981', isDefault: true),
      _SubjectItem(name: 'Language Arts', type: 'core', color: '#F59E0B', isDefault: true),
      _SubjectItem(name: 'Reading', type: 'core', color: '#3B82F6', isDefault: true),
      _SubjectItem(name: 'Science', type: 'core', color: '#8B5CF6', isDefault: true),
      _SubjectItem(name: 'Social Studies', type: 'core', color: '#EC4899', isDefault: true),
      _SubjectItem(name: 'Art', type: 'elective', color: '#06B6D4', isDefault: true),
      _SubjectItem(name: 'Music', type: 'elective', color: '#F97316', isDefault: true),
      _SubjectItem(name: 'Physical Education', type: 'elective', color: '#84CC16', isDefault: true),
      _SubjectItem(name: 'Health', type: 'elective', color: '#14B8A6', isDefault: true),
    ]);

    // Select core subjects by default
    _selectedSubjects.addAll([
      'Math',
      'Language Arts',
      'Reading',
      'Science',
      'Social Studies',
    ]);
  }

  @override
  void dispose() {
    _newSubjectController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _toggleSubject(String name) {
    setState(() {
      if (_selectedSubjects.contains(name)) {
        _selectedSubjects.remove(name);
      } else {
        _selectedSubjects.add(name);
      }
    });
  }

  void _addCustomSubject() {
    final name = _newSubjectController.text.trim();
    if (name.isEmpty) return;

    // Check if already exists
    if (_availableSubjects.any(
      (s) => s.name.toLowerCase() == name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject already exists')),
      );
      return;
    }

    // Pick a color
    final usedColors = _availableSubjects.map((s) => s.color).toSet();
    final availableColors = SubjectColors.all.where((c) => !usedColors.contains(c)).toList();
    final color = availableColors.isNotEmpty
        ? availableColors.first
        : SubjectColors.all[_availableSubjects.length % SubjectColors.all.length];

    setState(() {
      _availableSubjects.add(_SubjectItem(
        name: name,
        type: _newSubjectType,
        color: color,
        isDefault: false,
      ),);
      _selectedSubjects.add(name);
      _newSubjectController.clear();
    });
  }

  void _removeCustomSubject(String name) {
    setState(() {
      _availableSubjects.removeWhere((s) => s.name == name);
      _selectedSubjects.remove(name);
    });
  }

  void _addStudent() {
    setState(() {
      _students.add(_StudentItem());
    });
  }

  void _removeStudent(int index) {
    if (_students.length > 1) {
      setState(() {
        _students.removeAt(index);
      });
    }
  }

  Future<void> _completeOnboarding() async {
    // Validate students
    final validStudents = _students.where((s) => s.name.isNotEmpty).toList();
    if (validStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one student')),
      );
      return;
    }

    if (_selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one subject')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create subjects locally
      final subjectsNotifier = ref.read(subjectsProvider.notifier);
      for (final subjectItem in _availableSubjects) {
        if (_selectedSubjects.contains(subjectItem.name)) {
          await subjectsNotifier.createSubject(
            name: subjectItem.name,
            type: subjectItem.type,
            color: subjectItem.color,
          );
        }
      }

      // Create students locally
      final studentsNotifier = ref.read(studentsProvider.notifier);
      for (final student in validStudents) {
        await studentsNotifier.createStudent(
          name: student.name,
          gradeLevel: student.gradeLevel.isNotEmpty ? student.gradeLevel : 'K',
          avatarColor: AvatarColors.all[validStudents.indexOf(student) % AvatarColors.all.length],
        );
      }

      // Sync with server
      await ref.read(syncProvider.notifier).performFullSync();

      // Mark onboarding complete (this should be done on server-side via API)
      // For now, navigate to dashboard - the server should mark onboarding complete
      // when it receives the first sync with subjects/students

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Setup failed: $e')),
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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Welcome to Home School Logs! 📚',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Let's set up your family's homeschool tracking.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${((_currentStep + 1) / _totalSteps * 100).round()}% complete',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildCurrentStep(),
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _prevStep,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (_currentStep < _totalSteps - 1)
                    FilledButton(
                      onPressed: _nextStep,
                      child: const Text('Continue'),
                    )
                  else
                    FilledButton(
                      onPressed: _isLoading ? null : _completeOnboarding,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Complete Setup'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildSchoolYearStep();
      case 1:
        return _buildSubjectsStep();
      case 2:
        return _buildStudentsStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSchoolYearStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Define your school year',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'When does your school year start and end?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // Start Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date'),
              subtitle: Text(
                '${_schoolYearStart.month}/${_schoolYearStart.day}/${_schoolYearStart.year}',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _schoolYearStart,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _schoolYearStart = date);
                }
              },
            ),

            // End Date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: const Text('End Date'),
              subtitle: Text(
                '${_schoolYearEnd.month}/${_schoolYearEnd.day}/${_schoolYearEnd.year}',
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _schoolYearEnd,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() => _schoolYearEnd = date);
                }
              },
            ),

            const SizedBox(height: 16),

            // Hour increment
            Text(
              'Time Tracking Precision',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<double>(
              segments: const [
                ButtonSegment(value: 0.25, label: Text('15 min')),
                ButtonSegment(value: 0.5, label: Text('30 min')),
                ButtonSegment(value: 1.0, label: Text('1 hour')),
              ],
              selected: {_hourIncrement},
              onSelectionChanged: (selection) {
                setState(() => _hourIncrement = selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsStep() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose your subjects',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the subjects you\'ll be teaching, or add your own.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Subject chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSubjects.map((subject) {
                    final isSelected = _selectedSubjects.contains(subject.name);
                    final color = _parseColor(subject.color);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        FilterChip(
                          selected: isSelected,
                          label: Text(subject.name),
                          avatar: CircleAvatar(
                            backgroundColor: color,
                            radius: 8,
                          ),
                          selectedColor: color.withValues(alpha: 0.2),
                          checkmarkColor: color,
                          onSelected: (_) => _toggleSubject(subject.name),
                        ),
                        if (!subject.isDefault)
                          Positioned(
                            top: -4,
                            right: -4,
                            child: GestureDetector(
                              onTap: () => _removeCustomSubject(subject.name),
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),

                const SizedBox(height: 8),
                Text(
                  '${_selectedSubjects.length} subjects selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Add custom subject
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Custom Subject',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newSubjectController,
                        decoration: const InputDecoration(
                          hintText: 'Subject name (e.g., Spanish)',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addCustomSubject(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _newSubjectType,
                      items: const [
                        DropdownMenuItem(value: 'core', child: Text('Core')),
                        DropdownMenuItem(value: 'elective', child: Text('Elective')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _newSubjectType = value);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _addCustomSubject,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentsStep() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add your students',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Who will you be teaching?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            // Student list
            ..._students.asMap().entries.map((entry) {
              final index = entry.key;
              final student = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Student name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        onChanged: (value) => student.name = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: student.gradeLevel.isEmpty ? null : student.gradeLevel,
                        decoration: const InputDecoration(
                          hintText: 'Grade',
                          isDense: true,
                        ),
                        items: GradeLevels.all
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => student.gradeLevel = value);
                          }
                        },
                      ),
                    ),
                    if (_students.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: Colors.red,
                        onPressed: () => _removeStudent(index),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _addStudent,
              icon: const Icon(Icons.add),
              label: const Text('Add another student'),
            ),
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

// Helper classes
class _SubjectItem {
  final String name;
  final String type;
  final String color;
  final bool isDefault;

  _SubjectItem({
    this.name = '',
    this.type = 'elective',
    this.color = '#3B82F6',
    this.isDefault = false,
  });
}

class _StudentItem {
  String name = '';
  String gradeLevel = '';
}
