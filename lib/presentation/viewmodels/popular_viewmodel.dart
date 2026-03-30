import 'package:asmrapp/presentation/viewmodels/base/paginated_works_viewmodel.dart';
import 'package:asmrapp/data/services/api_service.dart';
import 'package:asmrapp/utils/logger.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PopularViewModel extends PaginatedWorksViewModel {
  static const _subtitleFilterKey = 'subtitle_filter';
  bool _hasSubtitle = false;
  bool _filterPanelExpanded = false;

  PopularViewModel() : super(GetIt.I<ApiService>());

  @override
  Future<void> onInit() async {
    await _loadSubtitleFilter();  // 使用 onInit 钩子加载状态
  }

  Future<void> _loadSubtitleFilter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSubtitle = prefs.getBool(_subtitleFilterKey) ?? false;
      notifyListeners();
    } catch (e) {
      AppLogger.error('加载字幕筛选状态失败', e);
    }
  }

  Future<void> _saveFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_subtitleFilterKey, _hasSubtitle);
    } catch (e) {
      AppLogger.error('保存筛选状态失败', e);
    }
  }

  bool get hasSubtitle => _hasSubtitle;
  bool get filterPanelExpanded => _filterPanelExpanded;

  void toggleSubtitleFilter() {
    _hasSubtitle = !_hasSubtitle;
    _saveFilterState();
    notifyListeners();
    refresh(); // 刷新列表
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

  @override
  String get pageName => '热门列表';

  @override
  Future<WorksResponse> fetchPage(int page) {
    return apiService.getPopular(
      page: page,
      hasSubtitle: _hasSubtitle,
    );
  }

  // 保持原有的便捷方法
  Future<void> loadPopular({bool refresh = false}) => 
    refresh ? this.refresh() : loadPage(1);

  @override
  void dispose() {
    _saveFilterState();
    super.dispose();
  }
} 