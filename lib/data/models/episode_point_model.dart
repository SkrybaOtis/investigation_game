import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong2/latlong.dart';

part 'episode_point_model.g.dart';

@JsonSerializable()
class EpisodePointModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final double latitude;
  final double longitude;
  final bool isMainPoint;
  final int? order;
  
  const EpisodePointModel({
    required this.id,
    required this.name,
    this.description,
    required this.latitude,
    required this.longitude,
    this.isMainPoint = false,
    this.order,
  });
  
  LatLng get latLng => LatLng(latitude, longitude);
  
  factory EpisodePointModel.fromJson(Map<String, dynamic> json) =>
      _$EpisodePointModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$EpisodePointModelToJson(this);
  
  @override
  List<Object?> get props => [id, name, latitude, longitude, isMainPoint, order];
}

@JsonSerializable()
class EpisodeLocalizationModel extends Equatable {
  final String city;
  final String? region;
  final String country;
  final String countryCode;
  final double centerLatitude;
  final double centerLongitude;
  
  const EpisodeLocalizationModel({
    required this.city,
    this.region,
    required this.country,
    required this.countryCode,
    required this.centerLatitude,
    required this.centerLongitude,
  });
  
  LatLng get center => LatLng(centerLatitude, centerLongitude);
  
  factory EpisodeLocalizationModel.fromJson(Map<String, dynamic> json) =>
      _$EpisodeLocalizationModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$EpisodeLocalizationModelToJson(this);
  
  @override
  List<Object?> get props => [city, region, country, countryCode];
}