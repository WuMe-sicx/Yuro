import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:asmrapp/widgets/common/skeleton_pulse.dart';

class PlayerCover extends StatelessWidget {
  final String? coverUrl;
  final double? maxWidth;
  
  const PlayerCover({
    super.key,
    this.coverUrl,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4/3,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? 480,
        ),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: coverUrl != null
              ? CachedNetworkImage(
                  imageUrl: coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => SkeletonPulse(
                    child: Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                )
              : const Icon(Icons.music_note, size: 100),
        ),
      ),
    );
  }
} 