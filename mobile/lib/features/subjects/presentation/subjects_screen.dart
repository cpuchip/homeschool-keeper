import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/subject.dart';
import '../../../providers/subjects_provider.dart';

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subjectsProvider.notifier).loadSubjects();
    });
  }

  void _showAddSubjectDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _SubjectSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjectsState = ref.watch(subjectsProvider);
    final coreSubjects = subjectsState.coreSubjects;
    final electiveSubjects = subjectsState.electiveSubjects;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(subjectsProvider.notifier).loadSubjects(),
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(
              title: Text('Subjects'),
            ),
            if (subjectsState.isLoading && subjectsState.subjects.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Core Subjects section
                    Text(
                      'Core Subjects (${coreSubjects.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Required for Missouri compliance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (coreSubjects.isEmpty)
                      Center(
                        child: Text(
                          'No core subjects added yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    else
                      ...coreSubjects.map((s) => _SubjectCard(subject: s)),
                    const SizedBox(height: 24),

                    // Electives section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Electives (${electiveSubjects.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton.icon(
                          onPressed: _showAddSubjectDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (electiveSubjects.isEmpty)
                      Center(
                        child: Text(
                          'No electives added yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      )
                    else
                      ...electiveSubjects.map((s) => _SubjectCard(subject: s)),
                  ]),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SubjectCard extends ConsumerWidget {
  final Subject subject;

  const _SubjectCard({required this.subject});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', ''), radix: 16) | 0xFF000000);
    } catch (_) {
      return Colors.blue;
    }
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SubjectSheet(subject: subject),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _parseColor(subject.color);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(
            subject.type == SubjectType.core ? Icons.star : Icons.extension,
            color: color,
          ),
        ),
        title: Text(subject.name),
        subtitle: Text(
          subject.type == SubjectType.core ? 'Core subject' : 'Elective',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'edit') {
              _showEditSheet(context);
            } else if (value == 'delete') {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Subject'),
                  content:
                      Text('Are you sure you want to delete ${subject.name}?'),
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
                await ref
                    .read(subjectsProvider.notifier)
                    .deleteSubject(subject.id);
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

class _SubjectSheet extends ConsumerStatefulWidget {
  final Subject? subject;
  
  const _SubjectSheet({this.subject});

  @override
  ConsumerState<_SubjectSheet> createState() => _SubjectSheetState();
}

class _SubjectSheetState extends ConsumerState<_SubjectSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late String _selectedType;
  late String _selectedColor;
  bool _isLoading = false;

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.subject!.name;
      _selectedType = widget.subject!.type;
      _selectedColor = widget.subject!.color;
    } else {
      _selectedType = SubjectType.elective;
      _selectedColor = SubjectColors.all.first;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        final updated = await ref.read(subjectsProvider.notifier).updateSubject(
              widget.subject!.id,
              name: _nameController.text.trim(),
              type: _selectedType,
              color: _selectedColor,
            );

        if (mounted && updated != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Updated ${updated.name}')),
          );
        }
      } else {
        final subject = await ref.read(subjectsProvider.notifier).createSubject(
              name: _nameController.text.trim(),
              type: _selectedType,
              color: _selectedColor,
            );

        if (mounted && subject != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Added ${subject.name}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${_isEditing ? "update" : "add"} subject: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit Subject' : 'Add Subject',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Subject Name',
                prefixIcon: Icon(Icons.book),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: SubjectType.core, child: Text('Core')),
                DropdownMenuItem(
                    value: SubjectType.elective, child: Text('Elective'),),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: SubjectColors.all.map((color) {
                final colorValue = Color(
                    int.parse(color.replaceFirst('#', ''), radix: 16) |
                        0xFF000000,);
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: colorValue, blurRadius: 8)]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save Changes' : 'Add Subject'),
            ),
          ],
        ),
      ),
    );
  }
}
