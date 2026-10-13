import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../gallery/data/models/pixabay_image.dart';
import '../gallery/data/pixabay_api_client.dart';
import '../gallery/presentation/gallery_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PixabayApiClient _apiClient = PixabayApiClient();
  List<PixabayImage> _trendingImages = [];
  List<PixabayImage> _categoryImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final trending = await _apiClient.fetchImages(
        page: 1,
        perPage: 4,
        query: 'trending',
      );
      final category = await _apiClient.fetchImages(
        page: 1,
        perPage: 6,
        category: 'nature',
      );
      
      if (mounted) {
        setState(() {
          _trendingImages = trending.images;
          _categoryImages = category.images;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Trending section
          _buildSectionHeader('Trending', context),
          const SizedBox(height: 12),
          _buildTrendingGrid(scheme),
          const SizedBox(height: 24),
          // Categories section
          _buildSectionHeader('Categories', context),
          const SizedBox(height: 12),
          _buildCategoryGrid(scheme),
          const SizedBox(height: 24),
          // Popular collections
          _buildSectionHeader('Popular Collections', context),
          const SizedBox(height: 12),
          _buildCollectionsList(scheme),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTrendingGrid(ColorScheme scheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _trendingImages.length,
      itemBuilder: (context, index) {
        final image = _trendingImages[index];
        return GestureDetector(
          onTap: () => _navigateToGallery('trending'),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: image.webformatUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: scheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: scheme.surfaceContainerHighest,
                child: const Icon(Icons.error),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryGrid(ColorScheme scheme) {
    final categories = [
      {'icon': Icons.nature, 'name': 'Nature', 'color': Colors.green, 'query': 'nature'},
      {'icon': Icons.pets, 'name': 'Animals', 'color': Colors.orange, 'query': 'animals'},
      {'icon': Icons.landscape, 'name': 'Travel', 'color': Colors.blue, 'query': 'travel'},
      {'icon': Icons.location_city, 'name': 'Architecture', 'color': Colors.purple, 'query': 'buildings'},
      {'icon': Icons.restaurant, 'name': 'Food', 'color': Colors.red, 'query': 'food'},
      {'icon': Icons.sports_soccer, 'name': 'Sports', 'color': Colors.teal, 'query': 'sports'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () => _navigateToGallery(category['query'] as String),
          child: Container(
            decoration: BoxDecoration(
              color: category['color'] as Color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 40,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCollectionsList(ColorScheme scheme) {
    final collections = [
      {'name': 'Best of 2024', 'query': '2024'},
      {'name': 'Photography Tips', 'query': 'photography'},
      {'name': 'Minimalist Design', 'query': 'minimalist'},
      {'name': 'Nature Photography', 'query': 'nature photography'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final collection = collections[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.collections,
                color: Colors.white,
              ),
            ),
            title: Text(collection['name'] as String),
            subtitle: const Text('Curated collection'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _navigateToGallery(collection['query'] as String),
          ),
        );
      },
    );
  }

  void _navigateToGallery(String query) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GalleryScreen(initialQuery: query),
      ),
    );
  }
}
