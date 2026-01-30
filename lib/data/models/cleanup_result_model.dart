class CleanupResult {
  final bool success;
  final int deletedCount;
  final int freedBytes;
  final String? errorMessage;
  
  const CleanupResult({
    required this.success,
    required this.deletedCount,
    required this.freedBytes,
    this.errorMessage,
  });
  
  String get freedBytesFormatted {
    if (freedBytes < 1024) {
      return '$freedBytes B';
    } else if (freedBytes < 1024 * 1024) {
      return '${(freedBytes / 1024).toStringAsFixed(1)} KB';
    } else if (freedBytes < 1024 * 1024 * 1024) {
      return '${(freedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(freedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}