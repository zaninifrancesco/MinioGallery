import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/like_service.dart';

class LikeButton extends StatefulWidget {
  final String imageId;
  final int initialLikeCount;
  final bool initialIsLiked;
  final Function(bool liked, int newCount)? onLikeChanged;
  final bool isCompact;
  final Color? iconColor;

  const LikeButton({
    super.key,
    required this.imageId,
    required this.initialLikeCount,
    required this.initialIsLiked,
    this.onLikeChanged,
    this.isCompact = false,
    this.iconColor,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with TickerProviderStateMixin {
  late bool isLiked;
  late int likeCount;
  late AnimationController _animationController;
  final LikeService _likeService = LikeService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    isLiked = widget.initialIsLiked;
    likeCount = widget.initialLikeCount;
    print(
      'LikeButton init - imageId: ${widget.imageId}, initialIsLiked: ${widget.initialIsLiked}, initialLikeCount: ${widget.initialLikeCount}',
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    print(
      '_toggleLike called - current state: isLiked=$isLiked, likeCount=$likeCount',
    );

    setState(() {
      _isLoading = true;
    });

    // Animazione
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    // Ottimistic update
    final previousLiked = isLiked;
    final previousCount = likeCount;

    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    print(
      'After optimistic update: isLiked=$isLiked, likeCount=$likeCount (was: $previousLiked, $previousCount)',
    );

    // API call
    print('Calling toggleLike API for imageId: ${widget.imageId}');
    final success = await _likeService.toggleLike(widget.imageId);
    print('toggleLike API result: $success');

    if (!success) {
      // Rollback se fallisce
      setState(() {
        isLiked = previousLiked;
        likeCount = previousCount;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${previousLiked ? 'unlike' : 'like'} image',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else if (widget.onLikeChanged != null) {
      widget.onLikeChanged!(isLiked, likeCount);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return InkWell(
        onTap: _toggleLike,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: Tween(
                  begin: 1.0,
                  end: 1.3,
                ).animate(_animationController),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color:
                      isLiked
                          ? Colors.red
                          : widget.iconColor ??
                              Theme.of(context).colorScheme.onSurface,
                  size: 16,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$likeCount',
                style: TextStyle(
                  color:
                      widget.iconColor ??
                      Theme.of(context).colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.3).animate(_animationController),
          child: IconButton(
            onPressed: _isLoading ? null : _toggleLike,
            icon:
                _isLoading
                    ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                    : Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : null,
                    ),
          ),
        ),
        Text('$likeCount', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
