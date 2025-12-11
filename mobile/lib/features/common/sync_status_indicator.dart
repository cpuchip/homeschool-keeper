import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sync_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../sync/presentation/conflict_resolution_screen.dart';

/// A widget that displays the sync status with last sync time.
/// 
/// Shows:
/// - Spinning sync icon when syncing
/// - Cloud check icon when synced
/// - Cloud off icon when offline
/// - Error icon when sync failed
/// - Tap to trigger manual sync
class SyncStatusIndicator extends ConsumerWidget {
  /// Whether to show extended info (last sync time)
  final bool showLastSyncTime;
  
  /// Whether tapping triggers a sync
  final bool tapToSync;

  const SyncStatusIndicator({
    super.key,
    this.showLastSyncTime = true,
    this.tapToSync = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final connectivity = ref.watch(connectivityProvider);
    final theme = Theme.of(context);

    return InkWell(
      onTap: tapToSync && connectivity.isOnline && !syncState.isSyncing
          ? () => _triggerSync(ref)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(syncState, connectivity, theme),
            if (showLastSyncTime) ...[
              const SizedBox(width: 8),
              _buildStatusText(syncState, connectivity, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(SyncState syncState, ConnectivityState connectivity, ThemeData theme) {
    // Offline
    if (!connectivity.isOnline) {
      return Icon(
        Icons.cloud_off_outlined,
        size: 20,
        color: Colors.orange.shade700,
      );
    }

    // Syncing - animated
    if (syncState.isSyncing) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      );
    }

    // Error
    if (syncState.hasError) {
      return Icon(
        Icons.cloud_off,
        size: 20,
        color: theme.colorScheme.error,
      );
    }

    // Has pending changes
    if (syncState.hasPendingChanges) {
      return Badge(
        label: Text(
          '${syncState.pendingChanges}',
          style: const TextStyle(fontSize: 10),
        ),
        child: Icon(
          Icons.cloud_upload_outlined,
          size: 20,
          color: theme.colorScheme.primary,
        ),
      );
    }

    // Synced / idle
    return Icon(
      Icons.cloud_done_outlined,
      size: 20,
      color: Colors.green.shade600,
    );
  }

  Widget _buildStatusText(SyncState syncState, ConnectivityState connectivity, ThemeData theme) {
    String text;
    Color color;

    if (!connectivity.isOnline) {
      text = 'Offline';
      color = Colors.orange.shade700;
    } else if (syncState.isSyncing) {
      text = 'Syncing...';
      color = theme.colorScheme.primary;
    } else if (syncState.hasError) {
      text = 'Sync failed';
      color = theme.colorScheme.error;
    } else if (syncState.lastSyncText != null) {
      text = syncState.lastSyncText!;
      color = theme.colorScheme.onSurfaceVariant;
    } else {
      text = 'Never synced';
      color = theme.colorScheme.onSurfaceVariant;
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Future<void> _triggerSync(WidgetRef ref) async {
    final syncNotifier = ref.read(syncProvider.notifier);
    await syncNotifier.performFullSync();
  }
}

/// A compact sync button for app bars
class SyncButton extends ConsumerWidget {
  const SyncButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final connectivity = ref.watch(connectivityProvider);
    final theme = Theme.of(context);

    return IconButton(
      onPressed: connectivity.isOnline && !syncState.isSyncing
          ? () => _triggerSync(ref, context)
          : null,
      tooltip: _getTooltip(syncState, connectivity),
      icon: _buildIcon(syncState, connectivity, theme),
    );
  }

  Widget _buildIcon(SyncState syncState, ConnectivityState connectivity, ThemeData theme) {
    if (!connectivity.isOnline) {
      return Icon(
        Icons.cloud_off_outlined,
        color: Colors.orange.shade700,
      );
    }

    if (syncState.isSyncing) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      );
    }

    if (syncState.hasError) {
      return Icon(
        Icons.sync_problem,
        color: theme.colorScheme.error,
      );
    }

    if (syncState.hasPendingChanges) {
      return Badge(
        label: Text(
          '${syncState.pendingChanges}',
          style: const TextStyle(fontSize: 10),
        ),
        child: const Icon(Icons.sync),
      );
    }

    return Icon(
      Icons.cloud_done_outlined,
      color: Colors.green.shade600,
    );
  }

  String _getTooltip(SyncState syncState, ConnectivityState connectivity) {
    if (!connectivity.isOnline) return 'Offline - sync unavailable';
    if (syncState.isSyncing) return 'Syncing...';
    if (syncState.hasError) return 'Sync failed - tap to retry';
    if (syncState.hasPendingChanges) {
      return '${syncState.pendingChanges} changes pending - tap to sync';
    }
    return syncState.lastSyncText ?? 'Tap to sync';
  }

  Future<void> _triggerSync(WidgetRef ref, BuildContext context) async {
    final syncNotifier = ref.read(syncProvider.notifier);
    final result = await syncNotifier.performFullSync();
    
    if (context.mounted) {
      if (result.success) {
        // Check for conflicts and show resolution dialog
        if (result.hasConflicts) {
          final resolutions = await Navigator.of(context).push<List<ResolvedConflict>>(
            MaterialPageRoute(
              builder: (context) => ConflictResolutionScreen(
                conflicts: result.conflictItems,
              ),
            ),
          );
          
          // Apply resolutions if user didn't cancel
          if (resolutions != null && context.mounted) {
            final resolved = await syncNotifier.applyConflictResolutions(resolutions);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Resolved $resolved conflict${resolved == 1 ? '' : 's'}'),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // No conflicts - show simple success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Synced: ${result.totalPushed} pushed, ${result.totalPulled} pulled'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${result.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
