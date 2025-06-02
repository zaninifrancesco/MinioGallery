import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gallery_provider.dart';
import '../models/image_metadata.dart';
import 'image_detail_screen.dart';
import '../providers/auth_provider.dart'; // Aggiunto AuthProvider

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isOwner = authProvider.user?.username == image.uploaderUsername;

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
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 4,
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
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          image.title,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Expanded(
                          child: Text(
                            image.description,
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (image.tags.isNotEmpty)
                          Wrap(
                            spacing: 2,
                            children:
                                image.tags
                                    .take(2)
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
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
                                                Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                            fontSize:
                                                10, // Ridotto il font size
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
            if (isOwner)
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  // Aggiunto Material per InkWell e visualizzazione corretta del ripple
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red[700]),
                    onPressed: () => _showDeleteDialog(context, image),
                    tooltip: 'Delete Image',
                    splashRadius: 20, // Raggio dello splash effect
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    ImageMetadata image,
  ) async {
    final galleryProvider = Provider.of<GalleryProvider>(
      context,
      listen: false,
    );
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            // Usato dialogContext per chiarezza
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Image'),
            content: Text(
              'Are you sure you want to delete "${image.title}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (shouldDelete == true) {
      // Mostra un indicatore di caricamento MODALE per bloccare l'UI
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        barrierDismissible: false, // Impedisce la chiusura toccando fuori
        builder:
            (dialogContext) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 24),
                  Text('Deleting image...'),
                ],
              ),
            ),
      );

      final success = await galleryProvider.deleteImage(image.id);

      // Chiudi il dialogo di caricamento modale
      // ignore: use_build_context_synchronously
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${image.title}" deleted successfully.'),
              backgroundColor: Colors.green,
            ),
          );
          // La galleria si aggiornerà automaticamente grazie al notifyListeners() in deleteImage
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                galleryProvider.errorMessage ?? 'Failed to delete image.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
