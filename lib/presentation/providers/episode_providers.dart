import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

import '../../data/models/download_progress_model.dart';
import '../../data/models/episode_manifest_model.dart';
import '../../data/models/installed_episode_model.dart';
import '../../data/repositories/episode_repository_impl.dart';
import '../../domain/repositories/episode_repository.dart';




// ============================================================================
// Available Episodes Provider
// ============================================================================

final availableEpisodesProvider = FutureProvider<List<EpisodeManifestModel>>((ref) async {
  final repository = ref.watch(episodeRepositoryProvider);
  return await repository.getAvailableEpisodes();
});

final episodesByCityProvider = FutureProvider.family<List<EpisodeManifestModel>, String>(
  (ref, cityQuery) async {
    final repository = ref.watch(episodeRepositoryProvider);
    return await repository.getEpisodesByCity(cityQuery);
  },
);

// ============================================================================
// Installed Episodes Provider
// ============================================================================

final installedEpisodesProvider = StateNotifierProvider<InstalledEpisodesNotifier, AsyncValue<List<InstalledEpisodeModel>>>(
  (ref) => InstalledEpisodesNotifier(ref.watch(episodeRepositoryProvider)),
);


class InstalledEpisodesNotifier extends StateNotifier<AsyncValue<List<InstalledEpisodeModel>>> {
  final EpisodeRepository _repository;
  
  InstalledEpisodesNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadInstalled();
  }
  
  Future<void> _loadInstalled() async {
    try {
      final episodes = await _repository.getInstalledEpisodes();
      state = AsyncValue.data(episodes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadInstalled();
  }
  
  Future<void> deleteEpisode(String episodeId) async {
    await _repository.deleteEpisode(episodeId);
    await _loadInstalled();
  }
}

// ============================================================================
// Episode Status Provider
// ============================================================================

final episodeStatusProvider = FutureProvider.family<EpisodeInstallStatus, EpisodeManifestModel>(
  (ref, episode) async {
    final repository = ref.watch(episodeRepositoryProvider);
    return await repository.getEpisodeStatus(episode);
  },
);

// ============================================================================
// Download Progress Provider
// ============================================================================

final downloadProgressProvider = StateNotifierProvider<DownloadProgressNotifier, Map<String, DownloadProgressModel>>(
  (ref) => DownloadProgressNotifier(ref),
);

class DownloadProgressNotifier extends StateNotifier<Map<String, DownloadProgressModel>> {
  final Ref _ref;
  final Map<String, StreamSubscription<DownloadProgressModel>> _subscriptions = {};
  
  DownloadProgressNotifier(this._ref) : super({});
  
  void startDownload(EpisodeManifestModel episode) {
    if (state.containsKey(episode.id) && state[episode.id]!.isActive) {
      return; // Already downloading
    }
    
    final repository = _ref.read(episodeRepositoryProvider);
    final stream = repository.downloadAndInstallEpisode(episode);
    Logger logger = Logger();
    
    _subscriptions[episode.id] = stream.listen(
      (progress) {
        state = {...state, episode.id: progress};
      },
      onError: (e) {
        state = {
          ...state,
          episode.id: state[episode.id]!.copyWith(
            phase: DownloadPhase.failed,
            errorMessage: e.toString(),
          ),
        };
        _subscriptions[episode.id]?.cancel();
        _subscriptions.remove(episode.id);
        logger.w("Download failed !!!");
      },
      onDone: () {
        final finalProgress = state[episode.id];
        if (finalProgress?.phase == DownloadPhase.completed) {
          _ref.read(installedEpisodesProvider.notifier).refresh();
          _ref.invalidate(episodeStatusProvider(episode));
          logger.i("Download completed !!!");
        } else {
          logger.w("Download failed !!!");
        }
        _subscriptions[episode.id]?.cancel();
        _subscriptions.remove(episode.id);
      },
    );
  }
  
  void cancelDownload(String episodeId) {
    final repository = _ref.read(episodeRepositoryProvider);
    repository.cancelDownload(episodeId);
    _subscriptions[episodeId]?.cancel();
    _subscriptions.remove(episodeId);
    
    if (state.containsKey(episodeId)) {
      state = {
        ...state,
        episodeId: state[episodeId]!.copyWith(
          phase: DownloadPhase.failed,
          errorMessage: 'Cancelled by user',
        ),
      };
    }
  }
  
  void clearProgress(String episodeId) {
    final newState = Map<String, DownloadProgressModel>.from(state);
    newState.remove(episodeId);
    state = newState;
  }
  
  @override
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    super.dispose();
  }
}

// ============================================================================
// City Search Provider
// ============================================================================

final citySearchQueryProvider = StateProvider<String>((ref) => '');

final filteredEpisodesProvider = Provider<AsyncValue<List<EpisodeManifestModel>>>((ref) {
  final query = ref.watch(citySearchQueryProvider).toLowerCase().trim();
  final episodesAsync = ref.watch(availableEpisodesProvider);
  
  return episodesAsync.whenData((episodes) {
    if (query.isEmpty) return episodes;
    
    return episodes.where((episode) {
      final city = episode.localization.city.toLowerCase();
      final region = episode.localization.region?.toLowerCase() ?? '';
      final country = episode.localization.country.toLowerCase();
      
      return city.contains(query) ||
             region.contains(query) ||
             country.contains(query);
    }).toList();
  });
});

// ============================================================================
// Episodes Near Location Provider
// ============================================================================

final userLocationProvider = StateProvider<LatLng?>((ref) => null);

final episodesNearLocationProvider = Provider.family<List<EpisodeManifestModel>, double>(
  (ref, radiusKm) {
    final userLocation = ref.watch(userLocationProvider);
    final episodesAsync = ref.watch(availableEpisodesProvider);
    
    if (userLocation == null) return [];
    
    return episodesAsync.maybeWhen(
      data: (episodes) {
        const distance = Distance();
        
        return episodes.where((episode) {
          final episodeLocation = episode.localization.center;
          final km = distance.as(
            LengthUnit.Kilometer,
            userLocation,
            episodeLocation,
          );
          return km <= radiusKm;
        }).toList()
          ..sort((a, b) {
            final distA = distance.as(LengthUnit.Kilometer, userLocation, a.localization.center);
            final distB = distance.as(LengthUnit.Kilometer, userLocation, b.localization.center);
            return distA.compareTo(distB);
          });
      },
      orElse: () => [],
    );
  },
);