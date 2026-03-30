import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:asmrapp/core/image/cache/image_cache_manager.dart';

class WorkCover extends StatelessWidget {
  final String imageUrl;
  final int workId;
  final String sourceId;
  final String? releaseDate;
  final String? heroTag;


  const WorkCover({
    super.key,
    required this.imageUrl,
    required this.workId,
    required this.sourceId,
    this.releaseDate,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Stack(
      children: [
        AspectRatio(
          aspectRatio: 195 / 146,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            cacheManager: ImageCacheManager.instance,
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
        if (releaseDate != null)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                releaseDate!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
              ),
            ),
          ),
      ],
    );

    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: content,
      );
    }

    return content;
  }
}
