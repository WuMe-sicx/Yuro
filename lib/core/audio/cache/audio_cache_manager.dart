import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:asmrapp/utils/logger.dart';

/// 音频缓存管理器
/// 负责管理音频文件的缓存,对外隐藏具体的缓存实现
class AudioCacheManager {
  static const int _maxCacheSize = 1024 * 1024 * 1024; // 总缓存限制 1024MB
  static const Duration _cacheExpiration = Duration(days: 30);

  /// 创建音频源
  /// 内部处理缓存逻辑,对外只返回 AudioSource
  static Future<AudioSource> createAudioSource(String url) async {
    try {
      final cacheFile = await _getCacheFile(url);
      final fileName = _generateFileName(url);
      AppLogger.debug('准备创建音频源 - URL: $url, 缓存文件名: $fileName');
      
      // 检查缓存文件是否存在且有效
      final isValid = await _isCacheValid(cacheFile, fileName);
      
      if (isValid) {
        AppLogger.debug('[$fileName] 使用已有缓存文件');
        return _createCachingSource(url, cacheFile);
      }

      AppLogger.debug('[$fileName] 创建新的缓存源');
      return _createCachingSource(url, cacheFile);
      
    } catch (e, stackTrace) {
      AppLogger.warning('创建缓存音频源失败,降级为流式播放: $url');
      AppLogger.error('缓存源创建异常', e, stackTrace);
      return ProgressiveAudioSource(Uri.parse(url));
    }
  }

  /// 清理过期和超量的缓存
  static Future<void> cleanCache() async {
    try {
      final cacheDir = await _getCacheDir();
      final files = await cacheDir.list().toList();
      
      // 按修改时间排序
      files.sort((a, b) {
        return a.statSync().modified.compareTo(b.statSync().modified);
      });

      var totalSize = 0;
      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          
          // 检查是否过期
          if (DateTime.now().difference(stat.modified) > _cacheExpiration) {
            await file.delete();
            continue;
          }

          totalSize += stat.size;
          
          // 如果总大小超过限制,删除最旧的文件
          if (totalSize > _maxCacheSize) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      AppLogger.error('清理缓存失败', e);
    }
  }

  /// 获取缓存大小
  static Future<int> getCacheSize() async {
    try {
      final cacheDir = await _getCacheDir();
      final files = await cacheDir.list().toList();
      
      var totalSize = 0;
      for (var file in files) {
        if (file is File) {
          totalSize += (await file.stat()).size;
        }
      }
      return totalSize;
    } catch (e) {
      AppLogger.error('获取缓存大小失败', e);
      return 0;
    }
  }

  // 私有方法

  /// 创建缓存音频源
  static AudioSource _createCachingSource(String url, File cacheFile) {
    return LockCachingAudioSource(
      Uri.parse(url),
      cacheFile: cacheFile,
    );
  }

  /// 检查缓存是否有效
  static Future<bool> _isCacheValid(File cacheFile, String fileName) async {
    final exists = await cacheFile.exists();
    if (!exists) {
      AppLogger.debug('[$fileName] 缓存验证: 文件不存在');
      return false;
    }

    try {
      final stat = await cacheFile.stat();
      final size = stat.size;
      final age = DateTime.now().difference(stat.modified);
      
      AppLogger.debug('[$fileName] 缓存验证: 大小=${size}bytes, 年龄=$age');
      
      // 移除单个文件大小检查，只保留过期检查
      if (age > _cacheExpiration) {
        AppLogger.debug('[$fileName] 缓存无效: 文件过期 ($age > $_cacheExpiration)');
        await cacheFile.delete();
        return false;
      }

      AppLogger.debug('[$fileName] 缓存验证: 有效');
      return true;
    } catch (e) {
      AppLogger.error('[$fileName] 检查缓存有效性失败', e);
      return false;
    }
  }

  /// 获取缓存文件
  static Future<File> _getCacheFile(String url) async {
    final cacheDir = await _getCacheDir();
    final fileName = _generateFileName(url);
    return File('${cacheDir.path}/$fileName');
  }

  /// 生成缓存文件名
  static String _generateFileName(String url) {
    final bytes = utf8.encode(url);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 获取缓存目录
  static Future<Directory> _getCacheDir() async {
    final cacheDir = await getTemporaryDirectory();
    final audioCacheDir = Directory('${cacheDir.path}/audio_cache');
    if (!await audioCacheDir.exists()) {
      await audioCacheDir.create(recursive: true);
    }
    return audioCacheDir;
  }
}