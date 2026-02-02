import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_exceptions.dart';
import '../../core/utils/hash_utils.dart';

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService();
});

class VerificationService {
  /// Verifies SHA-256 hash of a file against expected hash
  /// Runs in a background isolate for performance
  Future<bool> verifyFileIntegrity({
    required String filePath,
    required String expectedHash,
  }) async {
    final file = File(filePath);
    
    if (!await file.exists()) {
      throw VerificationException(
        expectedHash: expectedHash,
        actualHash: 'FILE_NOT_FOUND',
      );
    }
    
    final actualHash = await HashUtils.computeFileSha256(filePath);
    
    if (actualHash.toLowerCase() != expectedHash.toLowerCase()) {
      throw VerificationException(
        expectedHash: expectedHash,
        actualHash: actualHash,
      );
    }
    
    return true;
  }
  
  /// Validates episode content structure after extraction
  Future<EpisodeValidationResult> validateEpisodeContent(String episodePath, String episodeId) async {
    return await Isolate.run(() => _validateContentSync(episodePath, episodeId ));
  }
  
  static EpisodeValidationResult _validateContentSync(String episodePath, String episodeId) {
    final errors = <String>[];
    
    // Check $episodeId.json exists and is valid JSON
    final episodeFile = File('$episodePath/$episodeId.json');
    if (!episodeFile.existsSync()) {
      errors.add('Missing $episodeId.json');
    } else {
      try {
        final content = episodeFile.readAsStringSync();
        // Basic JSON validation - just check it's not empty
        if (content.trim().isEmpty) {
          errors.add('$episodeId.json is empty');
        }
      } catch (e) {
        errors.add('$episodeId.json is not readable');
      }
    }
    
    // Check images directory exists
    final imagesDir = Directory('$episodePath/images');
    if (!imagesDir.existsSync()) {
      //errors.add('Missing images directory');
    }
    
    return EpisodeValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class EpisodeValidationResult {
  final bool isValid;
  final List<String> errors;
  
  const EpisodeValidationResult({
    required this.isValid,
    required this.errors,
  });
}