import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../infrastructure/network/dio_client.dart';
import '../models/episode_manifest_model.dart';

final manifestServiceProvider = Provider<ManifestService>((ref) {
  return ManifestService(ref.watch(dioClientProvider));
});

class ManifestService {
  final DioClient _dioClient;
  
  ManifestService(this._dioClient);
  
  /// Fetches the episodes manifest from the server
  Future<ManifestModel> fetchManifest() async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      ApiConstants.manifestEndpoint,
    );
    
    return ManifestModel.fromJson(response.data!);
  }
  
  /// Fetches manifest for a specific region/city to reduce payload
  Future<ManifestModel> fetchManifestByCity(String cityQuery) async {
    final response = await _dioClient.get<Map<String, dynamic>>(
      ApiConstants.manifestEndpoint,
      queryParameters: {'city': cityQuery},
    );
    
    return ManifestModel.fromJson(response.data!);
  }
}