import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pandaseeker/json_model/gallery_details_info.dart';
import 'package:pandaseeker/json_model/gallery_image_info.dart';
import 'package:pandaseeker/widget/matrix_gesture_detector.dart';
import 'package:provider/provider.dart';

class GalleryImagePage extends StatefulWidget {
  final int targetPage;

  const GalleryImagePage({this.targetPage});

  @override
  State<StatefulWidget> createState() {
    return GalleryImagePageState();
  }
}

class GalleryImagePageState extends State<GalleryImagePage> {
  Future<bool> galleryLoadingFuture;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var galleryDetailsInfo = Provider.of<GalleryDetailsInfo>(context);
    return Scaffold(
        body: GalleryView(
      onReachBottom: (context) {
        if (galleryLoadingFuture != null) return;
        galleryLoadingFuture = context
            .read<GalleryDetailsInfo>()
            .fetchNextPage()
            .then((value) => galleryLoadingFuture = null);
      },
      initialOffset: 510.0 * widget.targetPage,
      itemCount: galleryDetailsInfo.galleryImages.length,
      itemBuilder: (ctx, idx) {
        return EHImage(galleryDetailsInfo.galleryImages[idx]);
      },
    ));
  }
}

typedef void OnReachBottomCallback(BuildContext ctx);

class GalleryView extends StatefulWidget {
  final List<String> imageUrls;
  final IndexedWidgetBuilder itemBuilder;
  final itemCount;
  final double initialOffset;
  final OnReachBottomCallback onReachBottom;

  GalleryView(
      {this.imageUrls,
      this.itemBuilder,
      this.itemCount,
      this.initialOffset,
      this.onReachBottom});

  @override
  State<StatefulWidget> createState() {
    return GalleryViewState();
  }
}

class GalleryViewState extends State<GalleryView>
    with TickerProviderStateMixin {
  final ValueNotifier<Matrix4> notifier = ValueNotifier(Matrix4.identity());

  ScrollController scrollController;
  AnimationController translateController;
  AnimationController scaleController;
  AnimationController scaleTranslateController;

  Animation<double> translateAnimation;
  Animation<double> scaleTranslateAnimation;
  Animation<double> scaleAnimation;

  double lastScale = 1.0;
  double updatingScale = 1.0;
  double bleedScaledWidth = 0;
  double bleedHeight = 0.0;

  bool scaling = false;

  TapDownDetails lastTapped;

  @override
  void initState() {
    super.initState();
    scrollController =
        ScrollController(initialScrollOffset: widget.initialOffset);

    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        if (widget.onReachBottom != null) {
          widget.onReachBottom(context);
        }
      }
    });

    scaleController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    scaleAnimation = Tween<double>(begin: 1, end: 1).animate(scaleController);
    scaleController.forward();
    scaleController.addListener(() {
      setState(() {
        notifier.value.setEntry(0, 0, scaleAnimation.value);
        notifier.value.setEntry(1, 1, scaleAnimation.value);
      });
    });

    scaleTranslateController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));

    scaleTranslateAnimation =
        Tween<double>(begin: 0, end: 0).animate(scaleController);
    scaleTranslateController.forward();
    scaleTranslateController.addListener(() {
      setState(() {
        translateController.stop();
        notifier.value.setTranslationRaw(scaleTranslateAnimation.value, 0, 0);
      });
    });

    translateController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    translateAnimation =
        Tween<double>(begin: 0, end: 0).animate(translateController);
    translateController.forward();

    translateController.addListener(() {
      scaleTranslateController.stop();
      if (translateAnimation.value >= 0) {
        translateController.stop();
        return;
      }

      if (translateAnimation.value <= -bleedScaledWidth) {
        translateController.stop();
        return;
      }

      setState(() {
        notifier.value.setTranslationRaw(translateAnimation.value, 0, 0);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MatrixGestureDetector(
      onTapDown: (m, tm, sm, rm, lastTapped) {
        this.lastTapped = lastTapped;
      },
      onDoubleTap: (m, tm, sm, rm) {
        m.setFrom(notifier.value);

        var scale = 1.0;
        if (m.getMaxScaleOnAxis() == 1.0) {
          scale = 2.0;
        }

        var scrollTo = 0.0;

        if (scale == 1.0) {
          scaleTranslateAnimation =
              Tween<double>(begin: m.getTranslation().s, end: 0)
                  .animate(scaleTranslateController);
          scrollTo = scrollController.position.pixels -
              (lastTapped.localPosition.dy / 2);
        } else {
          scaleTranslateAnimation = Tween<double>(
                  begin: m.getTranslation().s,
                  end: -lastTapped.localPosition.dx)
              .animate(scaleTranslateController);
          scrollTo = scrollController.position.pixels +
              (lastTapped.localPosition.dy / 2);
        }

        if (scrollTo < 0) {
          scrollTo = 0;
        } else if (scrollTo > scrollController.position.maxScrollExtent) {
          scrollTo = scrollController.position.maxScrollExtent;
        }

        scrollController.animateTo(scrollTo,
            duration: Duration(milliseconds: 100), curve: Curves.ease);
        scaleTranslateController.forward(from: 0);

        scaleAnimation = Tween<double>(begin: m.getMaxScaleOnAxis(), end: scale)
            .animate(scaleController);
        scaleController.forward(from: 0);
      },
      onMatrixUpdateEnd: (m, tm, sm, rm, d) {
        //Don't show scroll phy when scale
        if (!scaling) {
          //scroll phy for list view
          var goto = scrollController.position.pixels -
              (d.velocity.pixelsPerSecond.dy / m.getMaxScaleOnAxis());
          if (goto < 0) {
            goto = 0;
          } else if (goto > scrollController.position.maxScrollExtent) {
            goto = scrollController.position.maxScrollExtent;
          }
          scrollController.animateTo(goto,
              duration: Duration(seconds: 1), curve: Curves.decelerate);

          //scroll phy for horizon translation
          if (d.velocity.pixelsPerSecond.dx != 0) {
            translateAnimation = Tween<double>(
                    begin: m.getTranslation().s,
                    end: m.getTranslation().s + d.velocity.pixelsPerSecond.dx)
                .animate(translateController);
            translateController.forward(from: 0);
          }
        }

        //Store last scale for check scroll phy
        scaling = false;
        lastScale = m.getMaxScaleOnAxis();
        this.notifier.value = m;
      },
      shouldRotate: false,
      shouldTranslate: true,
      onMatrixUpdateStart: (m, tm, sm, rm, d) {
        m.setFrom(notifier.value);
        scaleTranslateController.stop();
        translateController.stop();
        this.notifier.value = m;
      },
      onMatrixUpdate: (m, tm, sm, rm) {
        if (m.getRow(0).s != lastScale) {
          scaling = true;
        }

        if (m.getRow(0).s < 1) {
          m.setEntry(0, 0, 1);
          m.setEntry(1, 1, 1);
          m.setTranslation(notifier.value.getTranslation());
        }

        if (updatingScale != m.getMaxScaleOnAxis()) {
          setState(() {
            updatingScale = m.getMaxScaleOnAxis();
          });
        }

        var scale = m.getMaxScaleOnAxis();

        var originalWidth = MediaQuery.of(context).size.width;
        var originalHeight = MediaQuery.of(context).size.height;

        var scaledWidth = originalWidth * scale;
        var scaledHeight = originalHeight * scale;

        bleedScaledWidth = (scaledWidth - originalWidth);
        var bleedScaledHeight = (scaledHeight - originalHeight);

        var translation = m.getTranslation();

        if (translation.s >= 0) {
          translation.s = 0;
          m.setTranslation(translation);
        }

        if (translation.s <= -bleedScaledWidth) {
          translation.s = -bleedScaledWidth;
          m.setTranslation(translation);
        }

        if (translation.t != 0) {
          var goto = scrollController.position.pixels - (translation.t / scale);

          if (goto < 0) {
            goto = 0;
          } else if (goto > scrollController.position.maxScrollExtent) {
            goto = scrollController.position.maxScrollExtent;
          }

          scrollController.jumpTo(goto);

          translation.t = 0;
          m.setTranslation(translation);
        }

        this.notifier.value = m;

        setState(() {
          bleedHeight = bleedScaledHeight / scale;
        });
      },
      child: AnimatedBuilder(
        animation: this.notifier,
        child: ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top / updatingScale),
          controller: scrollController,
          itemBuilder: (ctx, idx) {
            if (idx == widget.itemCount) {
              return SizedBox(
                height: bleedHeight,
              );
            }
            return widget.itemBuilder(ctx, idx);
          },
          itemCount: widget.itemCount + 1,
        ),
        builder: (ctx, child) {
          return Transform(
            transform: this.notifier.value,
            child: child,
          );
        },
      ),
    );
  }
}

