import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:asmrapp/core/theme/app_animations.dart';

class SidebarTile extends StatefulWidget {
  const SidebarTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.title,
    required this.onTap,
    this.showSeparator = true,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String title;
  final VoidCallback onTap;
  final bool showSeparator;

  @override
  State<SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<SidebarTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: widget.title,
      child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: AppAnimations.micro,
        color: _isPressed
            ? colorScheme.onSurface.withValues(alpha: 0.06)
            : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 11),
                child: Row(
                  children: [
                    // Colored icon square
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: widget.iconBackgroundColor,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
              if (widget.showSeparator)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  // Inset starts after leading area: 30(icon) + 12(gap) = 42
                  indent: 42,
                  endIndent: 0,
                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                ),
            ],
          ),
        ),
      ),
    ));
  }
}
