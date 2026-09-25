import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/connectivity_provider.dart';

/// A widget that displays an offline indicator banner when disconnected
/// 
/// Place this at the top of your scaffold body or use as a persistent banner.
/// It automatically hides when online and shows when offline.
class OfflineIndicator extends ConsumerWidget {
  /// Whether to show a minimal indicator (just an icon) or full banner
  final bool minimal;
  
  const OfflineIndicator({
    super.key,
    this.minimal = false,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    
    // Don't show anything when online
    if (connectivity.isOnline) {
      return const SizedBox.shrink();
    }
    
    if (minimal) {
      return _buildMinimalIndicator(context);
    }
    
    return _buildFullBanner(context);
  }
  
  Widget _buildMinimalIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 4),
          Text(
            'Offline',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFullBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        border: Border(
          bottom: BorderSide(color: Colors.orange.shade300),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            size: 20,
            color: Colors.orange.shade800,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You\'re offline',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
                Text(
                  'Changes will sync when you\'re back online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A wrapper that shows an offline banner above its child
class OfflineBannerWrapper extends StatelessWidget {
  final Widget child;
  
  const OfflineBannerWrapper({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const OfflineIndicator(),
        Expanded(child: child),
      ],
    );
  }
}

/// A small offline indicator for the app bar
class OfflineAppBarIndicator extends ConsumerWidget {
  const OfflineAppBarIndicator({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    
    if (connectivity.isOnline) {
      return const SizedBox.shrink();
    }
    
    return Tooltip(
      message: 'Offline - changes saved locally',
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 16,
              color: Colors.orange,
            ),
            const SizedBox(width: 4),
            Text(
              'Offline',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
