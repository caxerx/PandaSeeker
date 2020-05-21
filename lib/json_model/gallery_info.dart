import 'package:json_annotation/json_annotation.dart';

part 'gallery_info.g.dart';

@JsonSerializable(nullable: true)
class GalleryInfo {
  @JsonKey(name: "gid")
  final int gid;

  @JsonKey(name: "token")
  final String token;

  @JsonKey(name: "title")
  final String title;

  @JsonKey(name: "thumb")
  final String thumbnailUrl;

  @JsonKey(name: "rating")
  final double rating;

  @JsonKey(name: "category")
  final String category;

  @JsonKey(name: "posted")
  final int postTime;

  @JsonKey(name: "uploader")
  final String uploader;

  @JsonKey(name: "tags")
  final List<String> tags;

  @JsonKey(name: "uuid")
  final String uuid;

  const GalleryInfo(
      {this.gid,
      this.token,
      this.title,
      this.thumbnailUrl,
      this.rating,
      this.category,
      this.postTime,
      this.uploader,
      this.tags,
      this.uuid});

  factory GalleryInfo.fromJson(Map<String, dynamic> json) =>
      _$GalleryInfoFromJson(json);

  Map<String, dynamic> toJson() => _$GalleryInfoToJson(this);
}
