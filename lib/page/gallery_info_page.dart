import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pandaseeker/json_model/gallery_details_info.dart';
import 'package:pandaseeker/json_model/gallery_info.dart';
import 'package:pandaseeker/json_model/gallery_image_info.dart';
import 'package:pandaseeker/page/gallery_list_page.dart';
import 'package:pandaseeker/panda_parser.dart';
import 'package:provider/provider.dart';

import 'gallery_image_page.dart';

class GalleryInfoPage extends StatefulWidget {
  const GalleryInfoPage();

  @override
  State<StatefulWidget> createState() {
    return GalleryInfoPageState();
  }
}

class GalleryInfoPageState extends State<GalleryInfoPage> {
  ScrollController thumbnailScrollController = ScrollController();
  Future<bool> thumbnailInitFuture;
  Future<bool> thumbnailLoadingFuture;

  @override
  void initState() {
    super.initState();
    thumbnailInitFuture = thumbnailLoadingFuture =
        context.read<GalleryDetailsInfo>().fetchNextPage();
    thumbnailScrollController.addListener(() {
      if (thumbnailScrollController.position.pixels ==
          thumbnailScrollController.position.maxScrollExtent) {
        setState(() {
          if (thumbnailLoadingFuture == null) {
            thumbnailLoadingFuture = context
                .read<GalleryDetailsInfo>()
                .fetchNextPage()
                .then((value) => null);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final galleryInfo = Provider.of<GalleryDetailsInfo>(context);
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: CustomScrollView(
              controller: thumbnailScrollController,
              slivers: <Widget>[
                SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    DecoratedBox(
                        decoration: BoxDecoration(color: Colors.black54),
                        child: Column(children: [
                          SizedBox(
                            height: 30,
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                top: 15, left: 15, right: 15, bottom: 25),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Hero(
                                    tag: galleryInfo.galleryInfo.uuid,
                                    child: CachedNetworkImage(
                                        imageUrl: galleryInfo
                                            .galleryInfo.thumbnailUrl,
                                        width: 128,
                                        fit: BoxFit.fitWidth)),
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          galleryInfo.galleryInfo.title,
                                          maxLines: 5,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.left,
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1
                                              .copyWith(color: Colors.white),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 10),
                                          child: Text(
                                            galleryInfo.galleryInfo.uploader,
                                            textAlign: TextAlign.left,
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle2
                                                .copyWith(
                                                    color: Colors.white70),
                                          ),
                                        ),
                                        TypeChip(
                                            galleryInfo.galleryInfo.category)
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                                bottom: 18, left: 18, right: 18),
                            child: LayoutBuilder(
                              builder: (context, constraint) {
                                return Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    SizedBox(
                                        width: (constraint.maxWidth / 2) - 7,
                                        child: RaisedButton(
                                          color: Theme.of(context).primaryColor,
                                          colorBrightness: ThemeData
                                              .estimateBrightnessForColor(
                                                  Theme.of(context)
                                                      .primaryColor),
                                          child: Text("Read"),
                                          onPressed: () {
                                            Navigator.push(context,
                                                MaterialPageRoute(
                                                    builder: (context) {
                                              return GalleryImagePage();
                                            }));
                                          },
                                        )),
                                    SizedBox(
                                        width: (constraint.maxWidth / 2) - 7,
                                        child: RaisedButton(
                                          color: Theme.of(context)
                                              .secondaryHeaderColor,
                                          colorBrightness: ThemeData
                                              .estimateBrightnessForColor(
                                                  Theme.of(context)
                                                      .secondaryHeaderColor),
                                          child: Text("Download"),
                                          onPressed: () {},
                                        ))
                                  ],
                                );
                              },
                            ),
                          ),
                        ])),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        thickness: 1.5,
                      ),
                    ),
                    GalleryTags(),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(
                        thickness: 1.5,
                      ),
                    )
                  ]),
                ),
                SliverLayoutBuilder(
                  builder: (ctx, constraint) {
                    return FutureBuilder(
                      future: thumbnailInitFuture,
                      builder: (ctx, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SliverPadding(
                            padding: EdgeInsets.all(20),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                Center(
                                  child: CircularProgressIndicator(),
                                )
                              ]),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithMaxCrossAxisExtent(
                                    childAspectRatio: 0.7,
                                    maxCrossAxisExtent: 128,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10),
                            delegate: SliverChildBuilderDelegate((ctx, idx) {
                              return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                GalleryImagePage(
                                                  targetPage: idx,
                                                )));
                                  },
                                  child: Center(
                                      child: PositionedImage(
                                    left: galleryInfo.galleryImages[idx].left,
                                    top: galleryInfo.galleryImages[idx].top,
                                    width: galleryInfo.galleryImages[idx].width,
                                    height:
                                        galleryInfo.galleryImages[idx].height,
                                    image: CachedNetworkImage(
                                      imageUrl: galleryInfo
                                          .galleryImages[idx].thumbnailUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )));
                            }, childCount: galleryInfo.galleryImages.length),
                          ),
                        );
                      },
                    );
                  },
                )
              ],
            ),
          ),
          FutureBuilder(
            future: thumbnailLoadingFuture,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                this.thumbnailLoadingFuture = null;
              }
              return AnimatedLoadingIndicator(
                  loading: snapshot.connectionState == ConnectionState.waiting);
            },
          )
        ],
      ),
    );
  }
}

class GalleryTags extends StatelessWidget {
  const GalleryTags({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final galleryInfo = Provider.of<GalleryDetailsInfo>(context);
    final parsedTag = parseTags(galleryInfo.galleryInfo.tags);
    final tagCategory = parsedTag.keys.toList();

    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 10),
      child: galleryInfo.galleryInfo.tags.length == 0
          ? Text(
              "No tags have been added for this gallery yet.",
              textAlign: TextAlign.center,
            )
          : Column(
              children: List.generate(tagCategory.length, (index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Transform.scale(
                        scale: .85,
                        child: Chip(
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          label: Text(tagCategory[index],
                              style: TextStyle(
                                color: ThemeData.estimateBrightnessForColor(
                                            Theme.of(context).primaryColor) ==
                                        Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              )),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                      ),
                      Expanded(
                        child: Wrap(
                          children: List.generate(
                              parsedTag[tagCategory[index]].length, (index2) {
                            return Transform.scale(
                                scale: .85,
                                child: Chip(
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  label: Text(
                                    parsedTag[tagCategory[index]][index2],
                                  ),
                                ));
                          }),
                        ),
                      )
                    ],
                  ),
                );
              }),
            ),
    );
  }
}

class PositionedImage extends StatelessWidget {
  final Widget image;
  final double left;
  final double top;
  final double width;
  final double height;

  const PositionedImage({
    this.image,
    this.left,
    this.top,
    this.width,
    this.height,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        width: this.width,
        height: this.height,
        child: Stack(
          overflow: Overflow.clip,
          children: <Widget>[
            Positioned(
              left: this.left,
              top: this.top,
              child: this.image,
            )
          ],
        ));
  }
}
