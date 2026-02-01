import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/storage_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../infrastructure/network/dio_client.dart';
import '../models/download_progress_model.dart';
import '../models/episode_manifest_model.dart';
import '../models/cleanup_result_model.dart';

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(ref.watch(dioClientProvider));
});

class DownloadService {
  final DioClient _dioClient;
  final Map<String, CancelToken> _activeCancelTokens = {};
  
  DownloadService(this._dioClient);
  
  /// Downloads episode ZIP with progress tracking and resume support
  Stream<DownloadProgressModel> downloadEpisode(EpisodeManifestModel episode) {
    final controller = StreamController<DownloadProgressModel>();
    
    // Run download in background and pipe events to controller
    _performDownload(episode, controller);
    
    return controller.stream;
  }
  
  Future<void> _performDownload(
    EpisodeManifestModel episode,
    StreamController<DownloadProgressModel> controller,
  ) async {
    
    final tempDir = await getTemporaryDirectory();
    final partialPath = '${tempDir.path}/${episode.id}_v${episode.version}.zip${StorageConstants.partialFileSuffix}';
    final completedPath = '${tempDir.path}/${episode.id}_v${episode.version}.zip';
    
    final cancelToken = CancelToken();
    _activeCancelTokens[episode.id] = cancelToken;
    
    var progress = DownloadProgressModel.initial(episode.id, episode.sizeBytes);
    
    try {
      controller.add(progress.copyWith(phase: DownloadPhase.downloading));
      
      // Check for existing partial download
      final partialFile = File(partialPath);
      int existingBytes = 0;
      bool shouldResume = false;
      
      if (await partialFile.exists()) {
        existingBytes = await partialFile.length();
        
        // Only resume if partial file is SMALLER than expected total
        if (existingBytes > 0 && existingBytes < episode.sizeBytes) {
          shouldResume = true;
          progress = progress.copyWith(
            bytesReceived: existingBytes,
            progress: existingBytes / episode.sizeBytes,
          );
          controller.add(progress);
        } else {
          // File is complete or corrupted - delete and start fresh
          await partialFile.delete();
          existingBytes = 0;
        }
      }
      
      // Attempt download with optional resume
      final progressRef = _ProgressRef(progress);
      await _attemptDownload(
        episode: episode,
        partialPath: partialPath,
        cancelToken: cancelToken,
        existingBytes: existingBytes,
        shouldResume: shouldResume,
        controller: controller,
        progressRef: progressRef,
      );
      
      // Read back the actual final progress from the ref
      progress = progressRef.progress;
      
      // Rename partial to completed
      final completedPartialFile = File(partialPath);
      if (await completedPartialFile.exists()) {
        await completedPartialFile.rename(completedPath);
      }
      
      controller.add(progress.copyWith(
        phase: DownloadPhase.completed,
        progress: 1.0,
      ));
      
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        controller.add(progress.copyWith(
          phase: DownloadPhase.failed,
          errorMessage: 'Download cancelled',
        ));
      } else {
        controller.addError(DownloadException(
          'Failed to download episode',
          episode.id,
          e,
        ));
      }
    } catch (e) {
      controller.addError(DownloadException(
        'Failed to download episode',
        episode.id,
        e,
      ));
    } finally {
      _activeCancelTokens.remove(episode.id);
      await controller.close();
    }
  }
  
  Future<void> _attemptDownload({
    required EpisodeManifestModel episode,
    required String partialPath,
    required CancelToken cancelToken,
    required int existingBytes,
    required bool shouldResume,
    required StreamController<DownloadProgressModel> controller,
    required _ProgressRef progressRef,
  }) async {
    try {
      
      await _dioClient.download(
        episode.downloadUrl,
        partialPath,
        resumeDownload: shouldResume,
        existingBytes: existingBytes,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final totalReceived = existingBytes + received;
          final adjustedTotal = total > 0 
              ? (existingBytes + total) 
              : episode.sizeBytes;
          
          progressRef.progress = progressRef.progress.copyWith(
            bytesReceived: totalReceived,
            progress: totalReceived / adjustedTotal,
          );
          controller.add(progressRef.progress);
        },
      );
    } on NetworkException catch (e) {
      if (e.statusCode == 416) {
        // Delete the problematic partial file
        final file = File(partialPath);
        if (await file.exists()) {
          await file.delete();
        }
        
        // Reset and retry without resume
        progressRef.progress = DownloadProgressModel.initial(
          episode.id, 
          episode.sizeBytes,
        ).copyWith(phase: DownloadPhase.downloading);
        controller.add(progressRef.progress);
        
        // Retry download from scratch
        await _dioClient.download(
          episode.downloadUrl,
          partialPath,
          resumeDownload: false,
          cancelToken: cancelToken,
          onReceiveProgress: (received, total) {
            final adjustedTotal = total > 0 ? total : episode.sizeBytes;
            
            progressRef.progress = progressRef.progress.copyWith(
              bytesReceived: received,
              progress: received / adjustedTotal,
            );
            controller.add(progressRef.progress);
          },
        );
      } else {
        rethrow;
      }
    }
  }
  
  /// Cancels an ongoing download
  void cancelDownload(String episodeId) {
    _activeCancelTokens[episodeId]?.cancel('User cancelled');
    _activeCancelTokens.remove(episodeId);
  }
  
  /// Gets the path where the downloaded ZIP would be stored
  Future<String> getDownloadedZipPath(String episodeId, int version) async {
    final tempDir = await getTemporaryDirectory();
    return '${tempDir.path}/${episodeId}_v$version.zip';
  }
  
  /// Cleans up temporary download files
  Future<void> cleanupTempFiles(String episodeId) async {
    final tempDir = await getTemporaryDirectory();
    
    await for (final entity in tempDir.list()) {
      if (entity.path.contains(episodeId)) {
        await entity.delete(recursive: true);
      }
    }
  }

  /// Cleans up ALL partial download files from temp directory
  Future<CleanupResult> cleanupAllPartialDownloads() async {
    int deletedCount = 0;
    int freedBytes = 0;
    
    try {
      final tempDir = await getTemporaryDirectory();
      
      await for (final entity in tempDir.list()) {
        final path = entity.path;
        
        // Check for partial files and episode zip files
        if (path.endsWith(StorageConstants.partialFileSuffix) ||
            (path.endsWith('.zip') && path.contains('_v'))) {
          try {
            final stat = await entity.stat();
            freedBytes += stat.size;
            await entity.delete(recursive: true);
            deletedCount++;
          } catch (e) {
            // Skip files that can't be deleted
            continue;
          }
        }
      }
      
      return CleanupResult(
        success: true,
        deletedCount: deletedCount,
        freedBytes: freedBytes,
      );
    } catch (e) {
      return CleanupResult(
        success: false,
        deletedCount: deletedCount,
        freedBytes: freedBytes,
        errorMessage: e.toString(),
      );
    }
  }

}




/// Helper class to pass progress by reference in callbacks
class _ProgressRef {
  DownloadProgressModel progress;
  _ProgressRef(this.progress);
}