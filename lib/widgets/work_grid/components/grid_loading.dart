import 'package:flutter/material.dart';
import 'package:asmrapp/widgets/common/skeleton_pulse.dart';

class GridLoading extends StatelessWidget {
  const GridLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }
} 