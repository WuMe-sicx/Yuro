import 'package:asmrapp/core/theme/app_animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asmrapp/widgets/sidebar/sidebar_menu.dart';
import 'package:asmrapp/presentation/viewmodels/auth_viewmodel.dart';
import 'package:asmrapp/presentation/viewmodels/favorites_viewmodel.dart';
import 'package:asmrapp/presentation/layouts/work_layout_strategy.dart';
import 'package:asmrapp/widgets/pagination_controls.dart';
import 'package:asmrapp/widgets/work_grid_view.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _layoutStrategy = const WorkLayoutStrategy();
  final _scrollController = ScrollController();
  late FavoritesViewModel _viewModel;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      _viewModel = FavoritesViewModel(authViewModel);
      _viewModel.loadFavorites();
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) async {
    await _viewModel.loadPage(page);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: AppAnimations.medium,
        curve: AppAnimations.enter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的收藏'),
        ),
        drawer: const SidebarMenu(),
        body: Consumer<FavoritesViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                Expanded(
                  child: WorkGridView(
                    works: viewModel.works,
                    isLoading: viewModel.isLoading,
                    error: viewModel.error,
                    onRetry: () => viewModel.loadFavorites(),
                    layoutStrategy: _layoutStrategy,
                    scrollController: _scrollController,
                    bottomWidget: viewModel.works.isNotEmpty
                        ? PaginationControls(
                            currentPage: viewModel.currentPage,
                            totalPages: viewModel.totalPages ?? 1,
                            onPageChanged: _onPageChanged,
                            isLoading: viewModel.isLoading,
                          )
                        : null,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
} 