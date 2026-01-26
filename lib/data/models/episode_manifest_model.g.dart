// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_manifest_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpisodeManifestModel _$EpisodeManifestModelFromJson(
  Map<String, dynamic> json,
) => EpisodeManifestModel(
  id: json['id'] as String,
  version: (json['version'] as num).toInt(),
  localization: EpisodeLocalizationModel.fromJson(
    json['localization'] as Map<String, dynamic>,
  ),
  points: (json['points'] as List<dynamic>)
      .map((e) => EpisodePointModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  name: json['name'] as String,
  description: json['description'] as String,
  author: json['author'] as String,
  sha256Hash: json['sha256'] as String,
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  downloadUrl: json['downloadUrl'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  thumbnailUrl: json['thumbnailUrl'] as String?,
  difficulty: json['difficulty'] as String?,
  estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt(),
);

Map<String, dynamic> _$EpisodeManifestModelToJson(
  EpisodeManifestModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'version': instance.version,
  'localization': instance.localization.toJson(),
  'points': instance.points.map((e) => e.toJson()).toList(),
  'name': instance.name,
  'description': instance.description,
  'author': instance.author,
  'sha256': instance.sha256Hash,
  'sizeBytes': instance.sizeBytes,
  'downloadUrl': instance.downloadUrl,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'tags': instance.tags,
  'thumbnailUrl': instance.thumbnailUrl,
  'difficulty': instance.difficulty,
  'estimatedMinutes': instance.estimatedMinutes,
};

ManifestModel _$ManifestModelFromJson(Map<String, dynamic> json) =>
    ManifestModel(
      manifestVersion: (json['manifestVersion'] as num).toInt(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      episodes: (json['episodes'] as List<dynamic>)
          .map((e) => EpisodeManifestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ManifestModelToJson(ManifestModel instance) =>
    <String, dynamic>{
      'manifestVersion': instance.manifestVersion,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'episodes': instance.episodes.map((e) => e.toJson()).toList(),
    };
