import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:pandaseeker/global_settings.dart';
import 'package:pandaseeker/json_model/gallery_details_info.dart';
import 'package:pandaseeker/json_model/gallery_info.dart';
import 'package:pandaseeker/panda_parser.dart';
import 'package:provider/provider.dart';

import 'gallery_info_page.dart';

class GalleryListPage extends StatefulWidget {
  GalleryListPage({Key key}) : super(key: key);

  @override
  _GalleryListPageState createState() => _GalleryListPageState();
}

class _GalleryListPageState extends State<GalleryListPage> {
  var lastPage = 0;
  var items = <GalleryInfo>[];
  var loading = false;
  var reachEnd = false;

  var scrollControllerListView = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollControllerListView.addListener(() {
      if (scrollControllerListView.position.pixels ==
          scrollControllerListView.position.maxScrollExtent) {
        loadMore();
      }
    });
    loadMore();
  }

  loadMore() async {
    if (reachEnd || loading) {
      return;
    }

    await addItems(lastPage);

    lastPage += 1;
  }

  setLoading(loading) {
    setState(() {
      this.loading = loading;
    });
  }

  addItems(page) async {
    setLoading(true);

    var data = await loadPage(page, 767 /*767 = GlobalSetting.safeMode*/);

    items.addAll(data.galleryInfo);

    setLoading(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(),
      body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: GestureDetector(
                  child: Row(
                    children: <Widget>[
                      Text("Panda Seeker"),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.search),
                        color: Colors.white,
                        onPressed: () =>
                            showSearch(context: context, delegate: EHSearch()),
                      )
                    ],
                  ),
                  behavior: HitTestBehavior.translucent,
                  onTap: () => scrollControllerListView.animateTo(0,
                      duration: Duration(milliseconds: 500),
                      curve: Curves.ease),
                ),
                floating: true,
              )
            ];
          },
          body: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                    onRefresh: () {
                      lastPage = 0;
                      items.clear();
                      return loadMore();
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.only(top: 0),
                      itemCount: items.length,
                      controller: scrollControllerListView,
                      itemBuilder: (context, idx) {
                        return GalleryListTile(
                            rating: items[idx].rating,
                            thumbnail: items[idx].thumbnailUrl,
                            uploader: items[idx].uploader,
                            title: items[idx].title,
                            category: items[idx].category,
                            uploadTime: items[idx].postTime,
                            gid: items[idx].gid,
                            heroTag: items[idx].uuid,
                            onTap: () {
                              final galleryInfoProvider =
                                  Provider.of<GalleryDetailsInfo>(
                                      context,
                                      listen: false);
                              galleryInfoProvider.galleryInfo = items[idx];
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => GalleryInfoPage()));
                            });
                      },
                    )),
              ),
              AnimatedLoadingIndicator(loading: loading)
            ],
          )),
    );
  }
}

class AnimatedLoadingIndicator extends StatelessWidget {
  const AnimatedLoadingIndicator({
    Key key,
    @required this.loading,
  }) : super(key: key);

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      child: LinearProgressIndicator(),
      height: loading ? 5 : 0,
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }
}

class GalleryListTile extends StatelessWidget {
  static final postTimeFormat = DateFormat("y-MM-dd HH:mm");
  final String title;
  final String category;
  final String uploader;
  final int uploadTime;
  final String thumbnail;
  final double rating;
  final int gid;
  final Function onTap;
  final String heroTag;

  const GalleryListTile({
    @required this.title,
    @required this.category,
    @required this.uploader,
    @required this.uploadTime,
    @required this.rating,
    @required this.thumbnail,
    @required this.gid,
    @required this.heroTag,
    this.onTap,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
          onTap: this.onTap,
          child: Container(
            height: 128,
            child: Row(
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.only(right: 3),
                    child: Hero(
                      tag: heroTag,
                      child: CachedNetworkImage(
                          imageUrl: thumbnail,
                          height: 128,
                          width: 100,
                          fit: BoxFit.fitWidth),
                    )),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(5),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: double.infinity,
                          child: Text(
                            title,
                            maxLines: 2,
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.only(top: 3),
                          child: Text(
                            uploader,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                            style: Theme.of(context).textTheme.caption,
                          ),
                        ),
                        Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: GalleryListRating(rating),
                                ),
                                TypeChip(category)
                              ],
                            ),
                            Spacer(),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Text(""),
                                Text(postTimeFormat.format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        uploadTime * 1000,
                                        isUtc: true)))
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )),
    );
  }
}

class DismissKeyboardOnScroll extends StatelessWidget {
  final Widget child;
  final Function onDismiss;

  const DismissKeyboardOnScroll({Key key, this.child, this.onDismiss})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (x) {
        if (x.dragDetails == null) {
          return false;
        }

        FocusScope.of(context).unfocus();
        if (onDismiss != null) {
          onDismiss();
        }
        return true;
      },
      child: child,
    );
  }
}

class TypeChip extends StatelessWidget {
  final String chipType;

  const TypeChip(
    this.chipType, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(
        GlobalSetting.searchType
            .firstWhere((element) => element.title == chipType)
            .title,
        style: TextStyle(
            color: ThemeData.estimateBrightnessForColor(GlobalSetting.searchType
                        .firstWhere((element) => element.title == chipType)
                        .color) ==
                    Brightness.light
                ? Colors.black
                : Colors.white),
      ),
      backgroundColor: GlobalSetting.searchType
          .firstWhere((element) => element.title == chipType)
          .color,
      visualDensity: VisualDensity.compact,
    );
  }
}

class GalleryListRating extends StatelessWidget {
  final double score;

  const GalleryListRating(
    this.score, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          5,
          (index) => Icon(
                score >= index + .5
                    ? score >= index && score <= index + .5
                        ? Icons.star_half
                        : Icons.star
                    : Icons.star_border,
                size: 16,
                color: score > index ? Colors.orange : Colors.grey,
              )),
    );
  }
}

class EHSearch extends SearchDelegate<String> {
  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context);

  @override
  List<Widget> buildActions(BuildContext context) {
    // TODO: implement buildActions
    return <Widget>[];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.maybePop(context));
  }

  @override
  Widget buildResults(BuildContext context) {
    return Placeholder();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return DismissKeyboardOnScroll(
        child: ListView.builder(
      itemBuilder: (ctx, idx) {
        if (idx == 0) {
          return Container(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: SearchOptionCard(),
            ),
            width: double.infinity,
          );
        } else {
          return ListTile(
            title: Text("$idx"),
          );
        }
      },
      itemCount: 5,
    ));
  }
}

class SearchOptionCard extends StatelessWidget {
  const SearchOptionCard({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              child: Text(
                "Keyword Search",
                textAlign: TextAlign.left,
              ),
            ),
            Wrap(
              direction: Axis.horizontal,
              children: List.generate(
                GlobalSetting.searchType.length,
                (index) => LayoutBuilder(
                  builder: (ctx, constraint) => Container(
                      width: constraint.maxWidth / 2,
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: MaterialButton(
                        onPressed: () {},
                        child: Text(GlobalSetting.searchType[index].title),
                        color: GlobalSetting.searchType[index].color,
                        colorBrightness: ThemeData.estimateBrightnessForColor(
                            GlobalSetting.searchType[index].color),
                      )),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
