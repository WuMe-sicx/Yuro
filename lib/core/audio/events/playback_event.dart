import 'package:just_audio/just_audio.dart';
import '../models/audio_track_info.dart';
import '../models/playback_context.dart';
import 'package:asmrapp/data/models/files/child.dart';
import 'package:asmrapp/data/models/works/work.dart';

/// 播放事件基类
abstract class PlaybackEvent {}

/// 播放状态事件
class PlaybackStateEvent extends PlaybackEvent {
  final PlayerState state;
  final Duration position;
  final Duration? duration;
  PlaybackStateEvent(this.state, this.position, this.duration);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackStateEvent &&
          state.playing == other.state.playing &&
          state.processingState == other.state.processingState &&
          position.inMilliseconds ~/ 100 == other.position.inMilliseconds ~/ 100 &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(
        state.playing,
        state.processingState,
        position.inMilliseconds ~/ 100,
        duration,
      );
}

/// 播放上下文事件
class PlaybackContextEvent extends PlaybackEvent {
  final PlaybackContext context;
  PlaybackContextEvent(this.context);
}

/// 音轨变更事件
class TrackChangeEvent extends PlaybackEvent {
  final AudioTrackInfo track;
  final Child file;
  final Work work;
  TrackChangeEvent(this.track, this.file, this.work);
}

/// 播放错误事件
class PlaybackErrorEvent extends PlaybackEvent {
  final String operation;
  final dynamic error;
  final StackTrace? stackTrace;
  PlaybackErrorEvent(this.operation, this.error, [this.stackTrace]);
}

/// 播放完成事件
class PlaybackCompletedEvent extends PlaybackEvent {
  final PlaybackContext context;
  PlaybackCompletedEvent(this.context);
}

/// 播放进度事件
class PlaybackProgressEvent extends PlaybackEvent {
  final Duration position;
  final Duration? bufferedPosition;
  PlaybackProgressEvent(this.position, this.bufferedPosition);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaybackProgressEvent &&
          position == other.position;

  @override
  int get hashCode => position.hashCode;
}

/// 添加初始状态相关事件
class RequestInitialStateEvent extends PlaybackEvent {}

class InitialStateEvent extends PlaybackEvent {
  final AudioTrackInfo? track;
  final PlaybackContext? context;
  InitialStateEvent(this.track, this.context);
}