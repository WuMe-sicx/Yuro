import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:asmrapp/utils/logger.dart';

/// 图片缓存管理器
/// 统一管理应用内所有图片的缓存策略
class ImageCacheManager {
  static const String key = 'imageCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
      repo: JsonCacheInfoRepository(databaseName: key),
      fileService: HttpFileService(),
    ),
  );

  /// 获取缓存大小
  static Future<int> getSize() async {
    try {
      return instance.store.getCacheSize();
    } catch (e) {
      AppLogger.error('获取图片缓存大小失败', e);
      return 0;
    }
  }

  /// 清理图片缓存
  static Future<void> clearCache() async {
    try {
      await instance.emptyCache();
      AppLogger.debug('图片缓存已清空');
    } catch (e) {
      AppLogger.error('清理图片缓存失败', e);
    }
  }
}
