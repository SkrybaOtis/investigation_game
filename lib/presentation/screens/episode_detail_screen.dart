// ignore_for_file: unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/episode_manifest_model.dart';
import '../../domain/repositories/episode_repository.dart';
import '../providers/episode_providers.dart';
import '../widgets/download_progress_widget.dart';
import '../widgets/episode_map_marker.dart';
import 'game_screen.dart';

class EpisodeDetailScreen extends ConsumerWidget {
  final EpisodeManifestModel episode;
  
  const EpisodeDetailScreen({
    super.key,
    required this.episode,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(episodeStatusProvider(episode));
    final downloadProgress = ref.watch(downloadProgressProvider)[episode.id];
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                episode.name,
                style: const TextStyle(
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
              background: episode.thumbnailUrl != null
                  ? Image.network(
                      episode.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, size: 64, color: Colors.white54),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.search, size: 64, color: Colors.white54),
                    ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${episode.localization.city}, '
                          '${episode.localization.region ?? ''} '
                          '${episode.localization.country}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mini map
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 150,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: episode.mainPoint.latLng,
                          initialZoom: 13,
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          ),
                          MarkerLayer(
                            markers: EpisodeMapMarkerBuilder.buildPointMarkers(
                              points: episode.points,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Description
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(episode.description),
                  
                  const SizedBox(height: 24),
                  
                  // Metadata
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.person, 'Author', episode.author),
                  _buildDetailRow(Icons.storage, 'Size', episode.formattedSize),
                  _buildDetailRow(Icons.pin_drop, 'Locations', '${episode.points.length} points'),
                  if (episode.difficulty != null)
                    _buildDetailRow(Icons.trending_up, 'Difficulty', episode.difficulty!),
                  if (episode.estimatedMinutes != null)
                    _buildDetailRow(Icons.timer, 'Duration', '~${episode.estimatedMinutes} minutes'),
                  _buildDetailRow(Icons.calendar_today, 'Created',
                      '${episode.createdAt.day}/${episode.createdAt.month}/${episode.createdAt.year}'),
                  
                  // Tags
                  if (episode.tags?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: episode.tags!.map((tag) => Chip(
                        label: Text(tag),
                      )).toList(),
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Download progress or action
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
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Text('Error: $e'),
                    ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600]),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
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
            label: Text('Download Episode (${episode.formattedSize})'),
            onPressed: () {
              ref.read(downloadProgressProvider.notifier).startDownload(episode);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
      EpisodeInstallStatus.installed => Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play Episode'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(episodeId: episode.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete Episode', style: TextStyle(color: Colors.red)),
              onPressed: () => _showDeleteDialog(context, ref),
            ),
          ],
        ),
      EpisodeInstallStatus.updateAvailable => Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.update),
                label: const Text('Update Episode'),
                onPressed: () {
                  ref.read(downloadProgressProvider.notifier).startDownload(episode);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Play Current Version'),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameScreen(episodeId: episode.id),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    };
  }
  
  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Episode?'),
        content: Text('Are you sure you want to delete "${episode.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(installedEpisodesProvider.notifier).deleteEpisode(episode.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}