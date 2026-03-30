import 'package:flutter/foundation.dart';
import 'package:asmrapp/data/models/works/work.dart';
import 'package:asmrapp/data/models/works/pagination.dart';
import 'package:asmrapp/data/services/api_service.dart';
import 'package:asmrapp/presentation/viewmodels/auth_viewmodel.dart';
import 'package:asmrapp/utils/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendViewModel extends ChangeNotifier {
  static const _subtitleFilterKey = 'subtitle_filter'; // 与 PopularViewModel 使用相同的 key 实现全局共享
  final ApiService _apiService;
  final AuthViewModel _authViewModel;
  List<Work> _works = [];
  bool _isLoading = false;
  String? _error;
  Pagination? _pagination;
  int _currentPage = 1;
  bool _hasSubtitle = false;
  bool _filterPanelExpanded = false;

  RecommendViewModel(this._authViewModel) : _apiService = GetIt.I<ApiService>() {
    _loadFilterState();
  }

  // 加载筛选状态
  Future<void> _loadFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSubtitle = prefs.getBool(_subtitleFilterKey) ?? false;
      // 首次加载时应用筛选状态
      loadRecommendations(refresh: true);
    } catch (e) {
      AppLogger.error('加载筛选状态失败', e);
    }
  }

  // 保存筛选状态
  Future<void> _saveFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_subtitleFilterKey, _hasSubtitle);
    } catch (e) {
      AppLogger.error('保存筛选状态失败', e);
    }
  }

  // Getters
  List<Work> get works => _works;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int? get totalPages =>
      _pagination?.totalCount != null && _pagination?.pageSize != null
          ? (_pagination!.totalCount! / _pagination!.pageSize!).ceil()
          : null;
  bool get hasSubtitle => _hasSubtitle;
  bool get filterPanelExpanded => _filterPanelExpanded;

  Pagination? get pagination => _pagination;

  // 切换字幕筛选
  void toggleSubtitleFilter() {
    _hasSubtitle = !_hasSubtitle;
    _saveFilterState(); // 保存状态
    notifyListeners();
    loadRecommendations(refresh: true); // 刷新列表
  }

  void toggleFilterPanel() {
    _filterPanelExpanded = !_filterPanelExpanded;
    notifyListeners();
  }

  void closeFilterPanel() {
    if (_filterPanelExpanded) {
      _filterPanelExpanded = false;
      notifyListeners();
    }
  }

  /// 加载指定页面的数据
  Future<void> loadPage(int page) async {
    if (_isLoading) return;
    if (page < 1 || (totalPages != null && page > totalPages!)) return;
    
    // 检查是否已登录
    final uuid = _authViewModel.recommenderUuid;
    if (uuid == null) {
      _error = '请先登录';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getRecommendations(
        uuid: uuid,
        page: page,
        hasSubtitle: _hasSubtitle, // 添加字幕筛选参数
      );
      _works = response.works;
      _pagination = response.pagination;
      _currentPage = page;
      AppLogger.info('第$page页推荐列表加载成功: ${response.works.length}个作品');
    } catch (e) {
      AppLogger.error('加载推荐列表失败', e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载推荐列表(用于初始加载和刷新)
  Future<void> loadRecommendations({bool refresh = false}) async {
    await loadPage(1);
  }

  @override
  void dispose() {
    _saveFilterState(); // 在销毁时保存状态
    super.dispose();
  }
} 