import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/database_service.dart';
import '../../../providers/auth_provider.dart';
import '../../export/failsafe_backup_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoBackupEnabled = true;
  String? _backupPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final db = DatabaseService.instance;
    if (db.isInitialized) {
      setState(() {
        _autoBackupEnabled = db.familySettings.autoBackupEnabled;
      });
    }
    final path = await FailsafeBackupService.instance.getBackupDirectoryPath();
    if (mounted) {
      setState(() {
        _backupPath = path;
      });
    }
  }

  Future<void> _toggleAutoBackup(bool value) async {
    final db = DatabaseService.instance;
    if (!db.isInitialized) return;

    db.familySettings.autoBackupEnabled = value;
    await db.familySettings.save();
    setState(() {
      _autoBackupEnabled = value;
    });
  }

  Future<void> _openBackupFolder() async {
    final opened = await FailsafeBackupService.instance.openBackupFolder();
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open backup folder'),
        ),
      );
    }
  }

  Future<void> _backupNow() async {
    final path = await FailsafeBackupService.instance.performBackupNow();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            path != null ? 'Backup saved successfully' : 'Backup failed',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Settings'),
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

                // Backup section
                Text(
                  'Backups',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: const Icon(Icons.backup_outlined),
                        title: const Text('Automatic Backups'),
                        subtitle: const Text('Save backups every 15 minutes'),
                        value: _autoBackupEnabled,
                        onChanged: _toggleAutoBackup,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.save_outlined),
                        title: const Text('Backup Now'),
                        subtitle: const Text('Create a manual backup'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _backupNow,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.folder_open_outlined),
                        title: const Text('Open Backup Folder'),
                        subtitle: Text(
                          _backupPath ?? 'Loading...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _openBackupFolder,
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
