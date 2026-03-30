import 'dart:async';
import 'package:asmrapp/utils/logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import './i_audio_player_service.dart';
import './models/audio_track_info.dart';
import './models/playback_context.dart';
import './notification/audio_notification_service.dart';
import './storage/i_playback_state_repository.dart';
import './utils/audio_error_handler.dart';
import './state/playback_state_manager.dart';
import './controllers/playback_controller.dart';
import './events/playback_event_hub.dart';

class AudioPlayerService implements IAudioPlayerService {
  late final AudioPlayer _player;
  late final AudioNotificationService _notificationService;
  late final ConcatenatingAudioSource _playlist;
  late final PlaybackStateManager _stateManager;
  late final PlaybackController _playbackController;
  final PlaybackEventHub _eventHub;
  final IPlaybackStateRepository _stateRepository;
  final Completer<void> _initCompleter = Completer<void>();

  /// Await this before calling any public method to ensure init is complete
  Future<void> get ready => _initCompleter.future;

  AudioPlayerService._internal({
    required PlaybackEventHub eventHub,
    required IPlaybackStateRepository stateRepository,
  }) : _eventHub = eventHub,
       _stateRepository = stateRepository {
    _init();
  }

  static AudioPlayerService? _instance;
  
  factory AudioPlayerService({
    required PlaybackEventHub eventHub,
    required IPlaybackStateRepository stateRepository,
  }) {
    _instance ??= AudioPlayerService._internal(
      eventHub: eventHub,
      stateRepository: stateRepository,
    );
    return _instance!;
  }

  Future<void> _init() async {
    try {
      _player = AudioPlayer();
      _notificationService = AudioNotificationService(
        _player,
        _eventHub,
      );
      _playlist = ConcatenatingAudioSource(children: []);

      _stateManager = PlaybackStateManager(
        player: _player,
        stateRepository: _stateRepository,
        eventHub: _eventHub,
      );

      _playbackController = PlaybackController(
        player: _player,
        stateManager: _stateManager,
        playlist: _playlist,
        eventHub: _eventHub,
      );

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await _notificationService.init();

      _stateManager.initStateListeners();
      await restorePlaybackState();
      _initCompleter.complete();
    } catch (e, stack) {
      _initCompleter.completeError(e, stack);
      AudioErrorHandler.handleError(
        AudioErrorType.init,
        '音频播放器初始化',
        e,
        stack,
      );
      AudioErrorHandler.throwError(
        AudioErrorType.init,
        '音频播放器初始化',
        e,
      );
    }
  }

  // 基础播放控制
  @override
  Future<void> pause() async {
    await ready;
    await _playbackController.pause();
  }

  @override
  Future<void> resume() async {
    await ready;
    await _playbackController.play();
  }

  @override
  Future<void> stop() async {
    await ready;
    await _playbackController.stop();
    _stateManager.clearState();
  }

  @override
  Future<void> seek(Duration position) async {
    await ready;
    await _playbackController.seek(position);
  }

  @override
  Future<void> previous() async {
    await ready;
    await _playbackController.previous();
  }

  @override
  Future<void> next() async {
    await ready;
    await _playbackController.next();
  }

  // 上下文管理
  @override
  Future<void> playWithContext(PlaybackContext context) async {
    await ready;
    await _playbackController.setPlaybackContext(context);
    // 添加自动播放
    await resume();
  }

  // 状态访问
  @override
  AudioTrackInfo? get currentTrack => _stateManager.currentTrack;

  @override
  PlaybackContext? get currentContext => _stateManager.currentContext;

  // 状态持久化
  @override
  Future<void> savePlaybackState() => _stateManager.saveState();

  @override
  Future<void> restorePlaybackState() async {
    try {
      AppLogger.debug('开始恢复播放状态');
      final state = await _stateManager.loadState();
      
      if (state == null) {
        AppLogger.debug('没有可恢复的播放状态');
        return;
      }

      AppLogger.debug('已加载保存的状态: workId=${state.work.id}');
      AppLogger.debug('播放列表信息: 长度=${state.playlist.length}, 索引=${state.currentIndex}');

      if (state.playlist.isEmpty) {
        AppLogger.debug('保存的播放列表为空，跳过恢复');
        return;
      }

      final context = PlaybackContext(
        work: state.work,
        files: state.files,
        currentFile: state.currentFile,
        playMode: state.playMode,
      );

      try {
        await _playbackController.setPlaybackContext(
          context,
          initialPosition: Duration(milliseconds: state.position),
        );
        AppLogger.debug('播放状态恢复成功');
      } catch (e) {
        AppLogger.error('设置播放上下文失败，跳过状态恢复', e);
      }
    } catch (e, stack) {
      AudioErrorHandler.handleError(
        AudioErrorType.init,
        '恢复播放状态',
        e,
        stack,
      );
      rethrow;
    }
  }

  @override
  Future<void> dispose() async {
    _player.dispose();
    _notificationService.dispose();
  }
}
