import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/storage_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/file_utils.dart';
import '../models/installed_episode_model.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

class StorageService {
  /// Loads installed episodes registry
  Future<InstalledEpisodesContainer> loadInstalledEpisodes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(StorageConstants.installedEpisodesKey);
    
    if (jsonString == null) {
      return InstalledEpisodesContainer(
        episodes: const [],
        lastUpdated: DateTime.now(),
      );
    }
    
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return InstalledEpisodesContainer.fromJson(json);
    } catch (e) {
      // Corrupted data - reset
      await prefs.remove(StorageConstants.installedEpisodesKey);
      return InstalledEpisodesContainer(
        episodes: const [],
        lastUpdated: DateTime.now(),
      );
    }
  }
  
  /// Saves installed episodes registry
  Future<void> saveInstalledEpisodes(InstalledEpisodesContainer container) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(container.toJson());
    await prefs.setString(StorageConstants.installedEpisodesKey, jsonString);
  }
  
  /// Adds or updates an installed episode record
  Future<void> recordInstalledEpisode(InstalledEpisodeModel episode) async {
    final container = await loadInstalledEpisodes();
    
    final updatedEpisodes = container.episodes
        .where((e) => e.episodeId != episode.episodeId)
        .toList()
      ..add(episode);
    
    await saveInstalledEpisodes(InstalledEpisodesContainer(
      episodes: updatedEpisodes,
      lastUpdated: DateTime.now(),
    ));
  }
  
  /// Removes an installed episode record and deletes files
  Future<void> removeInstalledEpisode(String episodeId) async {
    final container = await loadInstalledEpisodes();
    final episode = container.findById(episodeId);
    
    if (episode != null) {
      // Delete files
      await FileUtils.safeDelete(episode.localPath);
      
      // Also delete parent episode directory if empty
      final episodeDir = Directory(episode.localPath).parent;
      if (await episodeDir.exists()) {
        final contents = await episodeDir.list().toList();
        if (contents.isEmpty) {
          await episodeDir.delete();
        }
      }
      
    }
    
    // Update registry
    final updatedEpisodes = container.episodes
        .where((e) => e.episodeId != episodeId)
        .toList();
    
    await saveInstalledEpisodes(InstalledEpisodesContainer(
      episodes: updatedEpisodes,
      lastUpdated: DateTime.now(),
    ));
  }
  
  /// Loads episode story data from local storage
  Future<Map<String, dynamic>> loadEpisodeData(String episodeId) async {
    final container = await loadInstalledEpisodes();
    final episode = container.findById(episodeId);
    
    if (episode == null) {
      throw EpisodeNotFoundException(episodeId);
    }
    
    final storyFile = File(
      '${episode.localPath}/${StorageConstants.episodeDataFileName}'
    );
    
    if (!await storyFile.exists()) {
      throw StorageException('Episode data file not found');
    }
    
    final content = await storyFile.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }
  
  /// Gets image file for an episode
  File getEpisodeImage(String episodePath, String imageName) {
    return File('$episodePath/${StorageConstants.imagesFolderName}/$imageName');
  }
  
  /// Calculates total storage used by installed episodes
  Future<int> getTotalStorageUsed() async {
    final supportDir = await getApplicationSupportDirectory();
    final episodesDir = Directory(
      '${supportDir.path}/${StorageConstants.episodesFolderName}'
    );
    
    if (!await episodesDir.exists()) {
      return 0;
    }
    
    return await FileUtils.getDirectorySize(episodesDir.path);
  }
  
  /// Cleans up all temporary files
  Future<void> cleanupAllTempFiles() async {
    final tempDir = await getTemporaryDirectory();
    
    await for (final entity in tempDir.list()) {
      if (entity.path.contains('.zip') || entity.path.contains('.partial')) {
        await FileUtils.safeDelete(entity.path);
      }
    }
  }
}