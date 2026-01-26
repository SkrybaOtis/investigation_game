import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/episode_manifest_model.dart';
import '../providers/episode_providers.dart';
import '../providers/map_providers.dart';
import '../widgets/episode_map_marker.dart';
import 'episode_detail_screen.dart';

class EpisodeMapScreen extends ConsumerStatefulWidget {
  final EpisodeManifestModel? focusEpisode;
  
  const EpisodeMapScreen({
    super.key,
    this.focusEpisode,
  });
  
  @override
  ConsumerState<EpisodeMapScreen> createState() => _EpisodeMapScreenState();
}

class _EpisodeMapScreenState extends ConsumerState<EpisodeMapScreen> {
  final MapController _mapController = MapController();
  EpisodeManifestModel? _selectedEpisode;
  
  @override
  void initState() {
    super.initState();
    _selectedEpisode = widget.focusEpisode;
    
    if (widget.focusEpisode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          widget.focusEpisode!.mainPoint.latLng,
          12.0,
        );
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final episodesAsync = ref.watch(availableEpisodesProvider);
    final currentLocation = ref.watch(currentLocationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Episode Map'),
        actions: [
          currentLocation.when(
            data: (location) => location != null
                ? IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: () {
                      _mapController.move(location, 10.0);
                    },
                  )
                : const SizedBox.shrink(),
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.focusEpisode?.mainPoint.latLng ??
                  const LatLng(50.0, 10.0),
              initialZoom: widget.focusEpisode != null ? 12.0 : 5.0,
              onTap: (_, __) {
                setState(() => _selectedEpisode = null);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.investigation_game',
              ),
              
              // Episode markers
              episodesAsync.when(
                data: (episodes) => MarkerLayer(
                  markers: EpisodeMapMarkerBuilder.buildMarkers(
                    episodes: episodes,
                    selectedEpisodeId: _selectedEpisode?.id,
                    onTap: (episode) {
                      setState(() => _selectedEpisode = episode);
                      _mapController.move(episode.mainPoint.latLng, 12.0);
                    },
                  ),
                ),
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
              
              // Current location marker
              currentLocation.when(
                data: (location) => location != null
                    ? MarkerLayer(
                        markers: [
                          Marker(
                            point: location,
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const MarkerLayer(markers: []),
                loading: () => const MarkerLayer(markers: []),
                error: (_, __) => const MarkerLayer(markers: []),
              ),
            ],
          ),
          
          // Selected episode popup
          if (_selectedEpisode != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: EpisodeInfoPopup(
                episode: _selectedEpisode!,
                onViewDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EpisodeDetailScreen(
                        episode: _selectedEpisode!,
                      ),
                    ),
                  );
                },
                onDownload: () {
                  ref.read(downloadProgressProvider.notifier)
                      .startDownload(_selectedEpisode!);
                },
              ),
            ),
        ],
      ),
    );
  }
}