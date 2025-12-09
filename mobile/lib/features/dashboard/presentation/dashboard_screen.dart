import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/logs_provider.dart';
import '../../../providers/stats_provider.dart';
import '../../../providers/students_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load data when dashboard mounts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      ref.read(statsProvider.notifier).loadFamilyStats(),
      ref.read(studentsProvider.notifier).loadStudents(),
      ref.read(logsProvider.notifier).loadLogs(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(statsProvider);
    final studentsState = ref.watch(studentsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar.large(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    // TODO: Show notifications
                  },
                ),
              ],
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick Log Button
                  _QuickLogCard(
                    onTap: () => context.go('/quick-log'),
                  ),
                  const SizedBox(height: 16),

                  // Hours Summary
                  _HoursSummaryCard(statsState: statsState),
                  const SizedBox(height: 16),

                  // Recent Logs
                  const _RecentLogsCard(),
                  const SizedBox(height: 16),

                  // Students Overview
                  _StudentsOverviewCard(studentsState: studentsState),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLogCard extends StatelessWidget {
  final VoidCallback onTap;
  
  const _QuickLogCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                Icons.add_circle,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Log',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Log hours in under 30 seconds',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoursSummaryCard extends StatelessWidget {
  final StatsState statsState;

  const _HoursSummaryCard({required this.statsState});

  @override
  Widget build(BuildContext context) {
    final stats = statsState.familyStats;
    final isLoading = statsState.isLoading;
    final totalHours = stats?.totalHours ?? 0;
    const totalTarget = 1000.0; // TODO: Get from family settings

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  stats?.schoolYear ?? 'This Year',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () {
                    // TODO: View detailed breakdown
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _HourStat(
                      label: 'Total Hours',
                      value: totalHours.toStringAsFixed(1),
                      target: totalTarget.toStringAsFixed(0),
                      progress: (totalHours / totalTarget).clamp(0.0, 1.0),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _HourStat(
                      label: 'Students',
                      value: '${stats?.students.length ?? 0}',
                      target: '',
                      progress: 0,
                      color: Theme.of(context).colorScheme.secondary,
                      hideProgress: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _HourStat(
                      label: 'Log Entries',
                      value: '${stats?.totalLogCount ?? 0}',
                      target: '',
                      progress: 0,
                      color: Theme.of(context).colorScheme.tertiary,
                      hideProgress: true,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HourStat extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final double progress;
  final Color color;
  final bool hideProgress;

  const _HourStat({
    required this.label,
    required this.value,
    required this.target,
    required this.progress,
    required this.color,
    this.hideProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        if (target.isNotEmpty)
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.titleLarge,
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' / $target',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          )
        else
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        if (!hideProgress) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ],
      ],
    );
  }
}

class _RecentLogsCard extends StatelessWidget {
  const _RecentLogsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Logs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => context.go('/logs'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No logs yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start by creating your first log entry',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentsOverviewCard extends StatelessWidget {
  final StudentsState studentsState;

  const _StudentsOverviewCard({required this.studentsState});

  @override
  Widget build(BuildContext context) {
    final students = studentsState.activeStudents;
    final isLoading = studentsState.isLoading;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Students (${students.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => context.go('/students'),
                  child: const Text('Manage'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (students.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add_outlined,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No students added',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    FilledButton.tonal(
                      onPressed: () => context.go('/students'),
                      child: const Text('Add Student'),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: students.take(3).map((student) {
                  final color = student.avatarColor != null
                      ? Color(
                          int.parse(
                                student.avatarColor!.replaceFirst('#', ''),
                                radix: 16,
                              ) |
                              0xFF000000,
                        )
                      : Theme.of(context).colorScheme.primary;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: color,
                      child: Text(
                        student.name.isNotEmpty
                            ? student.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(student.name),
                    subtitle: Text('Grade ${student.gradeLevel}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/students'),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
