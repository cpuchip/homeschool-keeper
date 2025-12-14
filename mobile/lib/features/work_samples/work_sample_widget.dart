import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/work_sample.dart';
import 'work_sample_service.dart';

/// Widget for displaying and managing work samples attached to a log entry.
class WorkSampleAttachments extends ConsumerStatefulWidget {
  final String logEntryId;
  final String? groupId;
  final String studentId;
  final String familyId;
  final String uploadedBy;
  final bool readOnly;

  const WorkSampleAttachments({
    super.key,
    required this.logEntryId,
    this.groupId,
    required this.studentId,
    required this.familyId,
    required this.uploadedBy,
    this.readOnly = false,
  });

  @override
  ConsumerState<WorkSampleAttachments> createState() =>
      _WorkSampleAttachmentsState();
}

class _WorkSampleAttachmentsState extends ConsumerState<WorkSampleAttachments> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<WorkSample> _samples = [];

  @override
  void initState() {
    super.initState();
    _loadSamples();
  }

  Future<void> _loadSamples() async {
    final repository = ref.read(workSampleRepositoryProvider);
    setState(() {
      _samples = repository.getByLogEntry(
        widget.logEntryId,
        groupId: widget.groupId,
      );
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (image != null) {
      await _addFile(File(image.path), 'image/jpeg');
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
    if (image != null) {
      await _addFile(File(image.path), 'image/jpeg');
    }
  }

  Future<void> _addFile(File file, String contentType) async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(workSampleRepositoryProvider);
      await repository.saveLocally(
        logEntryId: widget.logEntryId,
        groupId: widget.groupId,
        studentId: widget.studentId,
        file: file,
        contentType: contentType,
        uploadedBy: widget.uploadedBy,
        familyId: widget.familyId,
      );
      await _loadSamples();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteSample(WorkSample sample) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete "${sample.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repository = ref.read(workSampleRepositoryProvider);
        await repository.delete(sample.id);
        await _loadSamples();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleTile(WorkSample sample) {
    return Card(
      margin: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _openSample(sample),
        onLongPress: widget.readOnly ? null : () => _deleteSample(sample),
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForContentType(sample.contentType),
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 4),
              Text(
                sample.fileName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 2),
              _buildSyncBadge(sample),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSyncBadge(WorkSample sample) {
    IconData icon;
    Color color;
    String tooltip;

    switch (sample.syncStatus) {
      case SyncStatus.local:
        icon = Icons.phone_android;
        color = Colors.grey;
        tooltip = 'Stored locally';
      case SyncStatus.syncing:
        icon = Icons.cloud_upload;
        color = Colors.orange;
        tooltip = 'Uploading...';
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = 'Synced';
      case SyncStatus.error:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = 'Sync failed';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, size: 16, color: color),
    );
  }

  IconData _getIconForContentType(String contentType) {
    if (contentType.startsWith('image/')) {
      return Icons.image;
    } else if (contentType == 'application/pdf') {
      return Icons.picture_as_pdf;
    } else if (contentType.startsWith('video/')) {
      return Icons.videocam;
    }
    return Icons.attach_file;
  }

  Future<void> _openSample(WorkSample sample) async {
    if (sample.localPath != null) {
      final file = File(sample.localPath!);
      if (await file.exists()) {
        // Show image in a dialog
        if (sample.contentType.startsWith('image/') && mounted) {
          showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppBar(
                    title: Text(sample.fileName),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Flexible(
                    child: Image.file(file),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attachments',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (!widget.readOnly)
              TextButton.icon(
                onPressed: _isLoading ? null : _showAttachMenu,
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        if (_isLoading)
          const LinearProgressIndicator()
        else if (_samples.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No attachments yet',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _samples.length,
              itemBuilder: (context, index) => _buildSampleTile(_samples[index]),
            ),
          ),
      ],
    );
  }
}
