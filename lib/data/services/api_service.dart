import 'package:asmrapp/core/cache/recommendation_cache_manager.dart';
import 'package:asmrapp/data/models/mark_status.dart';
import 'package:asmrapp/data/models/playlists_with_exist_statu/playlists_with_exist_statu.dart';
import 'package:dio/dio.dart';
import 'package:asmrapp/data/models/files/files.dart';
import 'package:asmrapp/data/models/works/work.dart';
import 'package:asmrapp/data/models/works/pagination.dart';
import 'package:asmrapp/utils/logger.dart';
import 'package:asmrapp/data/services/interceptors/auth_interceptor.dart';
import 'package:asmrapp/data/services/interceptors/retry_interceptor.dart';
import 'package:asmrapp/data/services/exceptions/network_exception.dart';
import 'package:asmrapp/data/models/playlists_with_exist_statu/playlist.dart';
import 'package:asmrapp/data/models/my_lists/my_playlists/my_playlists.dart';
import 'package:asmrapp/data/models/tags/tag_item.dart';
import 'package:asmrapp/data/models/circles/circle_item.dart';
import 'package:asmrapp/data/models/vas/voice_actor.dart';
import 'package:asmrapp/data/models/works/work_info.dart';
import 'package:asmrapp/core/settings/app_settings_service.dart';


class WorksResponse {
  final List<Work> works;
  final Pagination pagination;

  WorksResponse({required this.works, required this.pagination});
}

class ApiService {
  final Dio _dio;
  final _recommendationCache = RecommendationCacheManager();

  final AppSettingsService _settings;

  ApiService({required AppSettingsService settings})
      : _settings = settings,
        _dio = Dio(BaseOptions(
          baseUrl: settings.serverUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        )) {
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
    _dio.interceptors.add(AuthInterceptor());
    // Listen for server URL changes
    _settings.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    if (_dio.options.baseUrl != _settings.serverUrl) {
      _dio.options.baseUrl = _settings.serverUrl;
      _recommendationCache.clear();
      AppLogger.info('API服务器已切换: ${_settings.serverUrl}');
    }
  }

