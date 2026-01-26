import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'installed_episode_model.g.dart';

/// Model for tracking locally installed episodes
@JsonSerializable()
class InstalledEpisodeModel extends Equatable {
  final String episodeId;
  final int version;
  final String localPath;
  final DateTime installedAt;
  final int sizeBytes;
  final String sha256Hash;
  
  const InstalledEpisodeModel({
    required this.episodeId,
    required this.version,
    required this.localPath,
    required this.installedAt,
    required this.sizeBytes,
    required this.sha256Hash,
  });
  
  factory InstalledEpisodeModel.fromJson(Map<String, dynamic> json) =>
      _$InstalledEpisodeModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$InstalledEpisodeModelToJson(this);
  
  @override
  List<Object?> get props => [episodeId, version, localPath];
}

/// Container for all installed episodes
@JsonSerializable(explicitToJson: true)
class InstalledEpisodesContainer extends Equatable {
  final List<InstalledEpisodeModel> episodes;
  final DateTime lastUpdated;
  
  const InstalledEpisodesContainer({
    required this.episodes,
    required this.lastUpdated,
  });
  
  factory InstalledEpisodesContainer.fromJson(Map<String, dynamic> json) =>
      _$InstalledEpisodesContainerFromJson(json);
  
  Map<String, dynamic> toJson() => _$InstalledEpisodesContainerToJson(this);
  
  InstalledEpisodeModel? findById(String episodeId) {
    try {
      return episodes.firstWhere((e) => e.episodeId == episodeId);
    } catch (_) {
      return null;
    }
  }
  
  @override
  List<Object?> get props => [episodes, lastUpdated];
}