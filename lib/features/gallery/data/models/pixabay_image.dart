import '../../../../core/utils/format.dart';

/// Domain model for a Pixabay image. JSON keys intentionally mirror the
/// Pixabay API so the same (de)serialisation is reused for local persistence.
class PixabayImage {
  const PixabayImage({
    required this.id,
    required this.pageUrl,
    required this.tags,
    required this.previewUrl,
    required this.webformatUrl,
    required this.largeImageUrl,
    required this.webformatWidth,
    required this.webformatHeight,
    required this.imageWidth,
    required this.imageHeight,
    required this.views,
    required this.downloads,
    required this.likes,
    required this.comments,
    required this.user,
    required this.userImageUrl,
  });

  final int id;
  final String pageUrl;
  final String tags;
  final String previewUrl;
  final String webformatUrl;
  final String largeImageUrl;
  final int webformatWidth;
  final int webformatHeight;
  final int imageWidth;
  final int imageHeight;
  final int views;
  final int downloads;
  final int likes;
  final int comments;
  final String user;
  final String userImageUrl;

  factory PixabayImage.fromJson(Map<String, dynamic> json) {
    int asInt(String key, [int fallback = 0]) =>
        (json[key] as num?)?.toInt() ?? fallback;
    final webformat = json['webformatURL'] as String? ?? '';
    return PixabayImage(
      id: asInt('id'),
      pageUrl: json['pageURL'] as String? ?? '',
      tags: json['tags'] as String? ?? '',
      previewUrl: json['previewURL'] as String? ?? webformat,
      webformatUrl: webformat,
      largeImageUrl: json['largeImageURL'] as String? ?? webformat,
      webformatWidth: asInt('webformatWidth', 4),
      webformatHeight: asInt('webformatHeight', 3),
      imageWidth: asInt('imageWidth'),
      imageHeight: asInt('imageHeight'),
      views: asInt('views'),
      downloads: asInt('downloads'),
      likes: asInt('likes'),
      comments: asInt('comments'),
      user: json['user'] as String? ?? 'Unknown',
      userImageUrl: json['userImageURL'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageURL': pageUrl,
        'tags': tags,
        'previewURL': previewUrl,
        'webformatURL': webformatUrl,
        'largeImageURL': largeImageUrl,
        'webformatWidth': webformatWidth,
        'webformatHeight': webformatHeight,
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'views': views,
        'downloads': downloads,
        'likes': likes,
        'comments': comments,
        'user': user,
        'userImageURL': userImageUrl,
      };

  double get aspectRatio => (webformatWidth > 0 && webformatHeight > 0)
      ? webformatWidth / webformatHeight
      : 4 / 3;

  List<String> get tagList => tags
      .split(',')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList(growable: false);

  String get title {
    final t = tagList;
    return t.isEmpty
        ? 'Photo by $user'
        : '${capitalize(t.first)} photo by $user';
  }

  /// Pixabay has no description field, so a human-readable one is composed
  /// from the available metadata (tags, author, resolution, popularity).
  String get description {
    final t = tagList;
    final buffer = StringBuffer();
    if (t.isEmpty) {
      buffer.write('A photo shared by $user on Pixabay.');
    } else {
      buffer.write('A ${t.first} image shared by $user on Pixabay.');
      if (t.length > 1) {
        buffer.write(' It is associated with ${t.skip(1).join(', ')}.');
      }
    }
    if (imageWidth > 0 && imageHeight > 0) {
      buffer.write(' Original resolution: $imageWidth × $imageHeight px.');
    }
    buffer.write(' It has been viewed ${compactNumber(views)} times, '
        'downloaded ${compactNumber(downloads)} times and liked '
        '${compactNumber(likes)} times.');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) => other is PixabayImage && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
