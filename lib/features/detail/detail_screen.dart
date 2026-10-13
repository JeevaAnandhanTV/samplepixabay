import 'dart:convert';
import 'dart:html' as html;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/controllers/notification_controller.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/format.dart';
import '../favorites/favorites_controller.dart';
import '../gallery/data/models/pixabay_image.dart';
import 'download_service.dart';

void openDetail(BuildContext context, PixabayImage image, String heroPrefix) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DetailScreen(image: image, heroPrefix: heroPrefix),
    ),
  );
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.image, required this.heroPrefix});

  final PixabayImage image;
  final String heroPrefix;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  double? _progress; // null = idle
  CancelToken? _cancelToken;

  bool get _downloading => _progress != null;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _download() async {
    // Web platform: download image programmatically
    if (kIsWeb) {
      final messenger = ScaffoldMessenger.of(context);
      setState(() {
        _progress = 0.5;
      });
      
      try {
        final response = await http.get(Uri.parse(widget.image.largeImageUrl));
        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'pixabay_${widget.image.id}.jpg')
            ..click();
          
          html.Url.revokeObjectUrl(url);
          
          messenger.showSnackBar(
            const SnackBar(content: Text('Image downloaded successfully')),
          );
        } else {
          throw Exception('Failed to download image');
        }
      } catch (e) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Download failed. Please try again.')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _progress = null;
          });
        }
      }
      return;
    }

    // Check if DownloadService is available
    try {
      final service = context.read<DownloadService>();
      final messenger = ScaffoldMessenger.of(context);
      final notifications = context.read<NotificationController>();
      final token = CancelToken();
      setState(() {
        _progress = 0;
        _cancelToken = token;
      });
      try {
        await service.saveToGallery(
          widget.image,
          cancelToken: token,
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
        );
        messenger.showSnackBar(
          const SnackBar(content: Text('Saved to your gallery')),
        );
        notifications.addDownloadComplete(widget.image.id, widget.image.largeImageUrl);
      } on AppException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
        notifications.addError('Download Failed', e.message);
      } finally {
        if (mounted) {
          setState(() {
            _progress = null;
            _cancelToken = null;
          });
        }
      }
    } catch (e) {
      // DownloadService not available
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Download not available on this platform')),
      );
    }
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Share.share(
        '${widget.image.title}\n${widget.image.pageUrl}',
        subject: widget.image.title,
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Sharing is not available on this device')),
      );
    }
  }

  void _openFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullScreenViewer(image: widget.image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.image;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isFavorite = context
        .select<FavoritesController, bool>((c) => c.isFavorite(image.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_outlined),
            onPressed: _share,
          ),
          IconButton(
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : null,
            ),
            onPressed: () async {
              final controller = context.read<FavoritesController>();
              final notifications = context.read<NotificationController>();
              final added = await controller.toggle(image);
              if (added) {
                notifications.addFavoriteAdded(image.id, image.webformatUrl);
              } else {
                notifications.addFavoriteRemoved(image.id);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _openFullScreen,
                child: Hero(
                  tag: '${widget.heroPrefix}_${image.id}',
                  child: AspectRatio(
                    aspectRatio: image.aspectRatio,
                    child: CachedNetworkImage(
                      imageUrl: image.largeImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => CachedNetworkImage(
                        imageUrl: image.webformatUrl,
                        fit: BoxFit.cover,
                      ),
                      errorWidget: (_, __, ___) => CachedNetworkImage(
                        imageUrl: image.webformatUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: scheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, size: 48),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      image.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (image.userImageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: CircleAvatar(
                              radius: 16,
                              backgroundImage:
                                  CachedNetworkImageProvider(image.userImageUrl),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            'by ${image.user}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        image.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in image.tagList)
                          Chip(
                            label: Text(tag),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: scheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Stat(icon: Icons.visibility_outlined, value: image.views),
                          _Stat(icon: Icons.download_outlined, value: image.downloads),
                          _Stat(icon: Icons.thumb_up_outlined, value: image.likes),
                          _Stat(icon: Icons.chat_bubble_outline, value: image.comments),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _downloading
                        ? _DownloadProgress(
                            progress: _progress!,
                            onCancel: () => _cancelToken?.cancel(),
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _download,
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(compactNumber(value), style: theme.textTheme.labelLarge),
      ],
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.progress, required this.onCancel});

  final double progress;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).clamp(0, 100).round();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null,
                  minHeight: 10,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('$percent%'),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
      ],
    );
  }
}

class _FullScreenViewer extends StatelessWidget {
  const _FullScreenViewer({required this.image});

  final PixabayImage image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        minScale: 1,
        maxScale: 5,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: image.largeImageUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
