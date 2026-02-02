import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/episode_manifest_model.dart';
import '../../domain/repositories/episode_repository.dart';
import '../providers/episode_providers.dart';
import 'download_progress_widget.dart';

class EpisodeCard extends ConsumerWidget {
  final EpisodeManifestModel episode;
  final VoidCallback? onTap;
  final VoidCallback? onMapTap;
  
  const EpisodeCard({
    super.key,
    required this.episode,
    this.onTap,
    this.onMapTap,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(episodeStatusProvider(episode));
    final downloadProgress = ref.watch(downloadProgressProvider)[episode.id];
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            if (episode.thumbnailUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  episode.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 48),
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          episode.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      statusAsync.when(
                        data: (status) => _buildStatusChip(status),
                        loading: () => const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${episode.localization.city}, ${episode.localization.country}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.map),
                        onPressed: onMapTap,
                        tooltip: 'View on map',
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Description
                  Text(
                    episode.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Metadata row
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _buildMetaChip(Icons.person, episode.author),
                      _buildMetaChip(Icons.storage, episode.formattedSize),
                      if (episode.difficulty != null)
                        _buildMetaChip(Icons.trending_up, episode.difficulty!),
                      if (episode.estimatedMinutes != null)
                        _buildMetaChip(Icons.timer, '${episode.estimatedMinutes} min'),
                    ],
                  ),
                  
                  // Tags
                  if (episode.tags?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: episode.tags!.map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ],
                  
                  // Download progress or action button
                  const SizedBox(height: 16),
                  
                  if (downloadProgress != null && downloadProgress.isActive)
                    DownloadProgressWidget(
                      episodeId: episode.id,
                      onCancel: () {
                        ref.read(downloadProgressProvider.notifier)
                            .cancelDownload(episode.id);
                      },
                    )
                  else
                    statusAsync.when(
                      data: (status) => _buildActionButton(context, ref, status),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatusChip(EpisodeInstallStatus status) {
    return switch (status) {
      EpisodeInstallStatus.notInstalled => const SizedBox.shrink(),
      EpisodeInstallStatus.installed => Chip(
          label: const Text('Installed'),
          backgroundColor: Colors.green[100],
          labelStyle: TextStyle(color: Colors.green[800], fontSize: 12),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      EpisodeInstallStatus.updateAvailable => Chip(
          label: const Text('Update Available'),
          backgroundColor: Colors.orange[100],
          labelStyle: TextStyle(color: Colors.orange[800], fontSize: 12),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
    };
  }
  
  Widget _buildMetaChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    EpisodeInstallStatus status,
  ) {
    return switch (status) {
      EpisodeInstallStatus.notInstalled => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: Text('Download (${episode.formattedSize})'),
            onPressed: () {
              ref.read(downloadProgressProvider.notifier).startDownload(episode);
            },
          ),
        ),
      EpisodeInstallStatus.installed => Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play'),
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showDeleteDialog(context, ref),
              color: Colors.red,
            ),
          ],
        ),
      EpisodeInstallStatus.updateAvailable => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.update),
            label: const Text('Update'),
            onPressed: () {
              ref.read(downloadProgressProvider.notifier).startDownload(episode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
    };
  }
  
  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Episode?'),
        content: Text('Are you sure you want to delete "${episode.name}"? '
            'You can download it again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(installedEpisodesProvider.notifier)
                  .deleteEpisode(episode.id);
              ref.invalidate(episodeStatusProvider(episode));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}