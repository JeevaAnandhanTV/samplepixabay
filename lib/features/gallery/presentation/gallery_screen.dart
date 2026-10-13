import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../../core/controllers/notification_controller.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/format.dart';
import '../../detail/detail_screen.dart';
import '../../explore/explore_screen.dart';
import '../../favorites/favorites_controller.dart';
import '../../favorites/favorites_screen.dart';
import '../../notifications/notification_screen.dart';
import '../../profile/profile_screen.dart';
import '../../upload/upload_screen.dart';
import 'gallery_controller.dart';
import 'widgets/error_view.dart';
import 'widgets/image_tile.dart';
import 'widgets/skeleton_grid.dart';

const _categories = <String>[
  'nature',
  'animals',
  'travel',
  'places',
  'buildings',
  'food',
  'backgrounds',
  'science',
  'sports',
  'people',
  'fashion',
  'music',
  'business',
];

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _masonry = true;

  static const _loadMoreThreshold = 800.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    
    // Set initial query if provided
    if (widget.initialQuery != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GalleryController>().setQuery(widget.initialQuery!);
        _searchController.text = widget.initialQuery!;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  int _columns(double width) {
    if (width < 600) return 2;
    if (width < 900) return 3;
    if (width < 1200) return 4;
    return 5;
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.extentAfter < _loadMoreThreshold) {
      context.read<GalleryController>().loadMore();
    }
  }

  /// On tall/wide screens the first page may not fill the viewport, which
  /// would leave no scroll event to trigger pagination. Check after layout.
  void _scheduleFillCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final controller = context.read<GalleryController>();
      if (controller.loadMoreError != null) return;
      final position = _scroll.position;
      if (position.maxScrollExtent <= 0 ||
          position.extentAfter < _loadMoreThreshold) {
        controller.loadMore();
      }
    });
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (mounted) context.read<GalleryController>().setQuery(value);
    });
    setState(() {}); // refresh clear button visibility
  }

  Future<void> _onRefresh() async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await context.read<GalleryController>().refresh();
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _scrollToTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GalleryController>();
    final favoritesCount =
        context.select<FavoritesController, int>((c) => c.count);
    final themeMode = context.select<ThemeController, ThemeMode>((c) => c.mode);
    final notificationCount =
        context.select<NotificationController, int>((c) => c.unreadCount);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            elevation: 0,
            backgroundColor: scheme.surface,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      scheme.primary.withOpacity(0.1),
                      scheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.photo_library_outlined, color: scheme.primary, size: 32),
                            const SizedBox(width: 8),
                            Text(
                              'Infinite Gallery',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Explore',
                              icon: const Icon(Icons.explore_outlined),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const ExploreScreen()),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Profile',
                              icon: const Icon(Icons.account_circle_outlined),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: _masonry ? 'Uniform grid' : 'Masonry grid',
                              icon: Icon(_masonry ? Icons.grid_view_rounded : Icons.dashboard_outlined),
                              onPressed: () => setState(() => _masonry = !_masonry),
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.upload_outlined,
                              label: 'Upload',
                              color: scheme.primary,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const UploadScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(Icons.search, color: scheme.onSurfaceVariant, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search images...',
                                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onChanged: _onSearchChanged,
                                onSubmitted: (v) {
                                  _debounce?.cancel();
                                  context.read<GalleryController>().setQuery(v);
                                },
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  _debounce?.cancel();
                                  context.read<GalleryController>().setQuery('');
                                  setState(() {});
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const NotificationScreen(),
                              ),
                            );
                          },
                        ),
                        if (notificationCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: scheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                '$notificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.favorite_border),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
                          ),
                        ),
                        if (favoritesCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: scheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                '$favoritesCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        switch (themeMode) {
                          ThemeMode.system => Icons.brightness_auto_outlined,
                          ThemeMode.light => Icons.light_mode_outlined,
                          ThemeMode.dark => Icons.dark_mode_outlined,
                        },
                      ),
                      onPressed: () => context.read<ThemeController>().cycle(),
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = index == 0 ? null : _categories[index - 1];
                  return ChoiceChip(
                    label: Text(value == null ? 'All' : capitalize(value)),
                    selected: controller.category == value,
                    onSelected: (_) {
                      _scrollToTop();
                      controller.setCategory(value);
                    },
                  );
                },
              ),
            ),
          ),
          SliverFillRemaining(
            child: _buildBody(controller),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(GalleryController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columns(constraints.maxWidth);
        switch (controller.status) {
          case GalleryStatus.loading:
            return SkeletonGrid(columns: columns);
          case GalleryStatus.failure:
            return ErrorView(
              error: controller.error!,
              onRetry: controller.loadInitial,
            );
          case GalleryStatus.success:
            if (controller.items.isEmpty) {
              return _EmptyResults(query: controller.query);
            }
            _scheduleFillCheck();
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: _buildGrid(controller, columns),
            );
        }
      },
    );
  }

  Widget _buildGrid(GalleryController controller, int columns) {
    final items = controller.items;

    Widget tile(int index) {
      final image = items[index];
      return ImageTile(
        key: ValueKey(image.id),
        image: image,
        heroPrefix: 'gallery',
        onTap: () => openDetail(context, image, 'gallery'),
      );
    }

    return CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          sliver: _masonry
              ? SliverMasonryGrid.count(
                  crossAxisCount: columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childCount: items.length,
                  itemBuilder: (context, index) => tile(index),
                )
              : SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => tile(index),
                ),
        ),
        SliverToBoxAdapter(child: _Footer(controller: controller)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final GalleryController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget child;
    if (controller.isLoadingMore) {
      child = const SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    } else if (controller.loadMoreError != null) {
      final AppException error = controller.loadMoreError!;
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(error.message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: controller.retryLoadMore,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      );
    } else if (!controller.hasMore) {
      child = Text(
        "You've reached the end",
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    } else {
      child = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(child: child),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search, size: 72, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('No images found', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              query.isEmpty
                  ? 'Try another category.'
                  : 'Nothing matched "$query". Try a different keyword.',
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
