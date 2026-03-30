import 'package:asmrapp/core/audio/utils/audio_error_handler.dart';
import 'package:asmrapp/data/models/works/work.dart';
import 'package:asmrapp/data/models/files/files.dart';
import 'package:asmrapp/data/models/files/child.dart';
import 'package:asmrapp/utils/logger.dart';
import 'package:asmrapp/core/audio/models/play_mode.dart';
import 'package:asmrapp/core/audio/models/file_path.dart';

class PlaybackContext {
  final Work work;
  final Files files;
  final Child currentFile;
  final List<Child> playlist;
  final int currentIndex;
  final PlayMode playMode;

  void validate() {
    if (playlist.isEmpty) {
      throw AudioError(
        AudioErrorType.state,
        '无效的播放列表状态：播放列表为空',
      );
    }
    
    if (currentIndex < 0 || currentIndex >= playlist.length) {
      throw AudioError(
        AudioErrorType.state,
        '无效的播放列表索引：$currentIndex，列表长度：${playlist.length}',
      );
    }

    if (!playlist.contains(currentFile)) {
      throw AudioError(
        AudioErrorType.state,
        '当前文件不在播放列表中',
      );
    }
  }

  // 私有构造函数
  const PlaybackContext._({
    required this.work,
    required this.files,
    required this.currentFile,
    required this.playlist,
    required this.currentIndex,
    this.playMode = PlayMode.sequence,
  });

  // 公开的工厂构造函数，只需要基本参数
  factory PlaybackContext({
    required Work work,
    required Files files,
    required Child currentFile,
    PlayMode playMode = PlayMode.sequence,
  }) {
    final playlist = _getPlaylistFromSameDirectory(currentFile, files);
    final currentIndex = playlist.indexWhere((file) => file.title == currentFile.title);
    
    return PlaybackContext._(
      work: work,
      files: files,
      currentFile: currentFile,
      playlist: playlist,
      currentIndex: currentIndex,
      playMode: playMode,
    );
  }

  // 获取同级文件列表
  static List<Child> _getPlaylistFromSameDirectory(Child currentFile, Files files) {
    // AppLogger.debug('开始获取播放列表...');
    // AppLogger.debug('当前文件: ${currentFile.title}');
    // AppLogger.debug('当前文件类型: ${currentFile.type}');

    // 获取当前文件的扩展名
    final extension = currentFile.title?.split('.').last.toLowerCase();
    // AppLogger.debug('当前文件扩展名: $extension');
    
    if (extension != 'mp3' && extension != 'wav') {
      AppLogger.debug('不支持的文件类型: $extension');
      return [];
    }

    // 使用 FilePath 获取同级文件
    final siblings = FilePath.getSiblings(currentFile, files);
    
    // 过滤出相同扩展名的文件
    final playlist = siblings.where((file) => 
      file.title?.toLowerCase().endsWith('.$extension') ?? false
    ).toList();
    
    // AppLogger.debug('找到 ${playlist.length} 个可播放文件:');
    // for (var file in playlist) {
    //   AppLogger.debug('- [${file.type}] ${file.title} (URL: ${file.mediaDownloadUrl != null ? '有' : '无'})');
    // }
    
    return playlist;
  }

  /// Create a context with a pre-filtered playlist (e.g. after skipping failed audio sources).
  /// `playlist` must be a subset of the original and `currentFile` must be in it.
  factory PlaybackContext.withFilteredPlaylist({
    required Work work,
    required Files files,
    required Child currentFile,
    required List<Child> playlist,
    PlayMode playMode = PlayMode.sequence,
  }) {
    final currentIndex = playlist.indexWhere((f) => f.title == currentFile.title);
    return PlaybackContext._(
      work: work,
      files: files,
      currentFile: currentFile,
      playlist: playlist,
      currentIndex: currentIndex >= 0 ? currentIndex : 0,
      playMode: playMode,
    );
  }

  // 便捷方法：检查是否有下一曲
  bool get hasNext => currentIndex < playlist.length - 1;

  // 便捷方法：检查是否有上一曲
  bool get hasPrevious => currentIndex > 0;

  // 获取下一曲（考虑播放模式）
  Child? getNextFile() {
    if (playlist.isEmpty) return null;
    
    switch (playMode) {
      case PlayMode.single:
        return currentFile;  // 单曲循环返回当前文件
      case PlayMode.loop:
        // 列表循环：最后一首返回第一首，否则返回下一首
        return hasNext ? playlist[currentIndex + 1] : playlist[0];
      case PlayMode.sequence:
        // 顺序播放：有下一首则返回，否则返回null
        return hasNext ? playlist[currentIndex + 1] : null;
    }
  }

  // 获取上一曲
  Child? getPreviousFile() {
    if (playlist.isEmpty) return null;
    
    switch (playMode) {
      case PlayMode.single:
        return currentFile;
      case PlayMode.loop:
        // 列表循环：第一首返回最后一首，否则返回上一首
        return hasPrevious ? playlist[currentIndex - 1] : playlist[playlist.length - 1];
      case PlayMode.sequence:
        // 顺序播放：有上一首则返回，否则返回null
        return hasPrevious ? playlist[currentIndex - 1] : null;
    }
  }

  // 这两个方法 copy 的设计思路是遵循了"不可变对象"模式，
  // 通过创建新的实例而不是修改现有实例来更新状态。这种模式有以下好处：
  // 状态可预测
  // 线程安全
  // 便于调试
  // 符合函数式编程思想

  // 创建新的上下文（用于切换文件）
  PlaybackContext copyWithFile(Child newFile) {
    return PlaybackContext(
      work: work,
      files: files,
      currentFile: newFile,
      playMode: playMode,
    );
  }

  // 创建新的上下文（用于切换播放模式）
  PlaybackContext copyWithMode(PlayMode newMode) {
    return PlaybackContext(
      work: work,
      files: files,
      currentFile: currentFile,
      playMode: newMode,
    );
  }

  // 便捷方法：获取可播放文件列表
  List<Child> getPlayableFiles() {
    if (files.children == null) return [];
    return files.children!.where((file) => 
      file.mediaDownloadUrl != null && 
      file.type?.toLowerCase() != 'vtt'
    ).toList();
  }

  // 工具方法：获取文件名（不含扩展名）
  String? _getBaseName(String? filename) {
    if (filename == null) return null;
    return filename.replaceAll(RegExp(r'\.[^.]+$'), '');
  }
} 