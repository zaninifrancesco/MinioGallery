import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/gallery_provider.dart';
import '../models/image_metadata.dart';
import 'profile_screen.dart';
import 'image_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Se si naviga alla Gallery tab (index 1), carica sempre la galleria globale
    if (index == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<GalleryProvider>().loadGlobalGallery(refresh: true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          DashboardTab(onNavigateToTab: _navigateToTab),
          const GalleryTab(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });

          // Se si naviga alla Gallery tab (index 1), carica sempre la galleria globale
          if (index == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<GalleryProvider>().loadGlobalGallery(refresh: true);
            });
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final Function(int)? onNavigateToTab;

  const DashboardTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.waving_hand,
                              size: 32,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Welcome back, ${user?.username ?? 'User'}!',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ready to manage your photo collection?',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'Upload Photos',
                        'Add new images to your gallery',
                        Icons.cloud_upload_outlined,
                        () {
                          // Navigate to upload screen
                          Navigator.pushNamed(context, '/upload');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        context,
                        'View Gallery',
                        'Browse your photo collection',
                        Icons.photo_library_outlined,
                        () {
                          // Switch to gallery tab
                          if (onNavigateToTab != null) {
                            onNavigateToTab!(1);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Statistics Card (placeholder)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Your Gallery Stats',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(context, '0', 'Photos'),
                            _buildStatItem(context, '0', 'Albums'),
                            _buildStatItem(context, '0 MB', 'Storage'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class GalleryTab extends StatefulWidget {
  const GalleryTab({super.key});

  @override
  State<GalleryTab> createState() => _GalleryTabState();
}

class _GalleryTabState extends State<GalleryTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchTags = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Carica immagini globali all'avvio
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GalleryProvider>().loadGlobalGallery(refresh: true);
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
      context.read<GalleryProvider>().loadMoreGlobalImages();
    }
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final tags = query.split(',').map((tag) => tag.trim()).toList();
      setState(() {
        _searchTags = tags;
      });
      context.read<GalleryProvider>().searchGlobalByTags(tags);
    } else {
      setState(() {
        _searchTags = [];
      });
      context.read<GalleryProvider>().loadGlobalGallery(refresh: true);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchTags = [];
    });
    context.read<GalleryProvider>().loadGlobalGallery(refresh: true);
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
              context.read<GalleryProvider>().loadGlobalGallery(refresh: true);
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
                              : 'Users can upload photos to get started',
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
                  onRefresh:
                      () => galleryProvider.loadGlobalGallery(refresh: true),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.0,
                        ),
                    itemCount:
                        galleryProvider.images.length +
                        (galleryProvider.hasMoreImages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= galleryProvider.images.length) {
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageDetailScreen(image: image),
            ),
          );
        },
        child: Stack(
          children: [
            // Full size image
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              child: Image.network(
                image.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
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
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 32),
                      SizedBox(height: 4),
                      Text(
                        'Image not available',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  );
                },
              ),
            ), // Gradient overlay - più compatto
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      image.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18, // Increased from 16 to 18
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (image.uploaderUsername != null) ...[
                          Icon(
                            Icons.person,
                            size: 14,
                            color: Colors.white70,
                          ), // Increased from 12 to 14
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              image.uploaderUsername!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                                fontSize: 12, // Increased from 10 to 12
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (image.tags.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              image.tags
                                  .take(2)
                                  .map(
                                    (tag) => Container(
                                      margin: const EdgeInsets.only(right: 4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.4),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize:
                                              11, // Increased from 9 to 11
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                    ],
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
