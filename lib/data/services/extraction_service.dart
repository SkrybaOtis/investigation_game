import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investigation_game/infrastructure/network/dio_client.dart';
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
      logger.t(
        'zipPath: $zipPath, \n' 
        'episodeId: $episodeId, \n'
        'version: $version, \n'
        'supportDir: $supportDir, \n'
        'episodeDir: $episodesDir, \n'
        'stagingPath: $stagingPath, \n'
        'finalPath $finalPath, \n'
      );
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
      
      // // Validate extraction
      // final isValid = await FileUtils.validateEpisodeStructure(stagingPath);
      
      // if (!isValid) {
      //   await FileUtils.safeDelete(stagingPath); // !!!
      //   throw const ExtractionException('Extracted content validation failed');
      // }
            
      // DEBUG: Log extracted contents
      await _logDirectoryContents(stagingPath, 'After extraction');
      
      // Handle nested folder structure
      final actualContentPath = await _resolveContentPath(stagingPath);
      
      // Validate extraction
      final isValid = await FileUtils.validateEpisodeStructure(actualContentPath);
      
      if (!isValid) {
        await FileUtils.safeDelete(stagingPath);
        // Include more details in the exception
        final contents = await _getDirectoryContents(actualContentPath);
        throw ExtractionException(
          'Extracted content validation failed. Contents: $contents',
        );
      }
      
      // If content was nested, move it up
      if (actualContentPath != stagingPath) {
        await _flattenNestedContent(actualContentPath, stagingPath);
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


  /// Checks if extraction created a single wrapper folder and returns actual content path
  Future<String> _resolveContentPath(String stagingPath) async {
    final stagingDir = Directory(stagingPath);
    final entities = await stagingDir.list().toList();
    
    // Filter out hidden files (like .DS_Store, __MACOSX)
    final visibleEntities = entities.where((e) {
      final name = e.path.split('/').last;
      return !name.startsWith('.') && name != '__MACOSX';
    }).toList();
    
    // If exactly one directory and no files, content is likely nested
    if (visibleEntities.length == 1 && visibleEntities.first is Directory) {
      final nestedDir = visibleEntities.first as Directory;
      
      // Verify the nested directory contains expected structure
      final hasExpectedFiles = await FileUtils.validateEpisodeStructure(nestedDir.path);
      if (hasExpectedFiles) {
        return nestedDir.path;
      }
    }
    
    return stagingPath;
  }
  
  /// Moves contents from nested folder up to staging root
  Future<void> _flattenNestedContent(String nestedPath, String stagingPath) async {
    final tempPath = '$stagingPath\_temp_flatten';
    
    // Move nested content to temp location
    await FileUtils.safeMove(nestedPath, tempPath);
    
    // Clear staging (removes empty nested folder)
    await for (final entity in Directory(stagingPath).list()) {
      if (entity.path != tempPath) {
        await FileUtils.safeDelete(entity.path);
      }
    }
    
    // Move contents from temp to staging root
    await for (final entity in Directory(tempPath).list()) {
      final name = entity.path.split('/').last;
      final newPath = '$stagingPath/$name';
      if (entity is File) {
        await entity.rename(newPath);
      } else if (entity is Directory) {
        await FileUtils.safeMove(entity.path, newPath);
      }
    }
    
    await FileUtils.safeDelete(tempPath);
  }
  
  /// Debug helper: logs directory contents
  Future<void> _logDirectoryContents(String path, String label) async {
    logger.i('=== $label: $path ===');
    final contents = await _getDirectoryContents(path);
    for (final item in contents) {
      logger.i('  $item');
    }
    logger.i('=== End $label ===');
  }
  
  Future<List<String>> _getDirectoryContents(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return ['<directory does not exist>'];
    }
    
    final contents = <String>[];
    await for (final entity in dir.list(recursive: true)) {
      final relativePath = entity.path.replaceFirst('$path/', '');
      final type = entity is Directory ? '[DIR]' : '[FILE]';
      contents.add('$type $relativePath');
    }
    return contents..sort();
  }


}