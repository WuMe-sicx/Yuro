import 'package:asmrapp/data/models/files/child.dart';
import 'package:asmrapp/data/models/files/files.dart';
import 'package:asmrapp/core/audio/models/file_path.dart';
import 'package:asmrapp/core/audio/models/subtitle.dart';
import 'package:dio/dio.dart';
import 'package:asmrapp/utils/logger.dart';
import 'package:asmrapp/core/subtitle/utils/subtitle_matcher.dart';
import 'package:asmrapp/core/subtitle/parsers/subtitle_parser_factory.dart';
import 'package:asmrapp/core/subtitle/cache/subtitle_cache_manager.dart';

class SubtitleLoader {
  final Dio _dio;

  SubtitleLoader({required Dio dio}) : _dio = dio;

  // 查找字幕文件
  Child? findSubtitleFile(Child audioFile, Files files) {
    if (files.children == null || audioFile.title == null) {
      AppLogger.debug('无法查找字幕文件: ${files.children == null ? '文件列表为空' : '当前文件名为空'}');
      return null;
    }

    AppLogger.debug('开始查找字幕文件...');
    
    // 使用 FilePath 获取同级文件
    final siblings = FilePath.getSiblings(audioFile, files);
    
    // 使用 SubtitleMatcher 查找匹配的字幕文件
    final subtitleFile = SubtitleMatcher.findMatchingSubtitle(
      audioFile.title!,
      siblings
    );
    
    if (subtitleFile != null) {
      AppLogger.debug('找到字幕文件: ${subtitleFile.title}, URL: ${subtitleFile.mediaDownloadUrl}');
    } else {
      AppLogger.debug('在当前目录中未找到字幕文件');
    }
    
    return subtitleFile;
  }

  // 修改: 加载字幕内容
  Future<SubtitleList?> loadSubtitleContent(String url) async {
    try {
      // 首先尝试从缓存加载
      final cachedContent = await SubtitleCacheManager.getCachedContent(url);
      if (cachedContent != null) {
        AppLogger.debug('从缓存加载字幕: $url');
        return _parseSubtitleContent(cachedContent);
      }

      // 缓存未命中，从网络加载
      AppLogger.debug('从网络加载字幕: $url');
      final response = await _dio.get(url);
      AppLogger.debug('字幕文件下载状态: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final content = response.data as String;
        
        // 保存到缓存
        await SubtitleCacheManager.cacheContent(url, content);
        
        return _parseSubtitleContent(content);
      } else {
        throw Exception('字幕下载失败: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.debug('字幕加载失败: $e');
      rethrow;
    }
  }

  // 新增: 解析字幕内容的私有方法
  SubtitleList? _parseSubtitleContent(String content) {
    AppLogger.debug('字幕文件内容预览: ${content.substring(0, content.length > 100 ? 100 : content.length)}...');
    
    final parser = SubtitleParserFactory.getParser(content);
    if (parser == null) {
      throw Exception('不支持的字幕格式');
    }
    
    final subtitleList = parser.parse(content);
    AppLogger.debug('字幕解析完成，字幕数量: ${subtitleList.subtitles.length}');
    
    return subtitleList;
  }
} 