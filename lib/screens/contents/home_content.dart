import 'package:asmrapp/core/theme/app_animations.dart';
import 'package:asmrapp/data/models/works/work.dart';
import 'package:asmrapp/presentation/models/filter_state.dart';
import 'package:asmrapp/widgets/filter/filter_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:asmrapp/presentation/viewmodels/home_viewmodel.dart';
import 'package:asmrapp/presentation/layouts/work_layout_strategy.dart';
import 'package:asmrapp/widgets/work_grid/enhanced_work_grid_view.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent>
    with AutomaticKeepAliveClientMixin {
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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.minScrollExtent) return;
    context.read<HomeViewModel>().closeFilterPanel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      children: [
        // Grid: only rebuilds when list data changes
        Selector<HomeViewModel, ({List<Work> works, bool isLoading, String? error, int currentPage, int? totalPages})>(
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
              onPageChanged: (page) => context.read<HomeViewModel>().loadPage(page),
              onRefresh: () => context.read<HomeViewModel>().refresh(),
              onRetry: () => context.read<HomeViewModel>().refresh(),
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
          child: Selector<HomeViewModel, ({bool expanded, bool hasSubtitle, FilterState filterState})>(
            selector: (_, vm) => (
              expanded: vm.filterPanelExpanded,
              hasSubtitle: vm.hasSubtitle,
              filterState: vm.filterState,
            ),
            builder: (context, data, child) {
              return AnimatedSlide(
                duration: AppAnimations.short,
                curve: AppAnimations.standard,
                offset: Offset(0, data.expanded ? 0 : -1),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 8,
                        spreadRadius: 1,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: FilterPanel(
                    hasSubtitle: data.hasSubtitle,
                    onSubtitleChanged: context.read<HomeViewModel>().updateSubtitle,
                    orderField: data.filterState.orderField,
                    isDescending: data.filterState.isDescending,
                    onOrderFieldChanged: context.read<HomeViewModel>().updateOrderField,
                    onSortDirectionChanged: context.read<HomeViewModel>().updateSortDirection,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
