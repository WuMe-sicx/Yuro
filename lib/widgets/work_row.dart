import 'package:flutter/material.dart';
import 'package:asmrapp/data/models/works/work.dart';
import 'package:asmrapp/widgets/work_card/work_card.dart';

class WorkRow extends StatelessWidget {
  final List<Work> works;
  final void Function(Work work)? onWorkTap;
  final double spacing;

  const WorkRow({
    super.key,
    required this.works,
    this.onWorkTap,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 第一个卡片
        Expanded(
          child: works.isNotEmpty
              ? WorkCard(
                  work: works[0],
                  onTap: onWorkTap != null ? () => onWorkTap!(works[0]) : null,
                )
              : const SizedBox.shrink(),
        ),
        SizedBox(width: spacing),
        // 第二个卡片或占位符
        Expanded(
          child: works.length > 1
              ? WorkCard(
                  work: works[1],
                  onTap: onWorkTap != null ? () => onWorkTap!(works[1]) : null,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
