import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../data/models/episode_manifest_model.dart';
import '../../data/models/episode_point_model.dart';

class EpisodeMapMarkerBuilder {
  static List<Marker> buildMarkers({
    required List<EpisodeManifestModel> episodes,
    String? selectedEpisodeId,
    required void Function(EpisodeManifestModel episode) onTap,
  }) {
    return episodes.map((episode) {
      final isSelected = episode.id == selectedEpisodeId;
      final point = episode.mainPoint;
      
      return Marker(
        point: point.latLng,
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        child: GestureDetector(
          onTap: () => onTap(episode),
          child: _EpisodeMarkerWidget(
            episode: episode,
            isSelected: isSelected,
          ),
        ),
      );
    }).toList();
  }
  
  static List<Marker> buildPointMarkers({
    required List<EpisodePointModel> points,
    Color color = Colors.blue,
    void Function(EpisodePointModel point)? onTap,
  }) {
    return points.map((point) {
      return Marker(
        point: point.latLng,
        width: point.isMainPoint ? 40 : 30,
        height: point.isMainPoint ? 40 : 30,
        child: GestureDetector(
          onTap: onTap != null ? () => onTap(point) : null,
          child: _PointMarkerWidget(
            point: point,
            color: color,
          ),
        ),
      );
    }).toList();
  }
}

class _EpisodeMarkerWidget extends StatelessWidget {
  final EpisodeManifestModel episode;
  final bool isSelected;
  
  const _EpisodeMarkerWidget({
    required this.episode,
    required this.isSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue : Colors.red,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.search,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

class _PointMarkerWidget extends StatelessWidget {
  final EpisodePointModel point;
  final Color color;
  
  const _PointMarkerWidget({
    required this.point,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: point.isMainPoint ? color : color.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          point.order?.toString() ?? (point.isMainPoint ? '★' : '•'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class EpisodeInfoPopup extends StatelessWidget {
  final EpisodeManifestModel episode;
  final VoidCallback? onViewDetails;
  final VoidCallback? onDownload;
  
  const EpisodeInfoPopup({
    super.key,
    required this.episode,
    this.onViewDetails,
    this.onDownload,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              episode.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${episode.localization.city}, ${episode.localization.country}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              episode.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onViewDetails != null)
                  TextButton(
                    onPressed: onViewDetails,
                    child: const Text('Details'),
                  ),
                if (onDownload != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download, size: 16),
                    label: Text(episode.formattedSize),
                    onPressed: onDownload,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}