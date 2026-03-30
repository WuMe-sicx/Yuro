import 'package:flutter/material.dart';
import 'package:asmrapp/common/constants/strings.dart';
import 'package:asmrapp/core/audio/cache/audio_cache_manager.dart';
import 'package:asmrapp/core/cache/cache_lifecycle_manager.dart';
import 'package:asmrapp/presentation/viewmodels/auth_viewmodel.dart';
import 'core/di/service_locator.dart';
import 'package:provider/provider.dart';
import 'screens/main_screen.dart';
import 'package:asmrapp/core/theme/app_theme.dart';
import 'package:asmrapp/core/theme/theme_controller.dart';
import 'screens/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化服务定位器
  await setupServiceLocator();

  // Initialize cache lifecycle manager (handles startup + resume cleanup)
  CacheLifecycleManager().initialize();
  // One-time legacy cache migration
  AudioCacheManager.cleanLegacyCache();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => getIt<AuthViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<ThemeController>(),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            title: Strings.appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeController.themeMode,
            home: const MainScreen(),
            routes: {
              // '/player': (context) => const PlayerScreen(),
              '/search': (context) {
                final keyword =
                    ModalRoute.of(context)?.settings.arguments as String?;
                return SearchScreen(initialKeyword: keyword);
              },
            },
          );
        },
      ),
    );
  }
}
