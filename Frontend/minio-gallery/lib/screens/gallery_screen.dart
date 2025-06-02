import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../models/image_metadata.dart';
import 'image_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchTags = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Carica immagini all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadGallery(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Carica più immagini quando si è vicini alla fine
      context.read<GalleryProvider>().loadMoreImages();
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final tags = query.split(',').map((tag) => tag.trim()).toList();
      setState(() {
        _searchTags = tags;
      });
      context.read<GalleryProvider>().searchByTags(tags);
    } else {
      setState(() {
        _searchTags = [];
      });
      context.read<GalleryProvider>().loadGallery(refresh: true);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchTags = [];
    });
    context.read<GalleryProvider>().loadGallery(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<GalleryProvider>().loadGallery(refresh: true);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by tags (comma separated)',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon:
                          _searchTags.isNotEmpty
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                              )
                              : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _onSearch, child: const Text('Search')),
              ],
            ),
          ),

          // Search Tags Display
          if (_searchTags.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children:
                    _searchTags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _searchTags.remove(tag);
                              });
                              if (_searchTags.isEmpty) {
                                _clearSearch();
                              } else {
                                _searchController.text = _searchTags.join(', ');
                                _onSearch();
                              }
                            },
                          ),
                        )
                        .toList(),
              ),
            ),

          if (_searchTags.isNotEmpty) const SizedBox(height: 16),

          // Gallery Grid
          Expanded(
            child: Consumer<GalleryProvider>(
              builder: (context, galleryProvider, child) {
                if (galleryProvider.images.isEmpty &&
                    galleryProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading gallery...'),
                      ],
                    ),
                  );
                }

                if (galleryProvider.images.isEmpty &&
                    !galleryProvider.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchTags.isNotEmpty
                              ? 'No images found for these tags'
                              : 'No images yet',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchTags.isNotEmpty
                              ? 'Try different search terms'
                              : 'Upload your first photo to get started',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => galleryProvider.loadGallery(refresh: true),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // Aumentato da 2 a 3 colonne
                          crossAxisSpacing: 8, // Ridotto lo spazio
                          mainAxisSpacing: 8, // Ridotto lo spazio
                          childAspectRatio: 1.0, // Fatto più quadrato (era 0.8)
                        ),
                    itemCount:
                        galleryProvider.images.length +
                        (galleryProvider.hasMoreImages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= galleryProvider.images.length) {
                        // Loading indicator per paginazione
                        return const Center(child: CircularProgressIndicator());
                      }

                      final image = galleryProvider.images[index];
                      return _buildImageCard(context, image);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, ImageMetadata image) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ImageDetailScreen(image: image),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 4, // Aumentato da 3 a 4 per dare più spazio all'immagine
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Image.network(
                  image.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 32),
                          SizedBox(height: 4),
                          Text(
                            'Image not available',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 1, // Ridotto da 2 a 1 per meno spazio all'info
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Ridotto da 12 a 8
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      image.title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        // Cambiato da titleSmall
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Ridotto da 4 a 2
                    Expanded(
                      // Aggiunto Expanded per gestire meglio lo spazio
                      child: Text(
                        image.description,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          // Cambiato da bodySmall
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1, // Ridotto da 2 a 1 linea
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (image.tags.isNotEmpty)
                      Wrap(
                        spacing: 2, // Ridotto da 4 a 2
                        children:
                            image.tags
                                .take(2)
                                .map(
                                  (tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4, // Ridotto da 6 a 4
                                      vertical: 1, // Ridotto da 2 a 1
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(
                                        6,
                                      ), // Ridotto da 8 a 6
                                    ),
                                    child: Text(
                                      tag,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall?.copyWith(
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                        fontSize: 10, // Ridotto il font size
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