  /// 获取作品文件列表
  Future<Files> getWorkFiles(String workId, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get(
        '/tracks/$workId', 
        queryParameters: {
          'v': '2',
        },
        cancelToken: cancelToken,  // 添加 cancelToken 支持
      );

      if (response.statusCode == 200) {
        final filesData = {
          'type': 'root',
          'title': 'Root',
          'children': response.data,
        };

        return Files.fromJson(filesData);
      }

      throw Exception('获取文件列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取作品列表
  Future<WorksResponse> getWorks({
    int page = 1,
    bool hasSubtitle = false,
    String order = 'create_date',
    String sort = 'desc',
    String playlistId = '',
  }) async {
    try {
      final queryParams = {
        'page': page,
        'subtitle': hasSubtitle ? 1 : 0,
        'order': order,
        'sort': sort,
      };

      // 如果提供了收藏夹ID，添加到查询参数
      if (playlistId.isNotEmpty) {
        queryParams['withPlaylistStatus[]'] = playlistId;
      }

      final response = await _dio.get(
        '/works',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception('获取作品列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 搜索作品
  Future<WorksResponse> searchWorks({
    required String keyword,
    int page = 1,
    String order = 'create_date',
    String sort = 'desc',
    bool hasSubtitle = false,
  }) async {
    try {
      final response = await _dio.get(
        '/search/${Uri.encodeComponent(keyword)}',
        queryParameters: {
          'page': page,
          'order': order,
          'sort': sort,
          'subtitle': hasSubtitle ? 1 : 0,
          'includeTranslationWorks': true,
        },
      );

      if (response.statusCode == 200) {
        AppLogger.debug('搜索返回数据: ${response.data}');

        final works = (response.data['works'] as List)
            .map((work) => Work.fromJson(work))
            .toList();

        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works,
          pagination: pagination,
        );
      }

      throw Exception('搜索失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取收藏列表
  Future<WorksResponse> getFavorites({int page = 1}) async {
    try {
      final response = await _dio.get('/review', queryParameters: {
        'page': page,
        'order': 'updated_at',
        'sort': 'desc',
      });

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception('获取收藏列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取推荐作品
  Future<WorksResponse> getRecommendations({
    required String uuid,
    int page = 1,
    bool hasSubtitle = false,
  }) async {
    try {
      final response = await _dio.post(
        '/recommender/recommend-for-user',
        data: {
          'keyword': ' ',
          'userId': uuid,
          'page': page,
          'subtitle': hasSubtitle ? 1 : 0,
          'localSubtitledWorks': [],
          'withPlaylistStatus': [],
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception('获取推荐列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取热门作品
  Future<WorksResponse> getPopular({
    int page = 1,
    bool hasSubtitle = false,
  }) async {
    try {
      final response = await _dio.post(
        '/recommender/popular',
        data: {
          'keyword': ' ',
          'page': page,
          'subtitle': hasSubtitle ? 1 : 0,
          'localSubtitledWorks': [],
          'withPlaylistStatus': [],
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception('获取热门列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取相关推荐作品
  Future<WorksResponse> getItemNeighbors({
    required String itemId,
    int page = 1,
    bool hasSubtitle = false,
  }) async {
    try {
      // 先尝试从缓存获取
      final cachedData = _recommendationCache.get(itemId, page, hasSubtitle ? 1 : 0);
      if (cachedData != null) {
        return cachedData;
      }

      // 缓存未命中，从网络获取
      final response = await _dio.post(
        '/recommender/item-neighbors',
        data: {
          'keyword': '',
          'itemId': itemId,
          'page': page,
          'subtitle': hasSubtitle ? 1 : 0,
          'localSubtitledWorks': [],
          'withPlaylistStatus': [],
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        final worksResponse = WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );

        // 存入缓存
        _recommendationCache.set(itemId, page, hasSubtitle ? 1 : 0, worksResponse);

        return worksResponse;
      }

      throw Exception('获取相关推荐失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取作品在收藏夹中的状态
  Future<PlaylistsWithExistStatu> getWorkExistStatusInPlaylists({
    required String workId,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get(
        '/playlist/get-work-exist-status-in-my-playlists',
        queryParameters: {
          'workID': workId,
          'page': page,
          'version': 2,
        },
      );

      if (response.statusCode == 200) {
        return PlaylistsWithExistStatu.fromJson(response.data);
      }

      throw Exception('获取收藏夹列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 添加作品到收藏夹
  Future<void> addWorkToPlaylist({
    required String playlistId,
    required String workId,
  }) async {
    try {
      await _dio.post(
        '/playlist/add-works-to-playlist',
        data: {
          'id': playlistId,
          'works': [int.parse(workId)],
        },
      );
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('添加到收藏夹失败', e, stackTrace);
      throw Exception('添加到收藏夹失败: $e');
    }
  }

  /// 从收藏夹移除作品
  Future<void> removeWorkFromPlaylist({
    required String playlistId,
    required String workId,
  }) async {
    try {
      await _dio.post(
        '/playlist/remove-works-from-playlist',
        data: {
          'id': playlistId,
          'works': [int.parse(workId)],
        },
      );
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('从收藏夹移除失败', e, stackTrace);
      throw Exception('从收藏夹移除失败: $e');
    }
  }

  /// 更新作品的标记状态
  Future<void> updateWorkMarkStatus(String workId, String status) async {
    try {
      final response = await _dio.put(
        '/review',
        data: {
          'work_id': int.parse(workId),
          'progress': status,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('标记失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('更新标记状态失败', e, stackTrace);
      rethrow;
    }
  }

  /// 将 MarkStatus 枚举转换为 API 参数
  String convertMarkStatusToApi(MarkStatus status) {
    switch (status) {
      case MarkStatus.wantToListen:
        return 'marked';
      case MarkStatus.listening:
        return 'listening';
      case MarkStatus.listened:
        return 'listened';
      case MarkStatus.relistening:
        return 'replay';
      case MarkStatus.onHold:
        return 'postponed';
    }
  }

  /// 获取默认标记目标收藏夹
  Future<Playlist> getDefaultMarkTargetPlaylist() async {
    try {
      final response = await _dio.get('/playlist/get-default-mark-target-playlist');

      if (response.statusCode == 200) {
        final playlist = Playlist.fromJson(response.data);
        AppLogger.info('获取默认标记目标收藏夹成功: id=${playlist.id}, name=${playlist.name}');
        return playlist;
      }

      throw Exception('获取默认标记目标收藏夹失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取用户的播放列表
  Future<MyPlaylists> getMyPlaylists({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/playlist/get-playlists',
        queryParameters: {
          'page': page,
        },
      );

      if (response.statusCode == 200) {
        final myPlaylists = MyPlaylists.fromJson(response.data);
        AppLogger.info('获取播放列表成功: ${myPlaylists.playlists?.length ?? 0}个播放列表');
        return myPlaylists;
      }

      throw Exception('获取播放列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取所有标签列表
  Future<List<TagItem>> getTags() async {
    try {
      final response = await _dio.get('/tags/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => TagItem.fromJson(item)).toList();
      }

      throw Exception('获取标签列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取所有社团列表
  Future<List<CircleItem>> getCircles() async {
    try {
      final response = await _dio.get('/circles/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => CircleItem.fromJson(item)).toList();
      }

      throw Exception('获取社团列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取所有声优列表
  Future<List<VoiceActor>> getVoiceActors() async {
    try {
      final response = await _dio.get('/vas/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => VoiceActor.fromJson(item)).toList();
      }

      throw Exception('获取声优列表失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取作品详细信息
  Future<WorkInfo> getWorkInfo(String workId, {CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get('/workInfo/$workId', cancelToken: cancelToken);

      if (response.statusCode == 200) {
        return WorkInfo.fromJson(response.data);
      }

      throw Exception('获取作品详情失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }

  /// 获取播放列表中的作品
  Future<WorksResponse> getPlaylistWorks({
    required String playlistId,
    int page = 1,
    int pageSize = 12,
  }) async {
    try {
      final response = await _dio.get(
        '/playlist/get-playlist-works',
        queryParameters: {
          'id': playlistId,
          'page': page,
          'pageSize': pageSize,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> works = response.data['works'] ?? [];
        final pagination = Pagination.fromJson(response.data['pagination']);

        return WorksResponse(
          works: works.map((work) => Work.fromJson(work)).toList(),
          pagination: pagination,
        );
      }

      throw Exception('获取播放列表作品失败: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('网络请求失败', e, e.stackTrace);
      throw NetworkException.fromDioException(e);
    } catch (e, stackTrace) {
      AppLogger.error('解析数据失败', e, stackTrace);
      throw Exception('解析数据失败: $e');
    }
  }
}
