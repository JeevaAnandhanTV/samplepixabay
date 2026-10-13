import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/controllers/notification_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/detail/download_service.dart';
import 'features/favorites/favorites_controller.dart';
import 'features/favorites/favorites_repository.dart';
import 'features/gallery/data/gallery_repository.dart';
import 'features/gallery/data/pixabay_api_client.dart';
import 'features/gallery/presentation/gallery_controller.dart';
import 'features/gallery/presentation/gallery_screen.dart';

class GalleryApp extends StatelessWidget {
  const GalleryApp({
    super.key,
    required this.prefs,
    required this.initialScreen,
  });

  final SharedPreferences prefs;
  final Widget initialScreen;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<GalleryRepository>(
          create: (_) => PixabayGalleryRepository(PixabayApiClient()),
        ),
        // Only provide DownloadService on non-web platforms
        if (!kIsWeb)
          Provider<DownloadService>(create: (_) => DownloadService()),
        ChangeNotifierProvider<GalleryController>(
          create: (context) =>
              GalleryController(context.read<GalleryRepository>())
                ..loadInitial(),
        ),
        ChangeNotifierProvider<FavoritesController>(
          create: (_) => FavoritesController(FavoritesRepository(prefs)),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(prefs),
        ),
        ChangeNotifierProvider<NotificationController>(
          create: (_) => NotificationController(),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, theme, _) => MaterialApp(
          title: 'Infinite Gallery',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: theme.mode,
          home: initialScreen,
        ),
      ),
    );
  }
}
