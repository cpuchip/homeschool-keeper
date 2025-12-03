import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings'),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Account section
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to profile
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to change password
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Preferences section
                Text(
                  'Preferences',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text('State'),
                        subtitle: const Text('Missouri'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Change state
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('School Year'),
                        subtitle: const Text('2024-2025'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Change school year
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.dark_mode_outlined),
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Follow system'),
                        value: false,
                        onChanged: (value) {
                          // TODO: Toggle dark mode
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Data section
                Text(
                  'Data',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.cloud_sync_outlined),
                        title: const Text('Sync'),
                        subtitle: const Text('Last synced: Never'),
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            // TODO: Sync now
                          },
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.download_outlined),
                        title: const Text('Export Data'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Export data
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // About section
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('About Homeschool Keeper'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Show about dialog
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.privacy_tip_outlined),
                        title: const Text('Privacy Policy'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Open privacy policy
                        },
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(Icons.tag),
                        title: Text('Version'),
                        trailing: Text('1.0.0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout button
                OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Sign Out'),
                        content: const Text('Are you sure you want to sign out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Sign Out'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      await ref.read(authStateProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
