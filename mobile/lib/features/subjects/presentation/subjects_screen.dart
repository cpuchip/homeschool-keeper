import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Subjects'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Core Subjects section
                Text(
                  'Core Subjects',
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
                ..._buildCoreSubjects(context),
                const SizedBox(height: 24),
                
                // Electives section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Electives',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Add custom subject
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'No custom subjects added yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCoreSubjects(BuildContext context) {
    final coreSubjects = [
      {'name': 'Reading', 'icon': Icons.menu_book, 'color': Colors.blue},
      {'name': 'Math', 'icon': Icons.calculate, 'color': Colors.green},
      {'name': 'Science', 'icon': Icons.science, 'color': Colors.purple},
      {'name': 'Social Studies', 'icon': Icons.public, 'color': Colors.orange},
      {'name': 'Language Arts', 'icon': Icons.abc, 'color': Colors.red},
    ];

    return coreSubjects.map((subject) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: (subject['color'] as Color).withOpacity(0.2),
            child: Icon(
              subject['icon'] as IconData,
              color: subject['color'] as Color,
            ),
          ),
          title: Text(subject['name'] as String),
          subtitle: const Text('Core subject'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: View subject details
          },
        ),
      );
    }).toList();
  }
}
