import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'episode_point_model.dart';

part 'episode_manifest_model.g.dart';

/// Model representing episode metadata from server manifest
@JsonSerializable(explicitToJson: true)
class EpisodeManifestModel extends Equatable {
  final String id;
  final int version;
  final EpisodeLocalizationModel localization;
  final List<EpisodePointModel> points;
  final String name;
  final String description;
  final String author;
  @JsonKey(name: 'sha256')
  final String sha256Hash;
  final int sizeBytes;
  final String downloadUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String>? tags;
  final String? thumbnailUrl;
  final String? difficulty;
  final int? estimatedMinutes;
  
  const EpisodeManifestModel({
    required this.id,
    required this.version,
    required this.localization,
    required this.points,
    required this.name,
    required this.description,
    required this.author,
    required this.sha256Hash,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.createdAt,
    this.updatedAt,
    this.tags,
    this.thumbnailUrl,
    this.difficulty,
    this.estimatedMinutes,
  });
  
  /// Gets the main point of the episode
  EpisodePointModel get mainPoint =>
      points.firstWhere((p) => p.isMainPoint, orElse: () => points.first);
  
  /// Human-readable file size
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  factory EpisodeManifestModel.fromJson(Map<String, dynamic> json) =>
      _$EpisodeManifestModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$EpisodeManifestModelToJson(this);
  
  @override
  List<Object?> get props => [id, version, sha256Hash];
}

/// Root manifest containing all episodes
@JsonSerializable(explicitToJson: true)
class ManifestModel extends Equatable {
  final int manifestVersion;
  final DateTime generatedAt;
  final List<EpisodeManifestModel> episodes;
  
  const ManifestModel({
    required this.manifestVersion,
    required this.generatedAt,
    required this.episodes,
  });
  
  factory ManifestModel.fromJson(Map<String, dynamic> json) =>
      _$ManifestModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$ManifestModelToJson(this);
  
  @override
  List<Object?> get props => [manifestVersion, generatedAt, episodes.length];
}