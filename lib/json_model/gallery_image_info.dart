import 'package:pandaseeker/json_model/gallery_info.dart';
import 'package:pandaseeker/panda_parser.dart';

class GalleryImageInfo {
  final int gid;
  final int page;
  final String thumbnailUrl;
  final double height;
  final double width;
  final double top;
  final double left;
  final bool isShouldCorp;
  final String token;

  double cachedHeight;
  String imageUrl;
  List<String> nl = [];

  GalleryImageInfo(
      {this.gid,
      this.page,
      this.thumbnailUrl,
      this.height,
      this.width,
      this.top,
      this.left,
      this.isShouldCorp,
      this.token});

  Future<String> fetchImageUrl() async {
    if (this.imageUrl != null) {
      return this.imageUrl;
    }
    var result = await getImageLink(this.gid, this.page, this.token);
    this.imageUrl = result.url;
    if (nl != null) {
      nl.add(result.nl);
    }
    return result.url;
  }

  Future<String> refetchImageUrl() async {
    var result = await getImageLink(this.gid, this.page, this.token, nl: nl);
    if (nl != null) {
      nl.add(result.nl);
    }
    return result.url;
  }
}
