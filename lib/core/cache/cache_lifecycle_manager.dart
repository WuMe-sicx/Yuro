import 'package:flutter/widgets.dart';
import 'package:asmrapp/core/cache/cache_coordinator.dart';
import 'package:asmrapp/utils/logger.dart';

/// 缓存生命周期管理器
/// 监听应用生命周期事件，自动触发缓存维护
class CacheLifecycleManager with WidgetsBindingObserver {
  static final CacheLifecycleManager _instance = CacheLifecycleManager._internal();
  factory CacheLifecycleManager() => _instance;
  CacheLifecycleManager._internal();

  bool _initialized = false;
  bool _isCleanupRunning = false;
  DateTime? _lastCleanup;
  static const _minCleanupInterval = Duration(hours: 6);

  /// 初始化并注册为生命周期观察者（幂等）
  void initialize() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _triggerCleanup();
  }

  /// 注销观察者
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerCleanup();
    }
  }

  void _triggerCleanup() {
    if (_isCleanupRunning) return;
    if (_lastCleanup != null &&
        DateTime.now().difference(_lastCleanup!) < _minCleanupInterval) {
      return;
    }

    _isCleanupRunning = true;
    CacheCoordinator().cleanAll().then((_) {
      _lastCleanup = DateTime.now();
      AppLogger.debug('自动缓存清理完成');
    }).catchError((e) {
      AppLogger.error('自动缓存清理失败', e);
    }).whenComplete(() {
      _isCleanupRunning = false;
    });
  }
}
