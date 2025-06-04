import 'package:flutter/material.dart';
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

    // Verifica automaticamente lo stato del like all'inizializzazione
    // Aggiungi un piccolo delay per permettere al widget di essere completamente inizializzato
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verifyLikeStatus();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Verifica lo stato del like dal server
  Future<void> _verifyLikeStatus() async {
    try {
      print('LikeButton: Verifying like status for imageId: ${widget.imageId}');
      final status = await _likeService.getLikeStatus(widget.imageId);
      final serverIsLiked = status['liked'] as bool;
      final serverLikeCount = status['likeCount'] as int;

      print(
        'LikeButton: Server response - isLiked: $serverIsLiked, likeCount: $serverLikeCount',
      );
      print(
        'LikeButton: Current state - isLiked: $isLiked, likeCount: $likeCount',
      );

      // Aggiorna lo stato sempre per assicurarsi che sia sincronizzato con il server
      if (mounted) {
        setState(() {
          isLiked = serverIsLiked;
          likeCount = serverLikeCount;
        });
        print(
          'LikeButton: Updated status from server - isLiked: $isLiked, likeCount: $likeCount',
        );
      }
    } catch (e) {
      print('Error verifying like status: $e');
      // In caso di errore, mantieni lo stato iniziale
    }
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
              'Failed to ${previousLiked ? 'unlike' : 'like'} image. Please login to like images.',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else {
      // Verifica lo stato reale dal server dopo il toggle
      try {
        final status = await _likeService.getLikeStatus(widget.imageId);
        final actualIsLiked = status['liked'] as bool;
        final actualLikeCount = status['likeCount'] as int;

        setState(() {
          isLiked = actualIsLiked;
          likeCount = actualLikeCount;
        });

        print(
          'Updated state from server after toggle: isLiked=$isLiked, likeCount=$likeCount',
        );

        if (widget.onLikeChanged != null) {
          widget.onLikeChanged!(isLiked, likeCount);
        }
      } catch (e) {
        print('Error getting updated like status: $e');
        // In caso di errore, mantieni lo stato ottimistico
        if (widget.onLikeChanged != null) {
          widget.onLikeChanged!(isLiked, likeCount);
        }
      }
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
                          ? Colors
                              .red[600] // Colore rosso più saturo quando liked
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
                      color:
                          isLiked
                              ? Colors.red[600]
                              : null, // Colore rosso più saturo quando liked
                    ),
          ),
        ),
        Text('$likeCount', style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
