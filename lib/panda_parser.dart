import 'package:html/dom.dart';
import 'package:intl/intl.dart';
import 'package:html/parser.dart' show parse;

import 'package:http/http.dart' as http;
import 'package:pandaseeker/debug_account_info.dart';
import 'package:pandaseeker/json_model/gallery_image_info.dart';
import 'package:pandaseeker/json_model/page_info.dart';
import 'package:uuid/uuid.dart';

import 'json_model/gallery_image_url_info.dart';
import 'json_model/gallery_info.dart';
import 'json_model/gallery_page_info.dart';
import 'json_model/gallery_thumbnail_page_info.dart';

var dateFormat = DateFormat("y-M-d H:m");
var ratingRegex = RegExp(r"background-position:(-?[0-9]+)px (-?[0-9]+)px;");
var galleryLinkRegex = RegExp(r"e-hentai.org\/g\/([a-z0-9]+)\/([a-z0-9]+)\/");
var galleryImageRegex = RegExp(
    r"margin:1px auto 0; width:([0-9]+)px; height:([0-9]+)px; background:transparent url\((.+)\) (-?[0-9]+)(?:px)? (-?[0-9]+)(?:px)? no-repeat");

var pageTokenRegex = RegExp(r"e-hentai.org\/s\/(.+)\/");
var galleryUrlNlRegex = RegExp(r"return nl\('(.+)'\)");
var totalItemRegex = RegExp(r"Showing .+ of ([0-9]+) images");

Future<GalleryListInfo> loadPage(int page, int filter) async {
  return parseGalleryList(await http.read(
      'https://e-hentai.org/?page=$page&f_cats=$filter',
      headers: {"cookie": "sl=dm_2;"}));
}

Future<GalleryThumbnailPageInfo> loadGallery(
    int gid, String token, int page) async {
  var result = await http.read('https://e-hentai.org/g/$gid/$token/?p=$page',
      headers: {"cookie": "sl=dm_2;"});
  return parseGallerySmallThumbnail(result, gid);
}

GalleryThumbnailPageInfo parseGallerySmallThumbnail(String html, int gid) {
  var document = parse(html);
  var thumbnails = document.querySelectorAll(".gdtm div");
  var thumbnailList = thumbnails.map((e) {
    var match = galleryImageRegex.firstMatch(e.attributes["style"]);
    var tokenMatch =
        pageTokenRegex.firstMatch(e.querySelector("a").attributes["href"]);
    var imgPage = e.querySelector("img").attributes["alt"];
    return GalleryImageInfo(
        isShouldCorp: true,
        thumbnailUrl: match.group(3),
        width: double.parse(match.group(1)),
        height: double.parse(match.group(2)),
        left: double.parse(match.group(4)),
        top: double.parse(match.group(5)),
        token: tokenMatch.group(1),
        gid: gid,
        page: int.parse(imgPage));
  }).toList();
  return GalleryThumbnailPageInfo(
      pageInfo: parsePage(document), thumbnail: thumbnailList);
}

//List<GalleryThumbnailInfo> parseGalleryLargeThumbnail(String html) {
//  var document = parse(html);
//  var thumbnails = document.querySelectorAll(".gdtl img");
//  return thumbnails.map((e) => e.attributes["src"]).toList();
//}

Future<GalleryImageUrlInfo> getImageLink(int gid, int page, String token,
    {List<String> nl}) async {
  var nlQuery = "skipserver=";
  if (nl != null) {
    nlQuery += nl.join("_");
  }
  var accountCookie = DebugAccountInfo.accountCookie;
  var result = await http.read('https://e-hentai.org/s/$token/$gid-$page',
      headers: {"cookie": "$accountCookie $nlQuery"});
  return parseImagePage(result);
}

GalleryImageUrlInfo parseImagePage(String html) {
  var document = parse(html);
  var url = document.querySelector("#img").attributes["src"];
  var nlScript = document.querySelector("#loadfail").attributes["onclick"];
  var nlMatch = galleryUrlNlRegex.firstMatch(nlScript);

  return GalleryImageUrlInfo(url: url, nl: nlMatch?.group(1));
}

PageInfo parsePage(Document document) {
  var currentPage = int.parse(document.querySelector(".ptds a").text);
  var pageIndicator = document.querySelectorAll(".ptt td");
  var lastPage = int.parse(pageIndicator[pageIndicator.length - 2].text);
  var totalItemDom = document.querySelector(".gpc");
  var totalItem = 0;
  if (totalItemDom != null) {
    totalItem = int.parse(totalItemRegex
        .firstMatch(document.querySelector(".gpc").text)
        .group(1));
  }

  return PageInfo(
      currentPage: currentPage, totalPage: lastPage, totalItems: totalItem);
}

GalleryListInfo parseGalleryList(String html) {
  var document = parse(html);
  var info = document
      .querySelectorAll("table.glte>tbody>tr")
      .where((e) => e.querySelector(".gl1e") != null)
      .map((e) {
    var thumb = e.querySelector(".gl1e img");
    var title = e.querySelector(".glink");
    var rate = e.querySelector(".ir");
    var uploader = e.querySelector(".ir+div");
    var galleryInfo = e.querySelector(".gl3e");
    var category = galleryInfo.querySelector(".cn");
    var time = galleryInfo.querySelector(".cn+div");
    var tags = e.querySelectorAll(".gt,.gtl");
    var galleryLink = e.querySelector(".gl1e a>img");

    var tagList = tags
        .map((element) => element.attributes["title"].startsWith(":")
            ? element.attributes["title"].replaceFirst(":", "")
            : element.attributes["title"])
        .toList();

    var rating = parseRating(rate.attributes["style"]);

    var galleryUrl = galleryLink.parent.attributes["href"];

    var galleryLinkMatch = galleryLinkRegex.firstMatch(galleryUrl);

    return GalleryInfo(
        uuid: Uuid().v4(),
        gid: int.parse(galleryLinkMatch.group(1)),
        token: galleryLinkMatch.group(2),
        title: title.text.trim(),
        thumbnailUrl: thumb.attributes["src"],
        rating: rating,
        category: category.text,
        uploader: uploader.text,
        postTime:
            ((dateFormat.parse(time.text).millisecondsSinceEpoch ~/ 1000)),
        tags: tagList);
  }).toList();

  return GalleryListInfo(pageInfo: parsePage(document), galleryInfo: info);
}

double parseRating(String cssString) {
  var matchResult = ratingRegex.firstMatch(cssString);
  var isHalfStar = matchResult.group(2) == "-21";
  var scorePosition = int.parse(matchResult.group(1));
  var score = (scorePosition + 80) * 2 / 32;

  return isHalfStar ? score - .5 : score;
}

Map<String, List<String>> parseTags(List<String> tags) {
  var groupedTags = <String, List<String>>{};
  tags.forEach((tag) {
    if (tag.indexOf(":") > 0) {
      var splintedTag = tag.split(":");
      if (groupedTags[splintedTag[0]] == null) {
        groupedTags[splintedTag[0]] = [];
      }
      groupedTags[splintedTag[0]].add(splintedTag[1]);
    } else {
      if (groupedTags["misc"] == null) {
        groupedTags["misc"] = [];
      }
      groupedTags["misc"].add(tag);
    }
  });
  return groupedTags;
}
