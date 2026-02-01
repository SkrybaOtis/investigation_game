import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/storage_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/file_utils.dart';

final extractionServiceProvider = Provider<ExtractionService>((ref) {
  return ExtractionService();
});

class ExtractionService {
  /// Extracts ZIP to staging directory, validates, then commits to final location
  Future<String> extractAndInstall({
    required String zipPath,
    required String episodeId,
    required int version,
  }) async {
    final supportDir = await getApplicationSupportDirectory();
    final episodesDir = '${supportDir.path}/${StorageConstants.episodesFolderName}';
    final stagingPath = '$episodesDir/$episodeId/${StorageConstants.stagingFolderSuffix}_v$version';
    final finalPath = '$episodesDir/$episodeId/v$version';
    
    try {
      // Clean up any existing staging directory
      await FileUtils.safeDelete(stagingPath);
      
      // Create staging directory
      await Directory(stagingPath).create(recursive: true);
      
      // Extract to staging using archive package.
      // InputFileStream reads directly from disk without loading the entire zip into memory.
      final inputStream = InputFileStream(zipPath);
      final archive = ZipDecoder().decodeStream(inputStream);
      extractArchiveToDisk(archive, stagingPath);
      inputStream.closeSync();
      
      // Validate extraction
      final isValid = await FileUtils.validateEpisodeStructure(stagingPath);
      
      if (!isValid) {
        await FileUtils.safeDelete(stagingPath);
        throw const ExtractionException('Extracted content validation failed');
      }
      
      // Atomic commit: remove old version if exists, then rename staging to final
      await FileUtils.safeDelete(finalPath);
      await FileUtils.safeMove(stagingPath, finalPath);
      
      return finalPath;
    } catch (e) {
      // Cleanup on failure
      await FileUtils.safeDelete(stagingPath);
      
      if (e is ExtractionException) rethrow;
      throw ExtractionException('Failed to extract episode: $e', e);
    }
  }
  
  /// Lists all installed episode versions
  Future<List<String>> getInstalledVersionPaths(String episodeId) async {
    final supportDir = await getApplicationSupportDirectory();
    final episodeDir = Directory(
      '${supportDir.path}/${StorageConstants.episodesFolderName}/$episodeId'
    );
    
    if (!await episodeDir.exists()) {
      return [];
    }
    
    final versions = <String>[];
    
    await for (final entity in episodeDir.list()) {
      if (entity is Directory && entity.path.contains('/v')) {
        versions.add(entity.path);
      }
    }
    
    return versions;
  }
}