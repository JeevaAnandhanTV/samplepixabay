import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/controllers/notification_controller.dart';
import '../../../favorites/favorites_controller.dart';
import '../../data/models/pixabay_image.dart';

/// Grid tile used by both the gallery and favorites screens.
///
/// Performance notes:
///  * `memCacheWidth` decodes the bitmap at the tile's real pixel width
///    instead of the full source resolution (big memory saver).
///  * `CachedNetworkImage` adds a disk cache + fade-in.
///  * Only the heart icon rebuilds on favourite changes (`context.select`).
class ImageTile extends StatelessWidget {
  const ImageTile({
    super.key,
    required this.image,
    required this.heroPrefix,
    required this.onTap,
  });

  final PixabayImage image;
  final String heroPrefix;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: image.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final cacheWidth = constraints.maxWidth.isFinite
                      ? (constraints.maxWidth * dpr).round()
                      : null;
                  return Hero(
                    tag: '${heroPrefix}_${image.id}',
                    child: CachedNetworkImage(
                      imageUrl: image.webformatUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: cacheWidth,
                      fadeInDuration: const Duration(milliseconds: 300),
                      placeholder: (_, __) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: scheme.outline,
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned.fill(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: scheme.primary.withOpacity(0.2),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _FavoriteButton(image: image),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.image});

  final PixabayImage image;

  @override
  Widget build(BuildContext context) {
    final isFavorite = context
        .select<FavoritesController, bool>((c) => c.isFavorite(image.id));
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
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
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? Colors.redAccent : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
