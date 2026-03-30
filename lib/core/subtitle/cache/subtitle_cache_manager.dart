import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:asmrapp/utils/logger.dart';

class SubtitleCacheManager {
  static const String key = 'subtitleCache';
  
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 365), // 字幕文件不会变更，设置较长的有效期
      maxNrOfCacheObjects: 1000, // 最大缓存文件数
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// 获取缓存的字幕内容
  static Future<String?> getCachedContent(String url) async {
    try {
      final fileInfo = await instance.getFileFromCache(url);
      if (fileInfo != null) {
        // Check if cache entry has expired
        if (fileInfo.validTill.isBefore(DateTime.now())) {
          AppLogger.debug('字幕缓存已过期: $url');
          await instance.removeFile(url);
          return null;
        }
        AppLogger.debug('使用字幕缓存: $url');
        return await fileInfo.file.readAsString();
      }
      return null;
    } catch (e) {
      AppLogger.error('读取字幕缓存失败', e);
      return null;
    }
  }

  /// 保存字幕内容到缓存
  static Future<void> cacheContent(String url, String content) async {
    try {
      await instance.putFile(
        url,
        Uint8List.fromList(utf8.encode(content)),
        fileExtension: 'txt',
      );
      AppLogger.debug('字幕已缓存: $url');
    } catch (e) {
      AppLogger.error('保存字幕缓存失败', e);
    }
  }

  /// 清理缓存
  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
      AppLogger.debug('字幕缓存已清空');
    } catch (e) {
      AppLogger.error('清理字幕缓存失败', e);
    }
  }

  /// 获取缓存大小
  static Future<int> getSize() async {
    try {
      return instance.store.getCacheSize();
    } catch (e) {
      AppLogger.error('获取字幕缓存大小失败', e);
      return 0;
    }
  }
} 