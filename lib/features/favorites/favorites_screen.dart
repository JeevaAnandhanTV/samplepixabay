import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../detail/detail_screen.dart';
import '../gallery/presentation/widgets/image_tile.dart';
import 'favorites_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  int _columns(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoritesController>();
    final items = favorites.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: items.isEmpty
          ? const _EmptyFavorites()
          : LayoutBuilder(
              builder: (context, constraints) => MasonryGridView.count(
                padding: const EdgeInsets.all(12),
                crossAxisCount: _columns(constraints.maxWidth),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final image = items[index];
                  return ImageTile(
                    key: ValueKey('fav_${image.id}'),
                    image: image,
                    heroPrefix: 'favorites',
                    onTap: () => openDetail(context, image, 'favorites'),
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 72, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No favorites yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap the heart on any image to save it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
