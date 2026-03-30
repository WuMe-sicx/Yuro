import 'dart:async';
import 'package:asmrapp/core/audio/events/playback_event_hub.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:asmrapp/utils/logger.dart';
import 'package:rxdart/rxdart.dart';
import '../models/audio_track_info.dart';
import '../audio_player_handler.dart';

class AudioNotificationService {
  final AudioPlayer _player;
  final PlaybackEventHub _eventHub;
  AudioHandler? _audioHandler;
  final _mediaItem = BehaviorSubject<MediaItem?>();
  StreamSubscription? _trackChangeSubscription;

  AudioNotificationService(
    this._player,
    this._eventHub,
  );

  Future<void> init() async {
    try {
      _audioHandler = await AudioService.init(
        builder: () => AudioPlayerHandler(_player, _eventHub),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.asmrapp.audio',
          androidNotificationChannelName: 'ASMR One 播放器',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: false,
        ),
      );

      _setupEventListeners();
      AppLogger.debug('通知栏服务初始化成功');
    } catch (e) {
      AppLogger.error('通知栏服务初始化失败', e);
      rethrow;
    }
  }

  void _setupEventListeners() {
    _trackChangeSubscription = _eventHub.trackChange.listen((event) {
      updateMetadata(event.track);
    });
  }

  void updateMetadata(AudioTrackInfo trackInfo) {
    final mediaItem = MediaItem(
      id: trackInfo.url,
      title: trackInfo.title,
      artist: trackInfo.artist,
      artUri: Uri.parse(trackInfo.coverUrl),
      duration: trackInfo.duration,
    );

    _mediaItem.add(mediaItem);
    if (_audioHandler != null) {
      (_audioHandler as BaseAudioHandler).mediaItem.add(mediaItem);
    }
  }

  Future<void> dispose() async {
    _trackChangeSubscription?.cancel();
    await _audioHandler?.stop();
    await _mediaItem.close();
  }
}
