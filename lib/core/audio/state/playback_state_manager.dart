import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../models/audio_track_info.dart';
import '../models/playback_context.dart';
import '../utils/audio_error_handler.dart';
import '../utils/track_info_creator.dart';
import 'package:asmrapp/data/models/playback/playback_state.dart';
import '../storage/i_playback_state_repository.dart';
import '../events/playback_event.dart';
import '../events/playback_event_hub.dart';
import 'package:asmrapp/data/models/files/child.dart';
import 'package:asmrapp/data/models/works/work.dart';


class PlaybackStateManager {
  final AudioPlayer _player;
  final PlaybackEventHub _eventHub;
  final IPlaybackStateRepository _stateRepository;
  
  AudioTrackInfo? _currentTrack;
  PlaybackContext? _currentContext;

  final List<StreamSubscription> _subscriptions = [];
  Timer? _saveDebounceTimer;
  static const _saveInterval = Duration(seconds: 5);

  PlaybackStateManager({
    required AudioPlayer player,
    required PlaybackEventHub eventHub,
    required IPlaybackStateRepository stateRepository,
  }) : _player = player,
       _eventHub = eventHub,
       _stateRepository = stateRepository;

  // 初始化状态监听
  void initStateListeners() {
    // 监听播放器索引变化
    _subscriptions.add(
      _player.currentIndexStream.listen((index) {
        if (index != null && _currentContext != null) {
          final newFile = _currentContext!.playlist[index];
          updateTrackAndContext(newFile, _currentContext!.work);
        }
      }),
    );

    // 直接监听 AudioPlayer 的原始流
    _subscriptions.add(
      _player.playerStateStream.listen((state) async {
        final position = _player.position;
        final duration = _player.duration;

        // 转换并发送到 EventHub
        _eventHub.emit(PlaybackStateEvent(state, position, duration));

        if (state.processingState == ProcessingState.completed) {
          _onPlaybackCompleted();
        }
        _debounceSave();
      }),
    );

    _subscriptions.add(
      _player.positionStream.listen((position) {
        _eventHub.emit(PlaybackProgressEvent(
          position,
          _player.bufferedPosition
        ));
      }),
    );

    _setupEventListeners();
  }

  void _debounceSave() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(_saveInterval, () {
      saveState();
    });
  }

  // 状态更新方法
  void updateContext(PlaybackContext? context) {
    _currentContext = context;
    if (context != null) {
      _eventHub.emit(PlaybackContextEvent(context));
    }
  }

  void updateTrackInfo(AudioTrackInfo track) {
    _currentTrack = track;
    _eventHub.emit(TrackChangeEvent(track, _currentContext!.currentFile, _currentContext!.work));
  }

  void updateTrackAndContext(Child file, Work work) {
    if (_currentContext != null) {
      final newContext = _currentContext!.copyWithFile(file);
      updateContext(newContext);
    }
    
    final trackInfo = TrackInfoCreator.createFromFile(file, work);
    updateTrackInfo(trackInfo);
  }

  void _onPlaybackCompleted() {
    if (_currentContext == null) return;
    saveState(); // Immediate save on completion
    _eventHub.emit(PlaybackCompletedEvent(_currentContext!));
  }

  // 状态访问
  AudioTrackInfo? get currentTrack => _currentTrack;
  PlaybackContext? get currentContext => _currentContext;

  void clearState() {
    _currentTrack = null;
    _currentContext = null;
    updateContext(null);
  }

  // 状态持久化
  Future<void> saveState() async {
    if (_currentContext == null) return;

    try {
      final state = PlaybackState(
        work: _currentContext!.work,
        files: _currentContext!.files,
        currentFile: _currentContext!.currentFile,
        playlist: _currentContext!.playlist,
        currentIndex: _currentContext!.currentIndex,
        playMode: _currentContext!.playMode,
        position: (_player.position).inMilliseconds,
        timestamp: DateTime.now().toIso8601String(),
      );
      
      await _stateRepository.saveState(state);
    } catch (e, stack) {
      AudioErrorHandler.handleError(
        AudioErrorType.state,
        '保存播放状态',
        e,
        stack,
      );
    }
  }

  Future<PlaybackState?> loadState() async {
    try {
      return await _stateRepository.loadState();
    } catch (e, stack) {
      AudioErrorHandler.handleError(
        AudioErrorType.state,
        '加载播放状态',
        e,
        stack,
      );
      return null;
    }
  }

  void _setupEventListeners() {
    // 处理初始状态请求
    _subscriptions.add(
      _eventHub.requestInitialState.listen((_) {
        _eventHub.emit(InitialStateEvent(
          _currentTrack,
          _currentContext
        ));
      }),
    );
  }

  void dispose() {
    _saveDebounceTimer?.cancel();
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
} 