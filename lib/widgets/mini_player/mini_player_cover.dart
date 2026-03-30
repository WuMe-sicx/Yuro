import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:asmrapp/widgets/common/skeleton_pulse.dart';
import 'package:asmrapp/core/image/cache/image_cache_manager.dart';

class MiniPlayerCover extends StatelessWidget {
  final String? coverUrl;
  final double size;

  const MiniPlayerCover({
    super.key,
    this.coverUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null) {
      return _buildEmptyPlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: coverUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheManager: ImageCacheManager.instance,
        placeholder: (context, url) => _buildPlaceholder(context),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.music_note, color: Colors.grey),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return SkeletonPulse(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  }
}