class EHImage extends StatefulWidget {
  final GalleryImageInfo galleryImageInfo;

  EHImage(this.galleryImageInfo, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return EHImageState();
  }
}

class EHImageState extends State<EHImage> with AutomaticKeepAliveClientMixin {
  Future<String> future;
  @override
  void initState() {
    super.initState();
    future = widget.galleryImageInfo.fetchImageUrl();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: (){
        setState(() {
          future = widget.galleryImageInfo.refetchImageUrl();
        });
      },
      child: FutureBuilder<String>(
          future: future,
          builder: (ctx, snapshot) {
            if (snapshot.data == null) {
              return buildLoading(0,
                  cachedHeight: widget.galleryImageInfo.cachedHeight,
                  page: widget.galleryImageInfo.page);
            }
            var width = MediaQuery.of(context).size.width;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: CachedNetworkImage(
                imageUrl: snapshot.data,
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    buildLoading(downloadProgress.progress,
                        cachedHeight: widget.galleryImageInfo.cachedHeight,
                        page: widget.galleryImageInfo.page),
                errorWidget: (context, url, error) =>
                    buildError(page: widget.galleryImageInfo.page),
                imageBuilder: (context, image) {
                  image
                      .resolve(ImageConfiguration())
                      .addListener(ImageStreamListener((image, sync) {
                    widget.galleryImageInfo.cachedHeight =
                        width / image.image.width * image.image.height;
                  }));
                  return Image(image: image);
                },
              ),
            );
          }),
    );
  }

  Widget buildLoading(double progress, {double cachedHeight, int page}) {
    return SizedBox(
      height: cachedHeight == null ? 500 : cachedHeight,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          progress == 0
              ? CircularProgressIndicator()
              : CircularProgressIndicator(
                  value: progress,
                ),
          Text("$page", style: Theme.of(context).textTheme.headline3)
        ],
      ),
    );
  }

  Widget buildError({int page}) {
    return SizedBox(
      height: 500,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.error,
            size: Theme.of(context).textTheme.headline3.fontSize,
            color: Theme.of(context).errorColor,
          ),
          Text("$page",
              style: Theme.of(context).textTheme.headline3.copyWith(
                    color: Theme.of(context).errorColor,
                  ))
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
