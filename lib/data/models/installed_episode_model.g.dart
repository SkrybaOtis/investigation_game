// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'installed_episode_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstalledEpisodeModel _$InstalledEpisodeModelFromJson(
  Map<String, dynamic> json,
) => InstalledEpisodeModel(
  episodeId: json['episodeId'] as String,
  version: (json['version'] as num).toInt(),
  localPath: json['localPath'] as String,
  installedAt: DateTime.parse(json['installedAt'] as String),
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  sha256Hash: json['sha256Hash'] as String,
);

Map<String, dynamic> _$InstalledEpisodeModelToJson(
  InstalledEpisodeModel instance,
) => <String, dynamic>{
  'episodeId': instance.episodeId,
  'version': instance.version,
  'localPath': instance.localPath,
  'installedAt': instance.installedAt.toIso8601String(),
  'sizeBytes': instance.sizeBytes,
  'sha256Hash': instance.sha256Hash,
};

InstalledEpisodesContainer _$InstalledEpisodesContainerFromJson(
  Map<String, dynamic> json,
) => InstalledEpisodesContainer(
  episodes: (json['episodes'] as List<dynamic>)
      .map((e) => InstalledEpisodeModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$InstalledEpisodesContainerToJson(
  InstalledEpisodesContainer instance,
) => <String, dynamic>{
  'episodes': instance.episodes.map((e) => e.toJson()).toList(),
  'lastUpdated': instance.lastUpdated.toIso8601String(),
};
