import 'package:equatable/equatable.dart';

sealed class AppException extends Equatable implements Exception {
  final String message;
  final Object? originalError;
  
  const AppException(this.message, [this.originalError]);
  
  @override
  List<Object?> get props => [message, originalError];
}

final class NetworkException extends AppException {
  final int? statusCode;
  
  const NetworkException(super.message, [this.statusCode, super.originalError]);
  
  @override
  List<Object?> get props => [...super.props, statusCode];
}

final class DownloadException extends AppException {
  final String? episodeId;
  
  const DownloadException(super.message, [this.episodeId, super.originalError]);
  
  @override
  List<Object?> get props => [...super.props, episodeId];
}

final class VerificationException extends AppException {
  final String expectedHash;
  final String actualHash;
  
  const VerificationException({
    required this.expectedHash,
    required this.actualHash,
    Object? originalError,
  }) : super('Hash verification failed', originalError);
  
  @override
  List<Object?> get props => [...super.props, expectedHash, actualHash];
}

final class ExtractionException extends AppException {
  const ExtractionException(super.message, [super.originalError]);
}

final class StorageException extends AppException {
  const StorageException(super.message, [super.originalError]);
}

final class EpisodeNotFoundException extends AppException {
  final String episodeId;
  
  const EpisodeNotFoundException(this.episodeId)
      : super('Episode not found: $episodeId');
  
  @override
  List<Object?> get props => [...super.props, episodeId];
}