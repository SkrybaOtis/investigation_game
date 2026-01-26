import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/download_progress_model.dart';
import '../providers/episode_providers.dart';

class DownloadProgressWidget extends ConsumerWidget {
  final String episodeId;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  
  const DownloadProgressWidget({
    super.key,
    required this.episodeId,
    this.onCancel,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressMap = ref.watch(downloadProgressProvider);
    final progress = progressMap[episodeId];
    
    if (progress == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getBackgroundColor(progress.phase),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildPhaseIcon(progress.phase),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  progress.phaseDescription,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _getTextColor(progress.phase),
                  ),
                ),
              ),
              if (progress.isActive && onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onCancel,
                  color: Colors.grey[600],
                ),
              if (progress.phase == DownloadPhase.failed && onRetry != null)
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  onPressed: onRetry,
                ),
            ],
          ),
          if (progress.phase == DownloadPhase.downloading) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatBytes(progress.bytesReceived)} / ${_formatBytes(progress.totalBytes)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
          if (progress.phase == DownloadPhase.verifying ||
              progress.phase == DownloadPhase.extracting ||
              progress.phase == DownloadPhase.installing) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildPhaseIcon(DownloadPhase phase) {
    return switch (phase) {
      DownloadPhase.idle => const Icon(Icons.hourglass_empty, color: Colors.grey),
      DownloadPhase.downloading => const Icon(Icons.download, color: Colors.blue),
      DownloadPhase.verifying => const Icon(Icons.security, color: Colors.orange),
      DownloadPhase.extracting => const Icon(Icons.unarchive, color: Colors.purple),
      DownloadPhase.installing => const Icon(Icons.install_mobile, color: Colors.teal),
      DownloadPhase.completed => const Icon(Icons.check_circle, color: Colors.green),
      DownloadPhase.failed => const Icon(Icons.error, color: Colors.red),
    };
  }
  
  Color _getBackgroundColor(DownloadPhase phase) {
    return switch (phase) {
      DownloadPhase.completed => Colors.green[50]!,
      DownloadPhase.failed => Colors.red[50]!,
      _ => Colors.blue[50]!,
    };
  }
  
  Color _getTextColor(DownloadPhase phase) {
    return switch (phase) {
      DownloadPhase.completed => Colors.green[800]!,
      DownloadPhase.failed => Colors.red[800]!,
      _ => Colors.blue[800]!,
    };
  }
  
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}