import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:core';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

/// Computes SHA-256 hash in a separate isolate to avoid UI jank
abstract final class HashUtils {
  /// Computes SHA-256 hash of a file in a background isolate
  static Future<String> computeFileSha256(String filePath) async {
    return await Isolate.run(() => _computeSha256Sync(filePath));
  }
  
  static String _computeSha256Sync(String filePath) {
    final file = File(filePath);
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);
    
    // Read file in chunks to avoid loading entire file into memory
    const chunkSize = 1024 * 1024; // 1MB chunks
    final randomAccessFile = file.openSync();
    
    try {
      final buffer = Uint8List(chunkSize);
      int bytesRead;
      
      while ((bytesRead = randomAccessFile.readIntoSync(buffer)) > 0) {
        if (bytesRead < chunkSize) {
          input.add(buffer.sublist(0, bytesRead));
        } else {
          input.add(buffer);
        }
      }
      
      input.close();
      return output.events.single.toString();
    } finally {
      randomAccessFile.closeSync();
    }
  }
  
  /// Computes SHA-256 hash of bytes (for smaller data)
  static String computeBytesSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}