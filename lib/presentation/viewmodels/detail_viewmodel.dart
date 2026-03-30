import 'package:asmrapp/data/models/playlists_with_exist_statu/pagination.dart';
import 'package:asmrapp/data/models/playlists_with_exist_statu/playlist.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:asmrapp/data/models/files/files.dart';
import 'package:asmrapp/data/models/files/child.dart';
import 'package:asmrapp/data/models/works/work.dart';
import 'package:asmrapp/data/services/api_service.dart';
import 'package:asmrapp/core/audio/i_audio_player_service.dart';
import 'package:asmrapp/utils/logger.dart';
import 'package:asmrapp/core/audio/models/playback_context.dart';
import 'package:asmrapp/widgets/detail/playlist_selection_dialog.dart';
import 'package:asmrapp/data/models/mark_status.dart';
import 'package:asmrapp/widgets/detail/mark_selection_dialog.dart';
import 'package:asmrapp/data/models/works/work_info.dart';
import 'package:asmrapp/widgets/detail/work_folder_item.dart';
import 'package:dio/dio.dart';

class DetailViewModel extends ChangeNotifier {
  late final ApiService _apiService;
  late final IAudioPlayerService _audioService;
  final Work work;

  Files? _files;
  bool _isLoading = false;
  String? _error;
  bool _disposed = false;

  WorkInfo? _workInfo;
  bool _isLoadingInfo = false;

  bool _hasRecommendations = false;
  bool _checkingRecommendations = false;

  // 收藏夹相关状态
  bool _loadingPlaylists = false;
  String? _playlistsError;
  List<Playlist>? _playlists;
  Pagination? _playlistsPagination;

  bool _loadingFavorite = false;
  bool get loadingFavorite => _loadingFavorite;

  MarkStatus? _currentMarkStatus;
  MarkStatus? get currentMarkStatus => _currentMarkStatus;

  bool _loadingMark = false;
  bool get loadingMark => _loadingMark;

  // 添加取消标记
  final _cancelToken = CancelToken();

  DetailViewModel({
    required this.work,
  }) {
    _audioService = GetIt.I<IAudioPlayerService>();
    _apiService = GetIt.I<ApiService>();
    _checkRecommendations();
  }

  Files? get files => _files;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasRecommendations => _hasRecommendations;
  bool get checkingRecommendations => _checkingRecommendations;
  WorkInfo? get workInfo => _workInfo;
  bool get isLoadingInfo => _isLoadingInfo;

  // 收藏夹相关 getters
  bool get loadingPlaylists => _loadingPlaylists;
  String? get playlistsError => _playlistsError;
  List<Playlist>? get playlists => _playlists;
  int? get playlistsTotalPages => 
      _playlistsPagination?.totalCount != null && _playlistsPagination?.pageSize != null
          ? (_playlistsPagination!.totalCount! / _playlistsPagination!.pageSize!).ceil()
          : null;

  Future<void> _checkRecommendations() async {
    _checkingRecommendations = true;
    notifyListeners();

    try {
      final response = await _apiService.getItemNeighbors(
        itemId: work.id.toString(),
        page: 1,
      );
      _hasRecommendations = (response.pagination.totalCount ?? 0) > 0;
    } catch (e) {
      AppLogger.error('检查相关推荐失败', e);
      _hasRecommendations = false;
    } finally {
      if (!_disposed) {
        _checkingRecommendations = false;
        notifyListeners();
      }
    }
  }

  /// Batch-load files and work info with minimal notifyListeners calls.
  /// Called once from the screen instead of separate loadFiles + loadWorkInfo.
  Future<void> loadInitialData() async {
    _isLoading = true;
    _isLoadingInfo = true;
    _error = null;
    notifyListeners(); // Single notify for "loading started"

    // Run both fetches concurrently
    await Future.wait([
      _loadFilesInternal(),
      _loadWorkInfoInternal(),
    ]);

    if (!_disposed) {
      notifyListeners(); // Single notify for "loading complete"
    }
  }

  Future<void> _loadFilesInternal() async {
    try {
      AppLogger.info('开始加载作品文件: ${work.id}');
      _files = await _apiService.getWorkFiles(
        work.id.toString(),
        cancelToken: _cancelToken,
      );
      WorkFolderItem.resetExpandState(); // Reset on new data load, not on every build
      AppLogger.info('文件加载成功: ${work.id}');
    } catch (e) {
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        AppLogger.info('加载文件失败');
        _error = e.toString();
      }
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadWorkInfoInternal() async {
    try {
      final workId = _extractNumericId(work.sourceId) ?? work.id.toString();
      _workInfo = await _apiService.getWorkInfo(workId, cancelToken: _cancelToken);
      AppLogger.info('作品详情加载成功: ${work.id}');
    } catch (e) {
      if (e is! DioException || e.type != DioExceptionType.cancel) {
        AppLogger.error('加载作品详情失败', e);
      }
    } finally {
      _isLoadingInfo = false;
    }
  }

  Future<void> loadWorkInfo() async {
    if (_isLoadingInfo) return;
    _isLoadingInfo = true;
    notifyListeners();
    await _loadWorkInfoInternal();
    if (!_disposed) notifyListeners();
  }

  Future<void> loadFiles() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _loadFilesInternal();
    if (!_disposed) notifyListeners();
  }

