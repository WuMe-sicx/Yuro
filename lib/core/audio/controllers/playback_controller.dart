import 'package:asmrapp/utils/logger.dart';
import 'package:just_audio/just_audio.dart';
import '../models/playback_context.dart';
import '../state/playback_state_manager.dart';
import '../utils/playlist_builder.dart';
import '../utils/audio_error_handler.dart';
import '../events/playback_event_hub.dart';
import '../events/playback_event.dart';
import 'package:asmrapp/data/models/files/child.dart';
import 'package:asmrapp/data/models/works/work.dart';


class PlaybackController {
  final AudioPlayer _player;
  final PlaybackStateManager _stateManager;
  final ConcatenatingAudioSource _playlist;
  final PlaybackEventHub _eventHub;

  PlaybackController({
    required AudioPlayer player,
    required PlaybackStateManager stateManager,
    required ConcatenatingAudioSource playlist,
    required PlaybackEventHub eventHub,
  }) : _player = player,
       _stateManager = stateManager,
       _playlist = playlist,
       _eventHub = eventHub;

  // 基础播放控制
  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position, {int? index}) => _player.seek(position, index: index);
  
  // 播放列表控制
  Future<void> next() async {
    try {
      AppLogger.debug('尝试切换下一曲');
      if (_stateManager.currentContext == null) {
        AppLogger.debug('当前上下文为空，无法切换下一曲');
        return;
      }

      if (_player.hasNext) {
        AppLogger.debug('执行切换到下一曲');
        await _player.seekToNext();
      } else {
        AppLogger.debug('没有下一曲可切换');
      }
    } catch (e, stack) {
      AppLogger.error('切换下一曲失败', e, stack);
      _eventHub.emit(PlaybackErrorEvent('next', e, stack));
      AudioErrorHandler.handleError(
        AudioErrorType.playback,
        '切换下一曲',
        e,
        stack,
      );
    }
  }

  Future<void> previous() async {
    try {
      AppLogger.debug('尝试切换上一曲');
      if (_stateManager.currentContext == null) {
        AppLogger.debug('当前上下文为空，无法切换上一曲');
        return;
      }

      if (_player.hasPrevious) {
        final previousFile = _stateManager.currentContext!.getPreviousFile();
        AppLogger.debug('获取到上一个文件: ${previousFile?.title}');
        if (previousFile != null) {
          _updateTrackAndContext(
            previousFile,
            _stateManager.currentContext!.work
          );
          AppLogger.debug('执行切换到上一曲');
          await _player.seekToPrevious();
        }
      } else {
        AppLogger.debug('没有上一曲可切换');
      }
    } catch (e, stack) {
      AppLogger.error('切换上一曲失败', e, stack);
      _eventHub.emit(PlaybackErrorEvent('previous', e, stack));
      AudioErrorHandler.handleError(
        AudioErrorType.playback,
        '切换上一曲',
        e,
        stack,
      );
    }
  }

  // 播放上下文设置
  Future<void> setPlaybackContext(PlaybackContext originalContext, {Duration? initialPosition}) async {
    try {
      AppLogger.debug('准备设置播放上下文: workId=${originalContext.work.id}, file=${originalContext.currentFile.title}');
      AppLogger.debug('播放列表状态: 长度=${originalContext.playlist.length}, 当前索引=${originalContext.currentIndex}');

      // 验证上下文
      try {
        originalContext.validate();
      } catch (e) {
        AppLogger.error('播放上下文验证失败', e);
        rethrow;
      }

      // 1. 先停止当前播放
      AppLogger.debug('停止当前播放');
      await _player.stop();

      // 2. 等待播放器就绪
      AppLogger.debug('暂停播放器');
      await _player.pause();

      // 3. 更新上下文
      AppLogger.debug('更新播放上下文');
      _stateManager.updateContext(originalContext);

      // 4. 设置新的播放源
      AppLogger.debug('设置播放源: 初始位置=${initialPosition?.inMilliseconds}ms');
      List<Child> loadedFiles;
      try {
        loadedFiles = await PlaylistBuilder.setPlaylistSource(
          player: _player,
          playlist: _playlist,
          files: originalContext.playlist,
          initialIndex: originalContext.currentIndex,
          initialPosition: initialPosition ?? Duration.zero,
        );
      } catch (e, stack) {
        AppLogger.error('设置播放源失败', e, stack);
        rethrow;
      }

      // Update context with filtered playlist to keep indices consistent
      var context = originalContext;
      if (loadedFiles.length != originalContext.playlist.length) {
        final currentFile = loadedFiles.contains(originalContext.currentFile)
            ? originalContext.currentFile
            : loadedFiles.first;
        context = PlaybackContext.withFilteredPlaylist(
          work: originalContext.work,
          files: originalContext.files,
          currentFile: currentFile,
          playlist: loadedFiles,
          playMode: originalContext.playMode,
        );
        _stateManager.updateContext(context);
      }

      // 5. 等待播放器准备完成
      // 删掉，会导致播放器索引回到0
      // AppLogger.debug('等待播放器加载');
      // await _player.load();

      // 6. 更新轨道信息
      AppLogger.debug('更新轨道信息');
      _updateTrackAndContext(context.currentFile, context.work);

      AppLogger.debug('播放上下文设置完成');
    } catch (e, stack) {
      AppLogger.error('设置播放上下文失败', e, stack);
      _eventHub.emit(PlaybackErrorEvent('setPlaybackContext', e, stack));
      AudioErrorHandler.handleError(
        AudioErrorType.context,
        '设置播放上下文',
        e,
        stack,
      );
      rethrow;
    }
  }

  // 私有辅助方法
  void _updateTrackAndContext(Child file, Work work) {
    AppLogger.debug('更新轨道和上下文: file=${file.title}');
    _stateManager.updateTrackAndContext(file, work);
  }
} 