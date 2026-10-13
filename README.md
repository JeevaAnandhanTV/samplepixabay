# Infinite Image Gallery (Flutter)

A production-style Flutter gallery app built for the **Gnxtace Technologies – Flutter Intermediate Assignment**.
It consumes the **Pixabay API**, supports infinite scrolling, an image detail screen, downloads to the device
gallery, and persistent favourites.

## Features

| Requirement | Implementation |
|---|---|
| Responsive grid home screen | 2 / 3 / 4 / 5 columns by width; toggle between **masonry** and **uniform** `GridView` |
| Infinite scroll / pagination | Scroll-extent trigger + viewport-fill check, duplicate protection, race-condition guard, end-of-list indicator |
| Loading states | Pulsing skeleton grid (first load), footer spinner (next page), pull-to-refresh |
| Error handling | Typed `AppException` (network, timeout, rate-limit, invalid/missing key, server…), full-screen retry, inline "Retry" for failed pagination, snackbars |
| Image detail | Hero animation, zoomable full-screen viewer, tags, author, stats |
| Description | Pixabay has no description field, so one is generated from tags, author, resolution and popularity (`PixabayImage.description`) |
| Download | Full-size download with **progress + cancel**, saved to the photo gallery album "Infinite Gallery" |
| Favourites + screen | Heart on tiles & detail, persisted locally (`shared_preferences`), dedicated Favorites screen |
| Image performance | `cached_network_image` (disk cache), `memCacheWidth` sized to the tile, fade-in, lazy sliver builders, per-widget rebuild isolation (`context.select`) |
| Bonus | Search (debounced), category filters, masonry grid, hero animations, light/dark/system theme (persisted), sharing, download progress, unit + widget tests |

## 1. Setup

### Prerequisites
* Flutter 3.24+ (Dart 3.5+), Android Studio / Xcode as needed
* Python 3 (only for the one-time patch script; optional - manual steps below)

### Get a Pixabay API key
1. Create a free account at <https://pixabay.com/accounts/register/>.
2. Open <https://pixabay.com/api/docs/> - your key is shown in the docs when logged in.

### Generate native projects & install
This archive contains the Dart source (`lib/`, `test/`, `pubspec.yaml`). Generate the Android/iOS runners once:

```bash
cd infinite_image_gallery
flutter create . --project-name infinite_image_gallery --org com.gnxtace --platforms android,ios
python3 tool/patch_platforms.py     # adds permissions (see "Manual platform setup" if you skip this)
flutter pub get
```

> If `flutter create` ever overwrites `pubspec.yaml`, `lib/main.dart` or `test/widget_test.dart`, restore them from the zip.

### Configure the API key (never committed)
The key is injected at build time with `--dart-define`:

```bash
# Option A - inline
flutter run --dart-define=PIXABAY_API_KEY=YOUR_KEY

# Option B - file (recommended). It is git-ignored.
cp dart_defines.json.example dart_defines.json   # then paste your key
flutter run --dart-define-from-file=dart_defines.json
```

Build an APK:
```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
# -> build/app/outputs/flutter-apk/app-release.apk
```

In VS Code add `"args": ["--dart-define-from-file=dart_defines.json"]` to your launch configuration.
Without a key the app shows a clear "API key is missing" screen instead of crashing.

### Run tests
```bash
flutter test
```

### Manual platform setup (if you skip the patch script)
**Android** - `android/app/src/main/AndroidManifest.xml`, before `<application>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
```
**iOS** - `ios/Runner/Info.plist`:
```xml
<key>NSPhotoLibraryAddUsageDescription</key><string>Saves images you download into your photo library.</string>
<key>NSPhotoLibraryUsageDescription</key><string>Needed to save downloaded images into the app's photo album.</string>
```
and set the iOS deployment target to **13.0** (`ios/Podfile`: `platform :ios, '13.0'`).

## 2. Architecture

Feature-first folders with a light layered structure:

```
lib/
  main.dart / app.dart          # bootstrap + dependency wiring (Provider)
  core/
    config/app_config.dart      # API key (dart-define), constants
    errors/app_exception.dart   # one typed exception for the whole app
    theme/                      # Material 3 themes + persisted ThemeController
    utils/format.dart
  features/
    gallery/
      data/                     # PixabayApiClient (Dio) -> GalleryRepository, PixabayImage model
      presentation/             # GalleryController (ChangeNotifier), GalleryScreen, widgets
    detail/                     # DetailScreen, DownloadService
    favorites/                  # FavoritesRepository (prefs) -> FavoritesController -> FavoritesScreen
test/                           # unit + widget tests
```

**State management: Provider + `ChangeNotifier`.** Chosen for being simple, idiomatic and easy to test at
intermediate level without code generation.

* **UI** (widgets) only reads state and calls controller methods - no networking or storage logic.
* **Controllers** (`GalleryController`, `FavoritesController`, `ThemeController`) hold state and business rules.
* **Repositories / services** (`GalleryRepository`, `FavoritesRepository`, `DownloadService`) talk to the outside
  world. `GalleryRepository` is an interface so tests inject a fake with no network.
* **Errors** are mapped once (Dio / Gal → `AppException`) so the UI shows consistent messages.

Notable details in `GalleryController`:
* **Generation counter** - responses from outdated requests (e.g. the user changed category mid-flight) are discarded.
* **Dedup by id** - Pixabay can return overlapping items between pages.
* **Pagination end detection** - `page * perPage < totalHits`, plus handling Pixabay's "page out of range" 400 as "end of list".
* **Failure isolation** - a failed *load more* keeps existing items and shows an inline Retry; a failed *refresh* keeps the old list and shows a snackbar.

## 3. Assumptions & limitations

* **API:** Pixabay (`image_type=photo`, `safesearch=true`, `order=popular`). Free tier: 100 requests/minute (handled with a friendly message on HTTP 429) and max **500 results per query** (so the feed ends after ~500 items).
* **Description:** Pixabay does not supply captions, so a description is composed from available metadata.
* **Pixabay terms:** responses may be cached for 24h; permanent hotlinking of images is discouraged by Pixabay. Images are shown via HTTP caching only, and "Download" saves a local copy for the user.
* **Download** works on Android and iOS (uses `gal`). Desktop/web are not supported targets. Android 10+ requires no runtime permission (MediaStore); Android ≤ 9 / iOS prompt the user, and a denial is reported with a clear message.
* **Favourites** are stored in `shared_preferences` as JSON. That is ideal for tens/hundreds of items; for thousands, switch the repository to SQLite/Isar (only `FavoritesRepository` changes).
* **No offline gallery feed** - only favourites persist; previously viewed images are served from the disk cache when possible.
* **Tests:** controllers, model, favourites persistence and two widget tests. Image-heavy widget tests and integration tests are not included.
* The `android/` and `ios/` folders are generated with `flutter create` (see setup) rather than shipped in the archive. This project was written without running it on a device in the authoring environment, so run `flutter analyze` and `flutter test` first, and tweak any package-version differences if reported.

## 4. Submission checklist

- [x] Push to a Git repository (`git init && git add . && git commit`)
- [ ] Add 2–4 screenshots to `docs/screenshots/` and link them here
- [ ] Attach the release APK (`flutter build apk --release --dart-define-from-file=dart_defines.json`)
