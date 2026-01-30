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

final downloadServiceProvider = Provider<DownloadService>((ref) {
  return DownloadService(ref.watch(dioClientProvider));
});

class DownloadService {
  final DioClient _dioClient;
  final Map<String, CancelToken> _activeCancelTokens = {};
  
  DownloadService(this._dioClient);
  
  /// Downloads episode ZIP with progress tracking and resume support
  Stream<DownloadProgressModel> downloadEpisode(
    EpisodeManifestModel episode,
  ) async* {
    final tempDir = await getTemporaryDirectory();
    final partialPath = '${tempDir.path}/${episode.id}_v${episode.version}.zip${StorageConstants.partialFileSuffix}';
    final completedPath = '${tempDir.path}/${episode.id}_v${episode.version}.zip';
    
    final cancelToken = CancelToken();
    _activeCancelTokens[episode.id] = cancelToken;
    
    var progress = DownloadProgressModel.initial(episode.id, episode.sizeBytes);
    
    try {
      yield progress = progress.copyWith(phase: DownloadPhase.downloading);
      
      // Check for existing partial download
      final partialFile = File(partialPath);
      int existingBytes = 0;
      
      if (await partialFile.exists()) {
        existingBytes = await partialFile.length();
        progress = progress.copyWith(
          bytesReceived: existingBytes,
          progress: existingBytes / episode.sizeBytes,
        );
        yield progress;
      }
      
      // Download with progress
      final progressController = StreamController<DownloadProgressModel>();
      
      await _dioClient.download(
        episode.downloadUrl,
        partialPath,
        resumeDownload: existingBytes > 0,
        existingBytes: existingBytes,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final totalReceived = existingBytes + received;
          final adjustedTotal = existingBytes + total;
          
          progress = progress.copyWith(
            bytesReceived: totalReceived,
            progress: totalReceived / adjustedTotal,
          );
          progressController.add(progress);
        },
      );
      
      await progressController.close();
      
      yield* progressController.stream;
      
      // Rename partial to completed
      await partialFile.rename(completedPath);
      
      yield progress.copyWith(
        phase: DownloadPhase.completed,
        progress: 1.0,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        yield progress.copyWith(
          phase: DownloadPhase.failed,
          errorMessage: 'Download cancelled',
        );
      } else {
        rethrow;
      }
    } catch (e) {
      throw DownloadException(
        'Failed to download episode',
        episode.id,
        e,
      );
    } finally {
      _activeCancelTokens.remove(episode.id);
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
}