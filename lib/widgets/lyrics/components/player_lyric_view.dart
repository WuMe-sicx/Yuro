import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:asmrapp/core/subtitle/i_subtitle_service.dart';
import 'package:asmrapp/core/audio/models/subtitle.dart';
import 'lyric_line.dart';
import 'package:asmrapp/presentation/viewmodels/player_viewmodel.dart';

class PlayerLyricView extends StatefulWidget {
  final bool immediateScroll;
  final Function(bool canSwitch) onScrollStateChanged;

  const PlayerLyricView({
    super.key,
    this.immediateScroll = false,
    required this.onScrollStateChanged,
  });

  @override
  State<PlayerLyricView> createState() => _PlayerLyricViewState();
}

class _PlayerLyricViewState extends State<PlayerLyricView> {
  final ISubtitleService _subtitleService = GetIt.I<ISubtitleService>();
  final PlayerViewModel _viewModel = GetIt.I<PlayerViewModel>();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  
  bool _isFirstBuild = true;
  Subtitle? _lastScrolledSubtitle;
  
  // 用于控制视图切换的计时器和状态
  // 当用户手动滚动时，暂时禁用视图切换功能，防止切换到封面
  Timer? _scrollDebounceTimer;
  
  // 用于控制自动滚动的计时器和状态
  // 当用户手动滚动时，暂时禁用自动滚动功能，让用户可以自由浏览歌词
  bool _allowAutoScroll = true;
  Timer? _autoScrollDebounceTimer;

  StreamSubscription? _subtitleSubscription;

  @override
  void initState() {
    super.initState();
    _subtitleSubscription = _subtitleService.currentSubtitleWithStateStream.listen((current) {
      if (current != null && _itemScrollController.isAttached) {
        _scrollToCurrentLyric(current);
      }
    });
    // Handle initial positioning after first frame when controller is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = _subtitleService.currentSubtitleWithState;
      if (current != null && _itemScrollController.isAttached) {
        _scrollToCurrentLyric(current);
      }
    });
  }

  @override
  void dispose() {
    _subtitleSubscription?.cancel();
    _scrollDebounceTimer?.cancel();
    _autoScrollDebounceTimer?.cancel();
    super.dispose();
  }

  void _scrollToCurrentLyric(SubtitleWithState current) {
    if (!_itemScrollController.isAttached) return;
    
    // 如果当前禁用了自动滚动（用户正在手动浏览），则不执行自动滚动
    if (!_allowAutoScroll) return;
    
    // 避免重复滚动到同一句歌词
    if (_lastScrolledSubtitle == current.subtitle) return;
    _lastScrolledSubtitle = current.subtitle;
    
    if (_isFirstBuild) {
      _isFirstBuild = false;
      // 首次加载时直接跳转，不使用动画
      _itemScrollController.jumpTo(
        index: current.subtitle.index,
        alignment: 0.5,
      );
    } else {
      // 正常播放时使用平滑滚动动画
      _itemScrollController.scrollTo(
        index: current.subtitle.index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuart,
        alignment: 0.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final baseUnit = screenHeight * 0.04;
    
    return StreamBuilder<SubtitleWithState?>(
      stream: _subtitleService.currentSubtitleWithStateStream,
      initialData: _subtitleService.currentSubtitleWithState,
      builder: (context, snapshot) {
        final currentSubtitle = snapshot.data;
        final subtitleList = _subtitleService.subtitleList;

        if (subtitleList == null || subtitleList.subtitles.isEmpty) {
          return const Center(
            child: Text('无歌词'),
          );
        }

        // Scrolling is handled by the stream listener in initState - no side effects here

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification && 
                notification.dragDetails != null) {  // 用户开始手动滚动
              // 立即禁用视图切换功能
              widget.onScrollStateChanged(false);
              
              // 禁用自动滚动功能
              _allowAutoScroll = false;
              
              // 取消所有待执行的计时器
              _scrollDebounceTimer?.cancel();
              _autoScrollDebounceTimer?.cancel();
            } else if (notification is ScrollEndNotification) {  // 用户结束滚动
              // 延长视图切换的禁用时间到1秒
              _scrollDebounceTimer?.cancel();
              _scrollDebounceTimer = Timer(const Duration(milliseconds: 1000), () {
                if (mounted) {
                  widget.onScrollStateChanged(true);
                }
              });
              
              // 自动滚动计时器保持3秒
              _autoScrollDebounceTimer?.cancel();
              _autoScrollDebounceTimer = Timer(const Duration(milliseconds: 3000), () {
                if (mounted) {
                  _allowAutoScroll = true;
                  if (_subtitleService.currentSubtitleWithState != null) {
                    _scrollToCurrentLyric(_subtitleService.currentSubtitleWithState!);
                  }
                }
              });
            }
            return false;
          },
          child: ScrollablePositionedList.builder(
            itemCount: subtitleList.subtitles.length,
            itemScrollController: _itemScrollController,
            itemPositionsListener: _itemPositionsListener,
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.3,
              horizontal: baseUnit * 0.8,
            ),
            itemBuilder: (context, index) {
              final subtitle = subtitleList.subtitles[index];
              final isActive = currentSubtitle?.subtitle == subtitle;
              
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: baseUnit * 0.35,
                ),
                child: LyricLine(
                  subtitle: subtitle,
                  isActive: isActive,
                  opacity: isActive ? 1.0 : 0.5,
                  onTap: () async {
                    widget.onScrollStateChanged(false);
                    
                    await _viewModel.seek(subtitle.start);
                    
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        widget.onScrollStateChanged(true);
                      }
                    });
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
} 