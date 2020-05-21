import 'package:flutter/cupertino.dart';
import 'package:pandaseeker/json_model/gallery_image_info.dart';
import 'package:pandaseeker/json_model/gallery_info.dart';
import 'package:pandaseeker/json_model/page_info.dart';
import 'package:pandaseeker/panda_parser.dart';

class GalleryDetailsInfo with ChangeNotifier {
  GalleryInfo _galleryInfo;
  List<GalleryImageInfo> _galleryImages;
  PageInfo _pageInfo;

  GalleryDetailsInfo();

  set galleryInfo(GalleryInfo val) {
    _galleryInfo = val;
    _galleryImages = [];
    _pageInfo = PageInfo(currentPage: 0, totalPage: 1, totalItems: 0);
    notifyListeners();
  }

  GalleryInfo get galleryInfo {
    return _galleryInfo;
  }

  List<GalleryImageInfo> get galleryImages {
    return _galleryImages;
  }

  PageInfo get pageInfo {
    return _pageInfo;
  }

  Future<bool> fetchNextPage() async {
    if (_pageInfo.totalPage > _pageInfo.currentPage) {
      var galleryThumbnails = await loadGallery(
          _galleryInfo.gid, _galleryInfo.token, _pageInfo.currentPage);
      _pageInfo = galleryThumbnails.pageInfo;
      _galleryImages.addAll(galleryThumbnails.thumbnail);
      notifyListeners();
    }
    return false;
  }
}
