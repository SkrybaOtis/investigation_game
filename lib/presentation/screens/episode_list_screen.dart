import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/episode_providers.dart';
import '../widgets/episode_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/cleanup_downloads_button.dart';
import 'episode_detail_screen.dart';
import 'episode_map_screen.dart';

class EpisodeListScreen extends ConsumerStatefulWidget {
  const EpisodeListScreen({super.key});
  
  @override
  ConsumerState<EpisodeListScreen> createState() => _EpisodeListScreenState();
}

class _EpisodeListScreenState extends ConsumerState<EpisodeListScreen> {
  final _searchController = TextEditingController();
  bool _showInstalledOnly = false;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredEpisodes = ref.watch(filteredEpisodesProvider);
    final installedEpisodes = ref.watch(installedEpisodesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Investigation Episodes'),
        actions: [
          IconButton(
            icon: Icon(
              _showInstalledOnly ? Icons.download_done : Icons.download_done_outlined,
            ),
            onPressed: () {
              setState(() => _showInstalledOnly = !_showInstalledOnly);
            },
            tooltip: _showInstalledOnly ? 'Show all' : 'Show installed only',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by city, region, or country...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(citySearchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                ref.read(citySearchQueryProvider.notifier).state = value;
              },
            ),
          ),
          CleanupDownloadsButton(),
          
          // Episode list
          Expanded(
            child: filteredEpisodes.when(
              data: (episodes) {
                if (_showInstalledOnly) {
                  return installedEpisodes.when(
                    data: (installed) {
                      final installedIds = installed.map((e) => e.episodeId).toSet();
                      final filtered = episodes
                          .where((e) => installedIds.contains(e.id))
                          .toList();
                      
                      if (filtered.isEmpty) {
                        return _buildEmptyState(
                          icon: Icons.download_for_offline_outlined,
                          message: 'No episodes installed yet',
                          action: TextButton(
                            onPressed: () {
                              setState(() => _showInstalledOnly = false);
                            },
                            child: const Text('Browse Episodes'),
                          ),
                        );
                      }
                      
                      return _buildEpisodeList(filtered);
                    },
                    loading: () => const EpisodeListShimmer(),
                    error: (e, _) => _buildErrorState(e.toString()),
                  );
                }
                
                if (episodes.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.search_off,
                    message: 'No episodes found',
                    action: _searchController.text.isNotEmpty
                        ? TextButton(
                            onPressed: () {
                              _searchController.clear();
                              ref.read(citySearchQueryProvider.notifier).state = '';
                            },
                            child: const Text('Clear search'),
                          )
                        : null,
                  );
                }
                
                return _buildEpisodeList(episodes);
              },
              loading: () => const EpisodeListShimmer(),
              error: (error, _) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEpisodeList(List episodes) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(availableEpisodesProvider);
        ref.read(installedEpisodesProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return EpisodeCard(
            episode: episode,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EpisodeDetailScreen(episode: episode),
                ),
              );
            },
            onMapTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EpisodeMapScreen(
                    focusEpisode: episode,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action,
          ],
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Failed to load episodes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () {
                ref.invalidate(availableEpisodesProvider);
              },
            ),
          ],
        ),
      ),
    );
  }
}