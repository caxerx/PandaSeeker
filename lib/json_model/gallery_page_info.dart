import 'package:pandaseeker/json_model/gallery_info.dart';
import 'package:pandaseeker/json_model/page_info.dart';

class GalleryListInfo {
  final PageInfo pageInfo;
  final List<GalleryInfo> galleryInfo;

  const GalleryListInfo({this.pageInfo, this.galleryInfo});
}
