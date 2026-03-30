import 'package:asmrapp/core/theme/app_animations.dart';
import 'package:asmrapp/screens/contents/favorites_content.dart';
import 'package:flutter/material.dart';
import 'package:asmrapp/widgets/mini_player/mini_player.dart';
import 'package:asmrapp/widgets/sidebar/sidebar_menu.dart';
import 'package:asmrapp/screens/contents/home_content.dart';
import 'package:asmrapp/screens/contents/recommend_content.dart';
import 'package:asmrapp/screens/contents/popular_content.dart';
import 'package:asmrapp/screens/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:asmrapp/presentation/viewmodels/home_viewmodel.dart';
import 'package:asmrapp/presentation/viewmodels/popular_viewmodel.dart';
import 'package:asmrapp/presentation/viewmodels/recommend_viewmodel.dart';
import 'package:asmrapp/presentation/viewmodels/auth_viewmodel.dart';
import 'package:asmrapp/presentation/viewmodels/favorites_viewmodel.dart';

/// MainScreen 是应用的主界面，负责管理底部导航栏和对应的内容页面。
/// 它采用了集中式的状态管理架构，所有子页面的 ViewModel 都在这里初始化和提供。
///
/// 架构说明：
/// 1. ViewModel 初始化：所有页面的 ViewModel 都在 MainScreen 中初始化，确保单一实例
/// 2. 状态提供：通过 MultiProvider 将 ViewModel 提供给整个子树
/// 3. 生命周期管理：负责所有 ViewModel 的创建和销毁
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _pageController = PageController(initialPage: 1);
  int _currentIndex = 1;

  // 集中管理所有页面的 ViewModel
  // 这些 ViewModel 将通过 Provider 提供给子页面
  late final HomeViewModel _homeViewModel;
  late final PopularViewModel _popularViewModel;
  late final RecommendViewModel _recommendViewModel;
  late final FavoritesViewModel _favoritesViewModel;

  final _titles = const ['收藏', '主页', '为你推荐', '热门作品'];

  // 页面内容列表
  // 注意：这些页面不应该创建自己的 ViewModel 实例
  // 而是应该通过 Provider.of 或 context.read 获取 MainScreen 提供的实例
  final _pages = const [
    FavoritesContent(),
    HomeContent(),
    RecommendContent(),
    PopularContent(),
  ];

  @override
  void initState() {
    super.initState();
    // 初始化所有 ViewModel
    // 注意初始化顺序，如果有依赖关系需要先初始化依赖项
    _homeViewModel = HomeViewModel();
    _popularViewModel = PopularViewModel();
    _recommendViewModel = RecommendViewModel(
      Provider.of<AuthViewModel>(context, listen: false),
    );
    _favoritesViewModel = FavoritesViewModel(
      Provider.of<AuthViewModel>(context, listen: false),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: AppAnimations.medium,
      curve: AppAnimations.standard,
    );
  }

  @override
  void dispose() {
    // 确保所有 ViewModel 都被正确释放
    _pageController.dispose();
    _homeViewModel.dispose();
    _popularViewModel.dispose();
    _recommendViewModel.dispose();
    _favoritesViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // 通过 MultiProvider 将所有 ViewModel 提供给子树
      // 这样子页面就可以通过 Provider.of 或 context.read 获取对应的 ViewModel
      providers: [
        ChangeNotifierProvider.value(value: _homeViewModel),
        ChangeNotifierProvider.value(value: _popularViewModel),
        ChangeNotifierProvider.value(value: _recommendViewModel),
        ChangeNotifierProvider.value(value: _favoritesViewModel),
      ],
      child: Builder(
        builder: (context) {
          // 根据当前页面获取对应的总数
          final totalCount = _currentIndex == 0
              ? context.watch<FavoritesViewModel>().totalCount
              : _currentIndex == 1
                  ? context.watch<HomeViewModel>().pagination?.totalCount
                  : _currentIndex == 2
                      ? context.watch<RecommendViewModel>().pagination?.totalCount
                      : _currentIndex == 3
                          ? context.watch<PopularViewModel>().pagination?.totalCount
                          : null;

          // 构建标题文本
          final title = totalCount != null
              ? '${_titles[_currentIndex]} ($totalCount)'
              : _titles[_currentIndex];

          return Scaffold(
            appBar: AppBar(
              title: Text(title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    if (_currentIndex == 1) {
                      context.read<HomeViewModel>().toggleFilterPanel();
                    } else if (_currentIndex == 2) {
                      context.read<RecommendViewModel>().toggleFilterPanel();
                    } else if (_currentIndex == 3) {
                      context.read<PopularViewModel>().toggleFilterPanel();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SearchScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            drawer: const SidebarMenu(),
            body: PageView(
              controller: _pageController,
              physics: const ClampingScrollPhysics(),
              onPageChanged: _onPageChanged,
              children: _pages,
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MiniPlayer(),
                NavigationBar(
                  height: 60,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 0,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onTabTapped,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.favorite_outline),
                      selectedIcon: Icon(Icons.favorite),
                      label: '收藏',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: '主页',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.recommend_outlined),
                      selectedIcon: Icon(Icons.recommend),
                      label: '推荐',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.trending_up_outlined),
                      selectedIcon: Icon(Icons.trending_up),
                      label: '热门',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 