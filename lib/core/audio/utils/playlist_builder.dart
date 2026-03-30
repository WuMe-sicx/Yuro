import 'package:just_audio/just_audio.dart';
import 'package:asmrapp/data/models/files/child.dart';
import 'package:asmrapp/core/audio/cache/audio_cache_manager.dart';
import 'package:asmrapp/utils/logger.dart';

class PlaylistBuilder {
  /// Build audio sources with per-item error handling.
  /// Returns a record of (sources, originalIndices) to maintain index mapping.
  static Future<(List<AudioSource>, List<int>)> buildAudioSources(List<Child> files) async {
    final sources = <AudioSource>[];
    final originalIndices = <int>[];

    for (var i = 0; i < files.length; i++) {
      try {
        final source = await AudioCacheManager.createAudioSource(files[i].mediaDownloadUrl!);
        sources.add(source);
        originalIndices.add(i);
      } catch (e) {
        AppLogger.error('创建音频源失败,跳过: ${files[i].title}', e);
      }
    }
    return (sources, originalIndices);
  }

  static Future<void> updatePlaylist(
    ConcatenatingAudioSource playlist,
    List<AudioSource> sources,
  ) async {
    await playlist.clear();
    await playlist.addAll(sources);
  }

  /// Returns the list of files that were successfully loaded (matching the player queue order).
  static Future<List<Child>> setPlaylistSource({
    required AudioPlayer player,
    required ConcatenatingAudioSource playlist,
    required List<Child> files,
    required int initialIndex,
    required Duration initialPosition,
  }) async {
    final (sources, originalIndices) = await buildAudioSources(files);

    // Guard: empty playlist
    if (sources.isEmpty) {
      AppLogger.error('所有音频源创建失败,无法播放');
      throw Exception('无可用的音频源');
    }

    await updatePlaylist(playlist, sources);

    // Build filtered files list matching actual player queue
    final loadedFiles = originalIndices.map((i) => files[i]).toList();

    // Remap initialIndex: find the new index corresponding to the original
    var remappedIndex = originalIndices.indexOf(initialIndex);
    if (remappedIndex < 0) {
      // Original track failed to load, use closest available
      remappedIndex = 0;
      for (var i = 0; i < originalIndices.length; i++) {
        if (originalIndices[i] >= initialIndex) {
          remappedIndex = i;
          break;
        }
      }
      AppLogger.warning('原始索引 $initialIndex 不可用,使用替代索引 $remappedIndex');
    }

    await player.setAudioSource(
      playlist,
      initialIndex: remappedIndex,
      initialPosition: initialPosition,
    );

    return loadedFiles;
  }
}
