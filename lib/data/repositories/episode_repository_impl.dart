import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../core/utils/file_utils.dart';
import '../../domain/repositories/episode_repository.dart';
import '../models/download_progress_model.dart';
import '../models/episode_manifest_model.dart';
import '../models/installed_episode_model.dart';
import '../services/download_service.dart';
import '../services/extraction_service.dart';
import '../services/manifest_service.dart';
import '../services/storage_service.dart';
import '../services/verification_service.dart';

final episodeRepositoryProvider = Provider<EpisodeRepository>((ref) {
  return EpisodeRepositoryImpl(
    manifestService: ref.watch(manifestServiceProvider),
    downloadService: ref.watch(downloadServiceProvider),
    verificationService: ref.watch(verificationServiceProvider),
    extractionService: ref.watch(extractionServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});

class EpisodeRepositoryImpl implements EpisodeRepository {
  final ManifestService _manifestService;
  final DownloadService _downloadService;
  final VerificationService _verificationService;
  final ExtractionService _extractionService;
  final StorageService _storageService;
  
  EpisodeRepositoryImpl({
    required ManifestService manifestService,
    required DownloadService downloadService,
    required VerificationService verificationService,
    required ExtractionService extractionService,
    required StorageService storageService,
  })  : _manifestService = manifestService,
        _downloadService = downloadService,
        _verificationService = verificationService,
        _extractionService = extractionService,
        _storageService = storageService;
  
  var logger = Logger(
    filter: null,
    printer: PrettyPrinter(),
    output: null,
  );

  @override
  Future<List<EpisodeManifestModel>> getAvailableEpisodes() async {
    final manifest = await _manifestService.fetchManifest();
    return manifest.episodes;
  }
  
  @override
  Future<List<EpisodeManifestModel>> getEpisodesByCity(String cityQuery) async {
    final manifest = await _manifestService.fetchManifestByCity(cityQuery);
    return manifest.episodes;
  }
  
  @override
  Future<List<InstalledEpisodeModel>> getInstalledEpisodes() async {
    final container = await _storageService.loadInstalledEpisodes();
    return container.episodes;
  }
  
  @override
  Stream<DownloadProgressModel> downloadAndInstallEpisode(
    EpisodeManifestModel episode,
  ) async* {
    var progress = DownloadProgressModel.initial(episode.id, episode.sizeBytes);
    
    try {
      // Phase 1: Download
      logger.i('Downloading started !!');
      yield progress = progress.copyWith(phase: DownloadPhase.downloading);
      
      String? zipPath;
      
      await for (final downloadProgress in _downloadService.downloadEpisode(episode)) {
        yield downloadProgress;
        progress = downloadProgress;
        
        if (downloadProgress.phase == DownloadPhase.completed) {
          zipPath = await _downloadService.getDownloadedZipPath(
            episode.id,
            episode.version,
          );
        } 

      }

      
      if (zipPath == null) {
        yield progress.copyWith(
          phase: DownloadPhase.failed,
          errorMessage: 'Download did not complete',
        );
        logger.f('Downloading failed !!');

        return;
      }
      
      // Phase 2: Verify
      logger.i('Veryfying started !!');
      yield progress = progress.copyWith(phase: DownloadPhase.verifying);
      
      await _verificationService.verifyFileIntegrity(
        filePath: zipPath,
        expectedHash: episode.sha256Hash,
      );
      
      // Phase 3: Extract
      logger.i('Extracting started !!');
      yield progress = progress.copyWith(phase: DownloadPhase.extracting);
      
      final installedPath = await _extractionService.extractAndInstall(
        zipPath: zipPath,
        episodeId: episode.id,
        version: episode.version,
      );
      
      // Phase 4: Validate extracted content
      logger.i('Vadidation extracted content started !!');
      final validationResult = await _verificationService.validateEpisodeContent(
        installedPath, episode.id
      );
      
      if (!validationResult.isValid) {
        await FileUtils.safeDelete(installedPath);
        yield progress.copyWith(
          phase: DownloadPhase.failed,
          errorMessage: 'Content validation failed: ${validationResult.errors.join(', ')}',
        );
        return;
      }
      
      // Phase 5: Record installation
      logger.i('Recorded installation started !!');
      yield progress = progress.copyWith(phase: DownloadPhase.installing);
      
      final installedSize = await FileUtils.getDirectorySize(installedPath);
      
      await _storageService.recordInstalledEpisode(InstalledEpisodeModel(
        episodeId: episode.id,
        version: episode.version,
        localPath: installedPath,
        installedAt: DateTime.now(),
        sizeBytes: installedSize,
        sha256Hash: episode.sha256Hash,
      ));
      
      // Cleanup temp files
      logger.i('Cleaunup temp files started !!');
      await _downloadService.cleanupTempFiles(episode.id);
      
      yield progress.copyWith(
        phase: DownloadPhase.completed,
        progress: 1.0,
      );
    } catch (e) {
      yield progress.copyWith(
        phase: DownloadPhase.failed,
        errorMessage: e.toString(),
      );

      logger.i(e.toString());
      
      // Cleanup on failure
      await _downloadService.cleanupTempFiles(episode.id);
    }
  }
  
  @override
  Future<void> deleteEpisode(String episodeId) async {
    await _storageService.removeInstalledEpisode(episodeId);
  }
  
  @override
  Future<EpisodeInstallStatus> getEpisodeStatus(EpisodeManifestModel episode) async {
    final container = await _storageService.loadInstalledEpisodes();
    final installed = container.findById(episode.id);
    
    if (installed == null) {
      return EpisodeInstallStatus.notInstalled;
    }
    
    if (installed.version < episode.version) {
      return EpisodeInstallStatus.updateAvailable;
    }
    
    return EpisodeInstallStatus.installed;
  }
  
  @override
  Future<Map<String, dynamic>> loadEpisodeGameData(String episodeId) async {
    return await _storageService.loadEpisodeData(episodeId);
  }

  @override
  void cancelDownload(String episodeId) {
    _downloadService.cancelDownload(episodeId);
  }

  
}