import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:asmrapp/widgets/common/skeleton_pulse.dart';
import 'package:asmrapp/core/image/cache/image_cache_manager.dart';

class WorkCoverImage extends StatelessWidget {
  final String imageUrl;
  final int workId;
  final String sourceId;
  // 195/146 ≈ 1.336
  static const double _aspectRatio = 195 / 146;

  const WorkCoverImage({
    super.key,
    required this.imageUrl,
    required this.workId,
    required this.sourceId,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: Stack(
        children: [
          Hero(
            tag: 'work-cover-$workId',
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              cacheManager: ImageCacheManager.instance,
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
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sourceId,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
