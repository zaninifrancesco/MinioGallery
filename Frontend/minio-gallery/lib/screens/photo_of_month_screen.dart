import 'package:flutter/material.dart';
import 'package:minio_gallery/models/gallery_response.dart';
import 'package:provider/provider.dart';
import '../models/image_metadata.dart';
import '../services/image_service.dart';
import '../widgets/like_button.dart';
import 'image_detail_screen.dart';

class PhotoOfMonthScreen extends StatefulWidget {
  const PhotoOfMonthScreen({super.key});

  @override
  State<PhotoOfMonthScreen> createState() => _PhotoOfMonthScreenState();
}

class _PhotoOfMonthScreenState extends State<PhotoOfMonthScreen> {
  final ImageService _imageService = ImageService();
  ImageMetadata? _photoOfMonth;
  List<ImageMetadata> _leaderboard = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final photoFuture = _imageService.getPhotoOfMonth(
        year: _selectedYear,
        month: _selectedMonth,
      );
      final leaderboardFuture = _imageService.getMonthlyLeaderboard(
        year: _selectedYear,
        month: _selectedMonth,
        limit: 10,
      );

      final results = await Future.wait([photoFuture, leaderboardFuture]);

      setState(() {
        _photoOfMonth = results[0] as ImageMetadata?;
        _leaderboard = (results[1] as GalleryResponse?)?.content ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data: $e';
        _isLoading = false;
      });
    }
  }

  void _showMonthYearPicker() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Month & Year'),
            content: SizedBox(
              width: 300,
              height: 200,
              child: Column(
                children: [
                  // Year Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Year:'),
                      DropdownButton<int>(
                        value: _selectedYear,
                        items: List.generate(5, (index) {
                          final year = DateTime.now().year - index;
                          return DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _selectedYear = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Month Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Month:'),
                      DropdownButton<int>(
                        value: _selectedMonth,
                        items: List.generate(12, (index) {
                          final month = index + 1;
                          return DropdownMenuItem(
                            value: month,
                            child: Text(_monthNames[index]),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _selectedMonth = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadData();
                },
                child: const Text('Apply'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_monthNames[_selectedMonth - 1]} $_selectedYear'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _showMonthYearPicker,
            tooltip: 'Select Month',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _loadData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo of the Month Section
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.emoji_events,
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Photo of the Month',
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
                                ],
                              ),
                            ),
                            if (_photoOfMonth != null)
                              _buildPhotoOfMonthCard(_photoOfMonth!)
                            else
                              Container(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.photo_camera_outlined,
                                        size: 64,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No photo of the month yet',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Start uploading and liking photos!',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.copyWith(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Leaderboard Section
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.leaderboard,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Monthly Leaderboard',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (_leaderboard.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.emoji_events_outlined,
                                          size: 48,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No photos this month',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children:
                                      _leaderboard.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final image = entry.value;
                                        return _buildLeaderboardItem(
                                          image,
                                          index + 1,
                                        );
                                      }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildPhotoOfMonthCard(ImageMetadata image) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageDetailScreen(image: image),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
            ),
            child: Image.network(
              image.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 48),
                      SizedBox(height: 8),
                      Text('Image not available'),
                    ],
                  ),
                );
              },
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  image.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (image.uploaderUsername != null)
                  Row(
                    children: [
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'by ${image.uploaderUsername}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    LikeButton(
                      imageId: image.id,
                      initialLikeCount: image.likeCount,
                      initialIsLiked: image.isLikedByCurrentUser,
                    ),
                    Text(
                      '🏆 Winner',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(ImageMetadata image, int position) {
    final isTop3 = position <= 3;
    final positionColor =
        position == 1
            ? Colors.amber[700]
            : position == 2
            ? Colors.grey[600]
            : position == 3
            ? Colors.brown[600]
            : Theme.of(context).colorScheme.onSurfaceVariant;

    final positionIcon =
        position == 1
            ? Icons.emoji_events
            : position == 2
            ? Icons.military_tech
            : position == 3
            ? Icons.workspace_premium
            : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isTop3 ? 2 : 1,
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color:
                    isTop3
                        ? positionColor?.withOpacity(0.1)
                        : Colors.transparent,
                shape: BoxShape.circle,
                border:
                    isTop3 ? Border.all(color: positionColor!, width: 2) : null,
              ),
              child: Center(
                child:
                    positionIcon != null
                        ? Icon(positionIcon, color: positionColor, size: 18)
                        : Text(
                          '$position',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: positionColor,
                          ),
                        ),
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                image.imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Icon(Icons.broken_image, size: 24),
                  );
                },
              ),
            ),
          ],
        ),
        title: Text(
          image.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle:
            image.uploaderUsername != null
                ? Text('by ${image.uploaderUsername}')
                : null,
        trailing: LikeButton(
          imageId: image.id,
          initialLikeCount: image.likeCount,
          initialIsLiked: image.isLikedByCurrentUser,
          isCompact: true,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageDetailScreen(image: image),
            ),
          );
        },
      ),
    );
  }
}
