import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/database_service.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/sync_provider.dart';
import '../../export/failsafe_backup_service.dart';
import '../../sync/presentation/conflict_resolution_screen.dart';

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

  Future<void> _showLogoutDialog(BuildContext dialogContext) async {
    final router = GoRouter.of(dialogContext);
    final result = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What would you like to do with your local data?'),
            SizedBox(height: 12),
            Text(
              'If you keep the data, it will be available when you sign back in.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'cancel'),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'clear'),
            child: const Text('Clear Data'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'keep'),
            child: const Text('Keep Data'),
          ),
        ],
      ),
    );

    if (result == 'cancel' || result == null) return;

    if (result == 'clear') {
      // Clear all local data (also reinitializes defaults)
      await DatabaseService.instance.clearAll();
    }

    // Logout
    await ref.read(authStateProvider.notifier).logout();
    
    // Navigate to login (router was captured before async gap)
    router.go('/login');
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
                _DataSyncCard(),
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
                  onPressed: () => _showLogoutDialog(context),
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

/// Card for sync status and controls
class _DataSyncCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final syncState = ref.watch(syncProvider);
    
    // Show different UI for offline mode
    if (authState.isOfflineMode) {
      return Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Sync'),
              subtitle: const Text('Sign in to sync across devices'),
              trailing: OutlinedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign In'),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('Export Data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigate to export screen
              },
            ),
          ],
        ),
      );
    }
    
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              syncState.isSyncing
                  ? Icons.sync
                  : syncState.hasError
                      ? Icons.sync_problem
                      : Icons.cloud_done_outlined,
              color: syncState.hasError
                  ? Theme.of(context).colorScheme.error
                  : null,
            ),
            title: Text(syncState.isSyncing ? 'Syncing...' : 'Sync'),
            subtitle: Text(
              syncState.hasError
                  ? 'Error: ${syncState.error}'
                  : syncState.hasPendingChanges
                      ? '${syncState.pendingChanges} changes pending • ${syncState.lastSyncText}'
                      : 'Last synced: ${syncState.lastSyncText}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: syncState.isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      // Capture context-dependent values before async operations
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final errorColor = Theme.of(context).colorScheme.error;
                      
                      final result = await ref
                          .read(syncProvider.notifier)
                          .performFullSync();
                      
                      if (context.mounted) {
                        if (result.success && result.hasConflicts) {
                          // Show conflict resolution dialog
                          final resolutions = await navigator.push<List<ResolvedConflict>>(
                            MaterialPageRoute(
                              builder: (context) => ConflictResolutionScreen(
                                conflicts: result.conflictItems,
                              ),
                            ),
                          );
                          
                          if (resolutions != null && context.mounted) {
                            await ref.read(syncProvider.notifier).applyConflictResolutions(resolutions);
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(content: Text('Conflicts resolved')),
                            );
                          }
                        } else {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                result.success
                                    ? 'Synced ${result.totalPulled} items'
                                    : 'Sync failed: ${result.error}',
                              ),
                              backgroundColor: result.success ? null : errorColor,
                            ),
                          );
                        }
                      }
                    },
                  ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export Data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to export screen
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Trash'),
            subtitle: const Text('View deleted items'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/trash'),
          ),
        ],
      ),
    );
  }
}
