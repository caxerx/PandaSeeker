// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gallery_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GalleryInfo _$GalleryInfoFromJson(Map<String, dynamic> json) {
  return GalleryInfo(
    gid: json['gid'] as int,
    token: json['token'] as String,
    title: json['title'] as String,
    thumbnailUrl: json['thumb'] as String,
    rating: (json['rating'] as num)?.toDouble(),
    category: json['category'] as String,
    postTime: json['posted'] as int,
    uploader: json['uploader'] as String,
    tags: (json['tags'] as List)?.map((e) => e as String)?.toList(),
    uuid: json['uuid'] as String,
  );
}

Map<String, dynamic> _$GalleryInfoToJson(GalleryInfo instance) =>
    <String, dynamic>{
      'gid': instance.gid,
      'token': instance.token,
      'title': instance.title,
      'thumb': instance.thumbnailUrl,
      'rating': instance.rating,
      'category': instance.category,
      'posted': instance.postTime,
      'uploader': instance.uploader,
      'tags': instance.tags,
      'uuid': instance.uuid,
    };