  Future<void> playFile(Child file, BuildContext context) async {
    if (file.type?.toLowerCase() != 'audio') {
      throw Exception('不支持的文件类型: ${file.type}');
    }

    if (file.mediaDownloadUrl == null) {
      throw Exception('无法播放：文件URL不存在');
    }

    if (_files == null) {
      throw Exception('文件列表未加载');
    }

    try {
      final playbackContext = PlaybackContext(
        work: work,
        files: _files!,
        currentFile: file,
      );

      await _audioService.playWithContext(playbackContext);
    } catch (e) {
      if (!_disposed) {
        AppLogger.error('播放失败', e);
      }
      rethrow;
    }
  }

  /// 加载收藏夹列表
  Future<void> loadPlaylists({int page = 1}) async {
    if (_loadingPlaylists) return;

    _loadingPlaylists = true;
    _playlistsError = null;
    notifyListeners();

    try {
      final response = await _apiService.getWorkExistStatusInPlaylists(
        workId: work.id.toString(),
        page: page,
      );
      
      _playlists = response.playlists;
      _playlistsPagination = response.pagination;
      AppLogger.info('收藏夹列表加载成功: ${_playlists?.length ?? 0}个收藏夹');
    } catch (e) {
      AppLogger.error('加载收藏夹列表失败', e);
      _playlistsError = e.toString();
    } finally {
      _loadingPlaylists = false;
      notifyListeners();
    }
  }

  Future<void> showPlaylistsDialog(BuildContext context) async {
    _loadingFavorite = true;
    notifyListeners();
    
    try {
      await loadPlaylists();
      _loadingFavorite = false;
      notifyListeners();
      
      if (!context.mounted) return;
      
      await showDialog(
        context: context,
        builder: (context) => PlaylistSelectionDialog(
          playlists: playlists,
          isLoading: loadingPlaylists,
          error: playlistsError,
          onRetry: () => loadPlaylists(),
          onPlaylistTap: (playlist) async {
            try {
              await togglePlaylistWork(playlist);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('操作失败: $e')),
                );
              }
            }
          },
        ),
      );
    } catch (e) {
      _loadingFavorite = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> togglePlaylistWork(Playlist playlist) async {
    try {
      if (playlist.exist ?? false) {
        await _apiService.removeWorkFromPlaylist(
          playlistId: playlist.id!,
          workId: work.id.toString(),
        );
      } else {
        await _apiService.addWorkToPlaylist(
          playlistId: playlist.id!,
          workId: work.id.toString(),
        );
      }
      
      // 更新本地收藏夹状态
      final index = _playlists?.indexWhere((p) => p.id == playlist.id);
      if (index != null && index != -1) {
        _playlists = List<Playlist>.from(_playlists!)
          ..[index] = playlist.copyWith(exist: !(playlist.exist ?? false));
        notifyListeners();
      }
      
      final action = (playlist.exist ?? false) ? '移除' : '添加';
      AppLogger.info('$action收藏成功: ${playlist.name}');
    } catch (e) {
      AppLogger.error('切换收藏状态失败', e);
      rethrow;
    }
  }

  Future<void> updateMarkStatus(MarkStatus status) async {
    _loadingMark = true;
    notifyListeners();

    try {
      await _apiService.updateWorkMarkStatus(
        work.id.toString(),
        _apiService.convertMarkStatusToApi(status),
      );
      
      _currentMarkStatus = status;
      AppLogger.info('更新标记状态成功: ${status.label}');
    } catch (e) {
      AppLogger.error('更新标记状态失败', e);
      rethrow;
    } finally {
      _loadingMark = false;
      notifyListeners();
    }
  }

  void showMarkDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => MarkSelectionDialog(
        currentStatus: _currentMarkStatus,
        loading: _loadingMark,
        onMarkSelected: (status) async {
          try {
            await updateMarkStatus(status);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已标记为${status.label}'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('标记失败: $e')),
              );
            }
          }
        },
      ),
    );
  }

  String? _extractNumericId(String? sourceId) {
    if (sourceId == null) return null;
    final match = RegExp(r'\d+').firstMatch(sourceId);
    return match?.group(0);
  }

  @override
  void dispose() {
    // 取消所有正在进行的请求
    _cancelToken.cancel('ViewModel disposed');
    _disposed = true;
    super.dispose();
  }
}
