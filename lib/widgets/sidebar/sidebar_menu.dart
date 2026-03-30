import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asmrapp/common/constants/strings.dart';
import 'package:asmrapp/presentation/viewmodels/auth_viewmodel.dart';
import 'package:asmrapp/presentation/widgets/auth/login_dialog.dart';
import 'package:asmrapp/screens/favorites_screen.dart';
import 'package:asmrapp/screens/browse/tags_screen.dart';
import 'package:asmrapp/screens/browse/circles_screen.dart';
import 'package:asmrapp/screens/browse/voice_actors_screen.dart';
import 'package:asmrapp/screens/settings/settings_screen.dart';
import 'package:asmrapp/widgets/sidebar/sidebar_header.dart';
import 'package:asmrapp/widgets/sidebar/sidebar_group.dart';
import 'package:asmrapp/widgets/sidebar/sidebar_tile.dart';

class SidebarMenu extends StatelessWidget {
  const SidebarMenu({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => screen),
    );
  }

  void _navigateToFavorites(BuildContext context) {
    final authVM = context.read<AuthViewModel>();
    Navigator.pop(context); // close drawer first
    if (!authVM.isLoggedIn) {
      showDialog(
        context: context,
        builder: (_) => const LoginDialog(),
      );
      return;
    }
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SidebarHeader(),
              const SizedBox(height: 24),

              // 资料库
              SidebarGroup(
                header: '资料库',
                children: [
                  SidebarTile(
                    icon: CupertinoIcons.heart_fill,
                    iconColor: Colors.white,
                    iconBackgroundColor: const Color(0xFFFF3B30),
                    title: Strings.favorites,
                    onTap: () => _navigateToFavorites(context),
                    showSeparator: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 探索
              SidebarGroup(
                header: '探索',
                children: [
                  SidebarTile(
                    icon: CupertinoIcons.tag_fill,
                    iconColor: Colors.white,
                    iconBackgroundColor: const Color(0xFF007AFF),
                    title: '标签',
                    onTap: () => _navigate(context, const TagsScreen()),
                  ),
                  SidebarTile(
                    icon: Icons.group,
                    iconColor: Colors.white,
                    iconBackgroundColor: const Color(0xFF34C759),
                    title: '社团',
                    onTap: () => _navigate(context, const CirclesScreen()),
                  ),
                  SidebarTile(
                    icon: CupertinoIcons.mic_fill,
                    iconColor: Colors.white,
                    iconBackgroundColor: const Color(0xFFFF9500),
                    title: '声优',
                    onTap: () => _navigate(context, const VoiceActorsScreen()),
                    showSeparator: false,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 系统
              SidebarGroup(
                header: '系统',
                children: [
                  SidebarTile(
                    icon: CupertinoIcons.settings,
                    iconColor: Colors.white,
                    iconBackgroundColor: const Color(0xFF8E8E93),
                    title: Strings.settings,
                    onTap: () => _navigate(context, const SettingsScreen()),
                    showSeparator: false,
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Footer
              Center(
                child: Text(
                  'Yuro v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.35),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
