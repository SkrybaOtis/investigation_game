import 'dart:io';
import 'dart:isolate';

abstract final class FileUtils {
  /// Safely moves a file/directory by renaming (same filesystem) or copying
  static Future<void> safeMove(String sourcePath, String destinationPath) async {
    final source = FileSystemEntity.isDirectorySync(sourcePath)
        ? Directory(sourcePath)
        : File(sourcePath);
    
    try {
      await source.rename(destinationPath);
    } on FileSystemException {
      // If rename fails (different filesystems), fall back to copy + delete
      if (source is Directory) {
        await _copyDirectory(source, Directory(destinationPath));
        await source.delete(recursive: true);
      } else {
        await (source as File).copy(destinationPath);
        await source.delete();
      }
    }
  }
  
  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    
    await for (final entity in source.list(recursive: false)) {
      final newPath = '${destination.path}/${entity.uri.pathSegments.last}';
      
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }
  
  /// Safely deletes a file or directory if it exists
  static Future<void> safeDelete(String path) async {
    final entity = FileSystemEntity.typeSync(path);
    
    switch (entity) {
      case FileSystemEntityType.file:
        await File(path).delete();
      case FileSystemEntityType.directory:
        await Directory(path).delete(recursive: true);
      case FileSystemEntityType.notFound:
      case FileSystemEntityType.link:
      case FileSystemEntityType.pipe:
      case FileSystemEntityType.unixDomainSock:
        break;
    }
  }
  
  /// Gets directory size in bytes (runs in isolate)
  static Future<int> getDirectorySize(String path) async {
    return await Isolate.run(() => _getDirectorySizeSync(path));
  }
  
  static int _getDirectorySizeSync(String path) {
    final directory = Directory(path);
    if (!directory.existsSync()) return 0;
    
    int totalSize = 0;
    
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    }
    
    return totalSize;
  }
  
  /// Validates that required episode files exist
  static Future<bool> validateEpisodeStructure(String episodePath, String episodeId) async {
    return await Isolate.run(() {
      final episodeFile = File('$episodePath/$episodeId.json');
      // final imagesDir = Directory('$episodePath/images');
      
      return episodeFile.existsSync(); //&& imagesDir.existsSync();
    });
  }
}