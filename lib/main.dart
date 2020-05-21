import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandaseeker/json_model/gallery_details_info.dart';
import 'package:pandaseeker/json_model/gallery_info.dart';
import 'package:provider/provider.dart';

import 'page/gallery_list_page.dart';
import 'global_settings.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<GalleryDetailsInfo>(
              create: (_) => GalleryDetailsInfo())
        ],
        child: MaterialApp(
          title: GlobalSetting.APP_NAME,
          theme: ThemeData(
              textTheme: GoogleFonts.openSansTextTheme(),
              secondaryHeaderColor: Colors.pink),
          darkTheme: ThemeData(
              brightness: Brightness.dark,
              textTheme:
              GoogleFonts.openSansTextTheme(ThemeData
                  .dark()
                  .textTheme)),
          home: GalleryListPage(),
        ));
  }
}
