import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/sync/conflict_item.dart';

/// A Windows Explorer-style conflict resolution screen that shows
/// field-by-field comparison between local and server versions.
class ConflictResolutionScreen extends StatefulWidget {
  final List<ConflictItem> conflicts;

  const ConflictResolutionScreen({
    super.key,
    required this.conflicts,
  });

  @override
  State<ConflictResolutionScreen> createState() =>
      _ConflictResolutionScreenState();
}

class _ConflictResolutionScreenState extends State<ConflictResolutionScreen> {
  late Map<String, ConflictResolution> resolutions;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    resolutions = {};
  }

  ConflictItem get currentConflict => widget.conflicts[currentIndex];

  bool get hasUnresolvedConflicts =>
      widget.conflicts.any((c) => !resolutions.containsKey(c.entityId));

  void _setResolution(ConflictResolution resolution) {
    setState(() {
      resolutions[currentConflict.entityId] = resolution;
    });
  }

  void _nextConflict() {
    if (currentIndex < widget.conflicts.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  void _previousConflict() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  void _applyAll(ConflictResolution resolution) {
    setState(() {
      for (final conflict in widget.conflicts) {
        resolutions[conflict.entityId] = resolution;
      }
    });
  }

  void _finish() {
    final result = widget.conflicts.map((conflict) {
      return ResolvedConflict(
        conflict: conflict,
        resolution: resolutions[conflict.entityId] ?? ConflictResolution.skip,
      );
    }).toList();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conflict = currentConflict;
    final resolution = resolutions[conflict.entityId];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolve Sync Conflicts'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.conflicts.length} conflict${widget.conflicts.length == 1 ? '' : 's'} found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${currentIndex + 1} / ${widget.conflicts.length}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (resolutions.length) / widget.conflicts.length,
                  backgroundColor: theme.colorScheme.surfaceContainerLow,
                ),
              ],
            ),
          ),

          // Conflict details
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Entity info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildEntityIcon(conflict.entityType),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      conflict.displayName,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      conflict.entityTypeName,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comparison header
                  Row(
                    children: [
                      Expanded(
                        child: _buildVersionHeader(
                          'Your Version',
                          conflict.localUpdatedAt,
                          Icons.phone_android,
                          theme.colorScheme.primary,
                          theme,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildVersionHeader(
                          'Server Version',
                          conflict.serverUpdatedAt,
                          Icons.cloud,
                          theme.colorScheme.secondary,
                          theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Field diffs
                  ...conflict.fieldDiffs.map(
                    (diff) => _buildFieldComparison(
                      diff,
                      theme,
                    ),
                  ),

                  if (conflict.fieldDiffs.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Both versions have the same values, but were modified at different times.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Resolution buttons
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Resolution choice indicator
                if (resolution != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getResolutionLabel(resolution),
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Main action buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.phone_android,
                        label: 'Keep Local',
                        color: theme.colorScheme.primary,
                        isSelected: resolution == ConflictResolution.keepLocal,
                        onPressed: () =>
                            _setResolution(ConflictResolution.keepLocal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.cloud,
                        label: 'Keep Server',
                        color: theme.colorScheme.secondary,
                        isSelected: resolution == ConflictResolution.keepServer,
                        onPressed: () =>
                            _setResolution(ConflictResolution.keepServer),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.skip_next,
                        label: 'Skip',
                        color: theme.colorScheme.outline,
                        isSelected: resolution == ConflictResolution.skip,
                        onPressed: () =>
                            _setResolution(ConflictResolution.skip),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Navigation and bulk actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton.outlined(
                          icon: const Icon(Icons.chevron_left),
                          onPressed:
                              currentIndex > 0 ? _previousConflict : null,
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: currentIndex < widget.conflicts.length - 1
                              ? _nextConflict
                              : null,
                        ),
                      ],
                    ),
                    PopupMenuButton<ConflictResolution>(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Apply to all',
                      onSelected: _applyAll,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: ConflictResolution.keepLocal,
                          child: Row(
                            children: [
                              Icon(Icons.phone_android, size: 20),
                              SizedBox(width: 12),
                              Text('Keep All Local'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: ConflictResolution.keepServer,
                          child: Row(
                            children: [
                              Icon(Icons.cloud, size: 20),
                              SizedBox(width: 12),
                              Text('Keep All Server'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: ConflictResolution.skip,
                          child: Row(
                            children: [
                              Icon(Icons.skip_next, size: 20),
                              SizedBox(width: 12),
                              Text('Skip All'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: hasUnresolvedConflicts ? null : _finish,
                      icon: const Icon(Icons.check),
                      label: Text(
                        hasUnresolvedConflicts
                            ? 'Resolve All (${resolutions.length}/${widget.conflicts.length})'
                            : 'Apply Changes',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntityIcon(ConflictEntityType type) {
    IconData icon;
    Color color;
    switch (type) {
      case ConflictEntityType.student:
        icon = Icons.person;
        color = Colors.blue;
        break;
      case ConflictEntityType.subject:
        icon = Icons.subject;
        color = Colors.green;
        break;
      case ConflictEntityType.log:
        icon = Icons.schedule;
        color = Colors.orange;
        break;
    }
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.2),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildVersionHeader(
    String title,
    DateTime updatedAt,
    IconData icon,
    Color color,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy h:mm a').format(updatedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldComparison(FieldDiff diff, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              diff.displayName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildValueCell(
                    diff.localValue,
                    theme.colorScheme.primary,
                    theme,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: theme.colorScheme.outline,
                  ),
                ),
                Expanded(
                  child: _buildValueCell(
                    diff.serverValue,
                    theme.colorScheme.secondary,
                    theme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueCell(dynamic value, Color accentColor, ThemeData theme) {
    String displayValue;
    if (value == null) {
      displayValue = '(empty)';
    } else if (value is bool) {
      displayValue = value ? 'Yes' : 'No';
    } else {
      displayValue = value.toString();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Text(
        displayValue,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: value == null
              ? theme.colorScheme.outline
              : theme.colorScheme.onSurface,
          fontStyle: value == null ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  String _getResolutionLabel(ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return 'Keeping your local version';
      case ConflictResolution.keepServer:
        return 'Keeping server version';
      case ConflictResolution.keepBoth:
        return 'Keeping both versions';
      case ConflictResolution.skip:
        return 'Skipping this conflict';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return isSelected
        ? FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: color,
            ),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, color: color),
            label: Text(label, style: TextStyle(color: color)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color),
            ),
          );
  }
}
