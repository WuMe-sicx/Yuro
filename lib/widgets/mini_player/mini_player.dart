import 'package:asmrapp/core/theme/app_animations.dart';
import 'package:asmrapp/screens/player_screen.dart';
import 'package:flutter/material.dart';
import 'package:asmrapp/presentation/viewmodels/player_viewmodel.dart';
import 'mini_player_controls.dart';
import 'mini_player_progress.dart';
import 'package:get_it/get_it.dart';
import 'mini_player_cover.dart';

class MiniPlayer extends StatelessWidget {
  static const height = 48.0;
  static const _boxShadow = [
    BoxShadow(
      color: Color(0x1A000000), // Colors.black at 10% opacity
      blurRadius: 4,
      offset: Offset(0, -1),
    ),
  ];

  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = GetIt.I<PlayerViewModel>();
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) {
                  return const PlayerScreen();
                },
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  // 创建一个曲线动画
                  final curvedAnimation = CurvedAnimation(
                    parent: animation,
                    curve: AppAnimations.smoothScroll,
                  );
                  
                  return Stack(
                    children: [
                      // 背景淡入效果
                      FadeTransition(
                        opacity: curvedAnimation,
                        child: Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                      // 内容从底部滑入并淡入
                      FadeTransition(
                        opacity: Tween<double>(
                          begin: 0.3,
                          end: 1.0,
                        ).animate(curvedAnimation),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(curvedAnimation),
                          child: child,
                        ),
                      ),
                    ],
                  );
                },
                transitionDuration: AppAnimations.long,
              ),
            );
          },
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: _boxShadow,
            ),
            child: Column(
              children: [
                const MiniPlayerProgress(),
                Expanded(
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                        child: Hero(
                          tag: 'mini-player-cover',
                          child: MiniPlayerCover(
                            coverUrl: viewModel.currentTrackInfo?.coverUrl,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Hero(
                            tag: 'player-title',
                            child: Material(
                              color: Colors.transparent,
                              child: Text(
                                viewModel.currentTrackInfo?.title ?? '未在播放',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const MiniPlayerControls(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
