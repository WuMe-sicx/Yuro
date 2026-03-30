import 'package:asmrapp/core/audio/events/playback_event.dart';
import 'package:asmrapp/core/audio/models/audio_track_info.dart';
import 'package:asmrapp/core/audio/models/playback_context.dart';
import 'package:asmrapp/core/subtitle/i_subtitle_service.dart';
import 'package:asmrapp/utils/logger.dart';
import 'package:flutter/foundation.dart';
import 'package:asmrapp/core/audio/i_audio_player_service.dart';
import 'package:asmrapp/core/audio/models/subtitle.dart';
import 'dart:async';
import 'package:asmrapp/core/subtitle/subtitle_loader.dart';
import 'package:asmrapp/core/audio/events/playback_event_hub.dart';
import 'package:just_audio/just_audio.dart';

class PlayerViewModel extends ChangeNotifier {
  final IAudioPlayerService _audioService;
  final PlaybackEventHub _eventHub;
  final ISubtitleService _subtitleService;
  final _subtitleLoader = SubtitleLoader();

  bool _isPlaying = false;
  bool _isBuffering = false;
  String? _errorMessage;
  Duration? _position;
  Duration? _duration;
  Subtitle? _currentSubtitle;

  final List<StreamSubscription> _subscriptions = [];

  static const _tag = 'PlayerViewModel';

  PlayerViewModel({
    required IAudioPlayerService audioService,
    required PlaybackEventHub eventHub,
    required ISubtitleService subtitleService,
  }) : _audioService = audioService,
       _eventHub = eventHub,
       _subtitleService = subtitleService {
    _initStreams();
    _requestInitialState();
  }

  void _initStreams() {
    // 播放状态事件
    _subscriptions.add(
      _eventHub.playbackState.listen(
        (event) {
          _isPlaying = event.state.playing;
          _position = event.position;
          _duration = event.duration;
          _isBuffering = event.state.processingState == ProcessingState.buffering ||
                         event.state.processingState == ProcessingState.loading;
          notifyListeners();
        },
        onError: (error) => debugPrint('$_tag - 播放状态流错误: $error'),
      ),
    );

    // 音轨变更事件
    _subscriptions.add(
      _eventHub.trackChange.listen(
        (event) {
          notifyListeners();
        },
        onError: (error) => debugPrint('$_tag - 音轨变更流错误: $error'),
      ),
    );

    // 播放进度事件
    _subscriptions.add(
      _eventHub.playbackProgress.listen(
        (event) {
          _position = event.position;
          if (_position != null) {
            _subtitleService.updatePosition(_position!);
          }
          notifyListeners();
        },
        onError: (error) => debugPrint('$_tag - 播放进度流错误: $error'),
      ),
    );

    // 上下文变更事件
    _subscriptions.add(
      _eventHub.contextChange.listen(
        (event) async {
          await _loadSubtitleIfAvailable(event.context);
          // 如果有保存的位置，在字幕加载完成后更新位置
          if (_position != null) {
            _subtitleService.updatePosition(_position!);
          }
        },
        onError: (error) => debugPrint('$_tag - 上下文流错误: $error'),
      ),
    );

    // 使用新添加的 initialState 流
    _subscriptions.add(
      _eventHub.initialState.listen(
        (event) {
          if (event.track != null) {
            notifyListeners();
          }
          if (event.context != null) {
            _loadSubtitleIfAvailable(event.context!);
          }
        },
        onError: (error) => debugPrint('$_tag - 初始状态流错误: $error'),
      ),
    );

    // 错误事件
    _subscriptions.add(
      _eventHub.errors.listen(
        (event) {
          _errorMessage = '播放错误: ${event.operation}';
          AppLogger.error('播放错误事件: ${event.operation}', event.error, event.stackTrace);
          notifyListeners();
        },
        onError: (error) => debugPrint('$_tag - 错误事件流错误: $error'),
      ),
    );

    _initSubtitleStreams();
  }

  void _initSubtitleStreams() {
    _subscriptions.add(
      _subtitleService.subtitleStream.listen(
        (subtitleList) {
          debugPrint('$_tag - 字幕列表更新: ${subtitleList != null ? '已加载' : '未加载'}');
        },
        onError: (error) => debugPrint('$_tag - 字幕流错误: $error'),
      ),
    );

    _subscriptions.add(
      _subtitleService.currentSubtitleStream.listen(
        (subtitle) {
          _currentSubtitle = subtitle;
          notifyListeners();
        },
        onError: (error) => debugPrint('$_tag - 当前字幕流错误: $error'),
      ),
    );
  }

  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  String? get errorMessage => _errorMessage;
  Duration? get position => _position;
  Duration? get duration => _duration;
  Subtitle? get currentSubtitle => _currentSubtitle;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> playPause() async {
    if (_isPlaying) {
      _audioService.pause();
    } else {
      _audioService.resume();
    }
  }

  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  Future<void> previous() async {
    await _audioService.previous();
  }

  Future<void> next() async {
    await _audioService.next();
  }

  Future<void> stop() async {
    await _audioService.stop();
    _position = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }

  // 请求初始状态
  void _requestInitialState() {
    _eventHub.emit(RequestInitialStateEvent());
  }

  // 修改字幕加载方法，返回 Future 以便等待加载完成
  Future<void> _loadSubtitleIfAvailable(PlaybackContext context) async {
    final subtitleFile = _subtitleLoader.findSubtitleFile(
      context.currentFile,
      context.files
    );
    if (subtitleFile?.mediaDownloadUrl != null) {
      await _subtitleService.loadSubtitle(subtitleFile!.mediaDownloadUrl!);
    } else {
      _subtitleService.clearSubtitle();
      AppLogger.debug('未找到字幕文件，清除现有字幕');
    }
  }

  AudioTrackInfo? get currentTrackInfo => _audioService.currentTrack;
  PlaybackContext? get currentContext => _audioService.currentContext;

  Future<void> seekToNextLyric() async {
    final currentSubtitle = _subtitleService.currentSubtitleWithState;
    final subtitleList = _subtitleService.subtitleList;
    
    if (currentSubtitle != null && subtitleList != null) {
      final nextSubtitle = currentSubtitle.subtitle.getNext(subtitleList);
      if (nextSubtitle != null) {
        await seek(nextSubtitle.start);
      }
    }
  }

  Future<void> seekToPreviousLyric() async {
    final currentSubtitle = _subtitleService.currentSubtitleWithState;
    final subtitleList = _subtitleService.subtitleList;
    
    if (currentSubtitle != null && subtitleList != null) {
      final previousSubtitle = currentSubtitle.subtitle.getPrevious(subtitleList);
      if (previousSubtitle != null) {
        await seek(previousSubtitle.start);
      }
    }
  }
}
