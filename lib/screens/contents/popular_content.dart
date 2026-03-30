import 'package:asmrapp/core/theme/app_animations.dart';
import 'package:asmrapp/data/models/works/work.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asmrapp/presentation/viewmodels/popular_viewmodel.dart';
import 'package:asmrapp/presentation/layouts/work_layout_strategy.dart';
import 'package:asmrapp/widgets/work_grid/enhanced_work_grid_view.dart';
import 'package:asmrapp/widgets/filter/filter_with_keyword.dart';

class PopularContent extends StatefulWidget {
  const PopularContent({super.key});

  @override
  State<PopularContent> createState() => _PopularContentState();
}

class _PopularContentState extends State<PopularContent> with AutomaticKeepAliveClientMixin {
  final _layoutStrategy = const WorkLayoutStrategy();
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.minScrollExtent) return;
    context.read<PopularViewModel>().closeFilterPanel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        // Grid: only rebuilds when list data changes
        Selector<PopularViewModel, ({List<Work> works, bool isLoading, String? error, int currentPage, int? totalPages})>(
          selector: (_, vm) => (
            works: vm.works,
            isLoading: vm.isLoading,
            error: vm.error,
            currentPage: vm.currentPage,
            totalPages: vm.totalPages,
          ),
          builder: (context, data, child) {
            return EnhancedWorkGridView(
              works: data.works,
              isLoading: data.isLoading,
              error: data.error,
              currentPage: data.currentPage,
              totalPages: data.totalPages,
              onPageChanged: (page) => context.read<PopularViewModel>().loadPage(page),
              onRefresh: () => context.read<PopularViewModel>().loadPopular(refresh: true),
              onRetry: () => context.read<PopularViewModel>().loadPopular(refresh: true),
              layoutStrategy: _layoutStrategy,
              scrollController: _scrollController,
            );
          },
        ),
        // Filter panel: only rebuilds when filter state changes
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Selector<PopularViewModel, ({bool expanded, bool hasSubtitle})>(
            selector: (_, vm) => (
              expanded: vm.filterPanelExpanded,
              hasSubtitle: vm.hasSubtitle,
            ),
            builder: (context, data, child) {
              return AnimatedSlide(
                duration: AppAnimations.short,
                curve: AppAnimations.standard,
                offset: Offset(0, data.expanded ? 0 : -1),
                child: FilterWithKeyword(
                  hasSubtitle: data.hasSubtitle,
                  onSubtitleChanged: (_) => context.read<PopularViewModel>().toggleSubtitleFilter(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
