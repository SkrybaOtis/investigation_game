import '../../data/models/download_progress_model.dart';
import '../../data/models/episode_manifest_model.dart';
import '../../data/models/installed_episode_model.dart';

abstract class EpisodeRepository {
  /// Fetches available episodes from server
  Future<List<EpisodeManifestModel>> getAvailableEpisodes();
  
  /// Fetches episodes filtered by city
  Future<List<EpisodeManifestModel>> getEpisodesByCity(String cityQuery);
  
  /// Gets locally installed episodes
  Future<List<InstalledEpisodeModel>> getInstalledEpisodes();
  
  /// Downloads and installs an episode
  Stream<DownloadProgressModel> downloadAndInstallEpisode(EpisodeManifestModel episode);
  
  /// Deletes an installed episode
  Future<void> deleteEpisode(String episodeId);
  
  /// Checks if episode is installed and up to date
  Future<EpisodeInstallStatus> getEpisodeStatus(EpisodeManifestModel episode);
  
  /// Loads episode game data
  Future<Map<String, dynamic>> loadEpisodeGameData(String episodeId);

  /// Cancels ongoing download
  void cancelDownload(String episodeId);

}

enum EpisodeInstallStatus {
  notInstalled,
  installed,
  updateAvailable,
}