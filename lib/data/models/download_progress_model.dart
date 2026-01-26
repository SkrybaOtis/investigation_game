import 'package:equatable/equatable.dart';

enum DownloadPhase {
  idle,
  downloading,
  verifying,
  extracting,
  installing,
  completed,
  failed,
}

class DownloadProgressModel extends Equatable {
  final String episodeId;
  final DownloadPhase phase;
  final double progress; // 0.0 to 1.0
  final int bytesReceived;
  final int totalBytes;
  final String? errorMessage;
  final DateTime startedAt;
  
  const DownloadProgressModel({
    required this.episodeId,
    required this.phase,
    required this.progress,
    required this.bytesReceived,
    required this.totalBytes,
    this.errorMessage,
    required this.startedAt,
  });
  
  factory DownloadProgressModel.initial(String episodeId, int totalBytes) {
    return DownloadProgressModel(
      episodeId: episodeId,
      phase: DownloadPhase.idle,
      progress: 0.0,
      bytesReceived: 0,
      totalBytes: totalBytes,
      startedAt: DateTime.now(),
    );
  }
  
  DownloadProgressModel copyWith({
    DownloadPhase? phase,
    double? progress,
    int? bytesReceived,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DownloadProgressModel(
      episodeId: episodeId,
      phase: phase ?? this.phase,
      progress: progress ?? this.progress,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      totalBytes: totalBytes,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      startedAt: startedAt,
    );
  }
  
  String get progressPercentage => '${(progress * 100).toStringAsFixed(1)}%';
  
  String get phaseDescription {
    return switch (phase) {
      DownloadPhase.idle => 'Waiting...',
      DownloadPhase.downloading => 'Downloading... $progressPercentage',
      DownloadPhase.verifying => 'Verifying integrity...',
      DownloadPhase.extracting => 'Extracting files...',
      DownloadPhase.installing => 'Installing...',
      DownloadPhase.completed => 'Completed!',
      DownloadPhase.failed => 'Failed: ${errorMessage ?? 'Unknown error'}',
    };
  }
  
  bool get isActive => phase != DownloadPhase.idle && 
                        phase != DownloadPhase.completed && 
                        phase != DownloadPhase.failed;
  
  @override
  List<Object?> get props => [episodeId, phase, progress, bytesReceived, errorMessage];
}