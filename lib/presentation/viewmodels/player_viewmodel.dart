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
import 'package:get_it/get_it.dart';
import 'package:asmrapp/core/subtitle/subtitle_import_service.dart';
import 'package:rxdart/rxdart.dart';

class PlayerViewModel extends ChangeNotifier {
  final IAudioPlayerService _audioService;
  final PlaybackEventHub _eventHub;
  final ISubtitleService _subtitleService;
  final _subtitleLoader = SubtitleLoader();
  final _importService = GetIt.I<SubtitleImportService>();

  bool _isPlaying = false;
  bool _isBuffering = false;
  String? _errorMessage;
  bool _isUserImportedSubtitle = false;
  int _loadVersion = 0;
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
    // 播放状态事件 - 状态变化时通知（播放/暂停/缓冲等）
    _subscriptions.add(
      _eventHub.playbackState.listen(
        (event) {
          _isPlaying = event.state.playing;
          _position = event.position;  // fallback position for pause/resume
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

    // 播放进度 - UI更新路径：节流到200ms，减少rebuild频率
    _subscriptions.add(
      _eventHub.playbackProgress
          .throttleTime(const Duration(milliseconds: 200))
          .listen(
        (event) {
          _position = event.position;
          notifyListeners();
        },
        onError: (error) => debugPrint('$_tag - 播放进度流错误: $error'),
      ),
    );

    // 播放进度 - 字幕同步路径：保持全精度，不触发rebuild
    _subscriptions.add(
      _eventHub.playbackProgress.listen(
        (event) {
          _subtitleService.updatePosition(event.position);
        },
        onError: (error) => debugPrint('$_tag - 字幕同步流错误: $error'),
      ),
    );

    // 上下文变更事件
    _subscriptions.add(
      _eventHub.contextChange.listen(
        (event) async {
          await _loadSubtitleIfAvailable(event.context);
          if (_position != null) {
            _subtitleService.updatePosition(_position!);
          }
        },
        onError: (error) => debugPrint('$_tag - 上下文流错误: $error'),
      ),
    );

    // 初始状态流
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
  bool get isUserImportedSubtitle => _isUserImportedSubtitle;
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

  Future<void> _loadSubtitleIfAvailable(PlaybackContext context) async {
    final version = ++_loadVersion;
    final workId = context.work.id?.toString();
    final fileName = context.currentFile.title;

    // 1. 用户导入优先
    if (workId != null && fileName != null) {
      final entry = await _importService.findImported(workId, fileName);
      if (_loadVersion != version) return;
      if (entry != null) {
        final subtitleList = await _importService.loadLocalSubtitle(entry.subtitlePath);
        if (_loadVersion != version) return;
        if (subtitleList != null) {
          await _subtitleService.loadSubtitleFromContent(subtitleList);
          if (_loadVersion != version) return;
          _isUserImportedSubtitle = true;
          notifyListeners();
          return;
        }
        // Local file missing/corrupted → remove invalid association
        await _importService.removeImportedSubtitle(workId, fileName);
        if (_loadVersion != version) return;
      }
    }

    // 2. 自动匹配（原有逻辑）
    _isUserImportedSubtitle = false;
    final subtitleFile = _subtitleLoader.findSubtitleFile(
      context.currentFile,
      context.files,
    );
    if (subtitleFile?.mediaDownloadUrl != null) {
      await _subtitleService.loadSubtitle(subtitleFile!.mediaDownloadUrl!);
    } else {
      _subtitleService.clearSubtitle();
      AppLogger.debug('未找到字幕文件，清除现有字幕');
    }
  }

  /// Import a subtitle file for the current audio.
  Future<ImportResult> importSubtitle() async {
    final context = currentContext;
    if (context == null) return ImportResult.cancelled;

    final workId = context.work.id?.toString();
    final fileName = context.currentFile.title;
    if (workId == null || fileName == null) return ImportResult.cancelled;

    final response = await _importService.importSubtitle(workId, fileName);
    if (response.result == ImportResult.success && response.subtitleList != null) {
      // Verify we're still on the same track
      final currentWorkId = currentContext?.work.id?.toString();
      final currentFileName = currentContext?.currentFile.title;
      if (currentWorkId == workId && currentFileName == fileName) {
        await _subtitleService.loadSubtitleFromContent(response.subtitleList!);
        _isUserImportedSubtitle = true;
        notifyListeners();
      }
    }
    return response.result;
  }

  /// Remove imported subtitle and fall back to auto-match.
  Future<void> removeImportedSubtitle() async {
    final context = currentContext;
    if (context == null) return;

    final workId = context.work.id?.toString();
    final fileName = context.currentFile.title;
    if (workId == null || fileName == null) return;

    await _importService.removeImportedSubtitle(workId, fileName);
    _isUserImportedSubtitle = false;
    await _loadSubtitleIfAvailable(context);
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
