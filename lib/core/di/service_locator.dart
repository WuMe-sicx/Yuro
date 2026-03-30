import 'dart:io';
import 'package:dio/dio.dart';
import 'package:asmrapp/data/services/interceptors/retry_interceptor.dart';
import 'package:asmrapp/data/services/interceptors/auth_interceptor.dart';
import 'package:asmrapp/core/platform/dummy_lyric_overlay_controller.dart';
import 'package:get_it/get_it.dart';
import '../audio/i_audio_player_service.dart';
import '../audio/audio_player_service.dart';
import '../../data/services/api_service.dart';
import '../../presentation/viewmodels/player_viewmodel.dart';
import '../../data/services/auth_service.dart';
import '../../presentation/viewmodels/auth_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/auth_repository.dart';
import '../subtitle/i_subtitle_service.dart';
import '../subtitle/subtitle_service.dart';
import '../subtitle/subtitle_loader.dart';
import '../../core/audio/storage/i_playback_state_repository.dart';
import '../../core/audio/storage/playback_state_repository.dart';
import '../audio/events/playback_event_hub.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/platform/i_lyric_overlay_controller.dart';
import '../../core/platform/lyric_overlay_controller.dart';
import '../../core/platform/lyric_overlay_manager.dart';
import '../../core/platform/wakelock_controller.dart';
import 'package:asmrapp/core/settings/app_settings_service.dart';
import 'package:asmrapp/core/database/database_service.dart';
import 'package:asmrapp/core/subtitle/storage/i_user_subtitle_repository.dart';
import 'package:asmrapp/core/subtitle/storage/user_subtitle_repository.dart';
import 'package:asmrapp/core/subtitle/import/i_file_picker_service.dart';
import 'package:asmrapp/core/subtitle/import/file_picker_service.dart';
import 'package:asmrapp/core/subtitle/subtitle_import_service.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  final prefs = await SharedPreferences.getInstance();

  // 注册 EventHub
  getIt.registerLazySingleton(() => PlaybackEventHub());

  // 注册 SharedPreferences 实例
  getIt.registerSingleton<SharedPreferences>(prefs);

  // 数据库服务
  getIt.registerLazySingleton<DatabaseService>(() => DatabaseService());

  // 用户字幕存储
  getIt.registerLazySingleton<IUserSubtitleRepository>(
    () => UserSubtitleRepository(getIt<DatabaseService>()),
  );

  // 文件选择器
  getIt.registerLazySingleton<IFilePickerService>(() => FilePickerService());

  // 字幕导入服务
  getIt.registerLazySingleton<SubtitleImportService>(
    () => SubtitleImportService(
      picker: getIt<IFilePickerService>(),
      repository: getIt<IUserSubtitleRepository>(),
    ),
  );

  // 注册 PlaybackStateRepository
  getIt.registerLazySingleton<IPlaybackStateRepository>(
    () => PlaybackStateRepository(getIt()),
  );

  // 核心服务
  getIt.registerLazySingleton<IAudioPlayerService>(
    () => AudioPlayerService(
      eventHub: getIt(),
      stateRepository: getIt(),
    ),
  );

  // 注册 PlayerViewModel
  getIt.registerLazySingleton<PlayerViewModel>(
    () => PlayerViewModel(
      audioService: getIt(),
      eventHub: getIt(),
      subtitleService: getIt(),
    ),
  );

  // 注册 AppSettingsService
  getIt.registerSingleton<AppSettingsService>(
    AppSettingsService(prefs),
  );

  // API 服务
  getIt.registerLazySingleton<ApiService>(
    () => ApiService(settings: getIt<AppSettingsService>()),
  );

  // 添加 AuthService 注册
  getIt.registerLazySingleton<AuthService>(
    () => AuthService(),
  );

  // 添加 AuthRepository 注册
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(prefs),
  );

  // 修改 AuthViewModel 注册
  getIt.registerSingleton<AuthViewModel>(
    AuthViewModel(
      authService: getIt<AuthService>(),
      authRepository: getIt<AuthRepository>(),
    ),
  );

  // 等待 AuthViewModel 完成初始化
  await getIt<AuthViewModel>().loadSavedAuth();

  // 添加字幕服务注册
  getIt.registerLazySingleton<ISubtitleService>(
    () => SubtitleService(),
  );

  await setupSubtitleServices();

  // 注册主题控制器
  getIt.registerLazySingleton<ThemeController>(
    () => ThemeController(prefs),
  );

  // 注册 WakeLockController
  getIt.registerLazySingleton(() => WakeLockController(prefs));
}

Future<void> setupSubtitleServices() async {
  getIt.registerLazySingleton<SubtitleLoader>(() {
    final dio = Dio();
    dio.interceptors.add(RetryInterceptor(dio: dio));
    dio.interceptors.add(AuthInterceptor());
    return SubtitleLoader(dio: dio);
  });
  if (Platform.isAndroid) {
    getIt.registerLazySingleton<ILyricOverlayController>(() => LyricOverlayController());
  } else {
    getIt.registerLazySingleton<ILyricOverlayController>(() => DummyLyricOverlayController());
  }
  getIt.registerLazySingleton(() => LyricOverlayManager(
    controller: getIt(),
    subtitleService: getIt(),
  ));

  // 初始化悬浮窗管理器
  await getIt<LyricOverlayManager>().initialize();
}
