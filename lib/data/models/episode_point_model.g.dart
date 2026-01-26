// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_point_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EpisodePointModel _$EpisodePointModelFromJson(Map<String, dynamic> json) =>
    EpisodePointModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isMainPoint: json['isMainPoint'] as bool? ?? false,
      order: (json['order'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EpisodePointModelToJson(EpisodePointModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'isMainPoint': instance.isMainPoint,
      'order': instance.order,
    };

EpisodeLocalizationModel _$EpisodeLocalizationModelFromJson(
  Map<String, dynamic> json,
) => EpisodeLocalizationModel(
  city: json['city'] as String,
  region: json['region'] as String?,
  country: json['country'] as String,
  countryCode: json['countryCode'] as String,
  centerLatitude: (json['centerLatitude'] as num).toDouble(),
  centerLongitude: (json['centerLongitude'] as num).toDouble(),
);

Map<String, dynamic> _$EpisodeLocalizationModelToJson(
  EpisodeLocalizationModel instance,
) => <String, dynamic>{
  'city': instance.city,
  'region': instance.region,
  'country': instance.country,
  'countryCode': instance.countryCode,
  'centerLatitude': instance.centerLatitude,
  'centerLongitude': instance.centerLongitude,
};
