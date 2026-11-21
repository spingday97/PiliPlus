import 'package:PiliPlus/common/widgets/appbar/appbar.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/keep_alive_wrapper.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart'
    show tabBarScrollPhysics;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/pages/history/base_controller.dart';
import 'package:PiliPlus/pages/history/controller.dart';
import 'package:PiliPlus/pages/history/widgets/item.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.type, this.isTab = false});

  final String? type;
  final bool isTab;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final HistoryController _historyController;

  @override
  void initState() {
    super.initState();
    _historyController = Get.put(
      HistoryController(widget.type),
      tag: widget.type ?? 'all',
    );
  }

  @override
  void dispose() {
    Get.delete<HistoryController>(tag: widget.type ?? 'all');
    super.dispose();
  }

  @override
  bool get wantKeepAlive => widget.isTab;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isModern = Pref.modernCardUi;
    Widget child = Obx(
      () => _buildBody(_historyController.loadingState.value),
    );
    if (!widget.isTab) {
      child = SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            if (_historyController.tabs.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: isModern
                    ? TabBar(
                        controller: _historyController.tabController,
                        dividerHeight: 0,
                        isScrollable: true,
                        tabAlignment: .start,
                        padding: const .symmetric(horizontal: 14),
                        dividerColor: Colors.transparent,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorWeight: 0,
                        indicatorPadding: const .symmetric(vertical: 6),
                        indicator: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: .circular(18),
                        ),
                        labelColor: theme.colorScheme.onPrimary,
                        unselectedLabelColor: theme.colorScheme.onSurface,
                        labelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.normal,
                        ),
                        onTap: (index) {
                          if (!_historyController.tabController.indexIsChanging) {
                            _historyController.tabs[index].ctr.scrollController
                                .animToTop();
                          } else {
                            final ctr = _historyController.tabs[index].ctr;
                            if (ctr.loadingState.value is! Success) {
                              ctr.onReload();
                            }
                          }
                        },
                        tabs: _historyController.tabs
                            .map((e) => Tab(text: e.label))
                            .toList(),
                      )
                    : TabBar(
                        controller: _historyController.tabController,
                        onTap: (index) {
                          if (!_historyController.tabController.indexIsChanging) {
                            _historyController.tabs[index].ctr.scrollController
                                .animToTop();
                          } else {
                            final ctr = _historyController.tabs[index].ctr;
                            if (ctr.loadingState.value is! Success) {
                              ctr.onReload();
                            }
                          }
                        },
                        tabs: _historyController.tabs
                            .map((e) => Tab(text: e.label))
                            .toList(),
                      ),
              ),
            Expanded(
              child: _historyController.tabs.isNotEmpty
                  ? TabBarView(
                      physics: tabBarScrollPhysics,
                      controller: _historyController.tabController,
                      children: _historyController.tabs
                          .map(
                            (e) => KeepAliveWrapper(
                              child: HistoryPage(
                                type: e.type,
                                isTab: true,
                              ),
                            ),
                          )
                          .toList(),
                    )
                  : child,
            ),
          ],
        ),
      );
      child = popScope(
        canPop: !_historyController.baseCtr.enableMultiSelect.value,
        onPopInvokedWithResult: (didPop, result) {
          if (_historyController.baseCtr.enableMultiSelect.value) {
            _historyController.baseCtr.handleSelect();
          }
        },
        child: SimpleScaffold(
          appBar: _buildAppBar(theme),
          body: child,
        ),
      );
    }
    return child;
  }

  PreferredSizeWidget? _buildAppBar(ThemeData theme) {
    if (widget.isTab) return null;
    final colorScheme = theme.colorScheme;
    final isModern = Pref.modernCardUi;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Obx(() {
        final enableMultiSelect =
            _historyController.baseCtr.enableMultiSelect.value;
        if (enableMultiSelect) {
          return AppBar(
            leading: IconButton(
              tooltip: '关闭',
              onPressed: _historyController.baseCtr.handleSelect,
              icon: const Icon(Icons.close_outlined),
            ),
            title: Text(
              '已选择${_historyController.baseCtr.checkedCount.value}项',
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () =>
                    _historyController.baseCtr.handleSelect(checked: true),
                child: const Text('全选'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () =>
                    _historyController.baseCtr.onDelCheckedHistory(context),
                child: Text(
                  '删除',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
              const SizedBox(width: 6),
            ],
          );
        }

        if (isModern) {
          return AppBar(
            titleSpacing: 18,
            title: Text(
              '历史',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: colorScheme.onSurface,
              ),
            ),
            actions: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: .circle,
                  border: .all(
                    color: colorScheme.outline.withValues(alpha: 0.16),
                    width: 0.8,
                  ),
                ),
                child: IconButton(
                  tooltip: '搜索',
                  padding: EdgeInsets.zero,
                  onPressed: () => Get.toNamed('/historySearch'),
                  icon: Icon(
                    Icons.search,
                    size: 20,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'pause':
                      _historyController.baseCtr.onPauseHistory(context);
                    case 'clear':
                      _historyController.baseCtr.onClearHistory(context);
                    case 'select':
                      _historyController.baseCtr.handleSelect();
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'pause',
                    child: Text(
                      !_historyController.baseCtr.pauseStatus.value
                          ? '暂停历史记录'
                          : '恢复历史记录',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Text('清空历史记录'),
                  ),
                  const PopupMenuItem(
                    value: 'select',
                    child: Text('多选'),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          );
        }

        return AppBar(
          titleSpacing: 0,
          title: GestureDetector(
            onTap: () => Get.toNamed('/historySearch'),
            child: Container(
              height: 38,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.65,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    size: 18,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '搜索历史记录',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              tooltip: '多选',
              onPressed: _historyController.baseCtr.handleSelect,
              icon: const Icon(Icons.checklist),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'pause':
                    _historyController.baseCtr.onPauseHistory(context);
                  case 'clear':
                    _historyController.baseCtr.onClearHistory(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pause',
                  child: Text(
                    !_historyController.baseCtr.pauseStatus.value
                        ? '暂停历史记录'
                        : '恢复历史记录',
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear',
                  child: Text('清空历史记录'),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        );
      }),
    );
  }

  Widget _buildContinueWatchingStrip(
    ThemeData theme,
    List<HistoryData> items,
  ) {
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        Padding(
          padding: const .fromLTRB(14, 10, 14, 8),
          child: Text(
            '继续观看',
            style: TextStyle(
              fontSize: 15,
              fontWeight: .w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(
          height: 146,
          child: ListView.separated(
            scrollDirection: .horizontal,
            padding: const .symmetric(horizontal: 14),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final cover = item.cover?.isNotEmpty == true
                  ? item.cover!
                  : (item.covers?.firstOrNull ?? '');
              final duration = item.duration ?? 0;
              final progress = item.progress ?? 0;
              final double? progressRatio = duration > 0
                  ? (progress == -1
                        ? 1.0
                        : (progress > 0
                              ? (progress / duration).clamp(0.0, 1.0)
                              : null))
                  : null;
              return SizedBox(
                width: 172,
                child: Material(
                  color: colorScheme.surface,
                  borderRadius: .circular(12),
                  clipBehavior: .antiAlias,
                  child: InkWell(
                    onTap: () {
                      if (item.history?.bvid != null) {
                        PageUtils.toVideoPage(
                          bvid: item.history!.bvid,
                          cid: item.history!.cid ?? 0,
                          cover: cover,
                          title: item.title,
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Stack(
                          children: [
                            NetworkImgLayer(
                              src: cover,
                              width: 172,
                              height: 96,
                            ),
                            if (progressRatio != null)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LinearProgressIndicator(
                                  value: progressRatio,
                                  minHeight: 3,
                                  backgroundColor: Colors.black38,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const .fromLTRB(8, 6, 8, 6),
                          child: Text(
                            item.title ?? '',
                            maxLines: 2,
                            overflow: .ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.25,
                              fontWeight: .w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildBody(LoadingState<List<HistoryData>?> loadingState) {
    final theme = Theme.of(context);
    final isModern = Pref.modernCardUi;
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) => () {
        if (response == null || response.isEmpty) {
          return HttpError(
            onReload: _historyController.onReload,
          );
        }
        final continueItems = (isModern && !widget.isTab)
            ? response
                  .where(
                    (e) =>
                        (e.cover?.isNotEmpty == true) ||
                        (e.covers?.isNotEmpty == true),
                  )
                  .take(6)
                  .toList()
            : const <HistoryData>[];
        return refreshIndicator(
          onRefresh: _historyController.onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _historyController.scrollController,
            slivers: [
              if (continueItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: _buildContinueWatchingStrip(theme, continueItems),
                ),
              SliverPadding(
                padding: EdgeInsets.only(
                  top: 7,
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: gridDelegate,
                  itemCount: response.length,
                  itemBuilder: (context, index) {
                    if (index == response.length - 1) {
                      _historyController.onLoadMore();
                    }
                    final item = response[index];
                    return HistoryItem(
                      item: item,
                      ctr: _historyController.baseCtr,
                      onChoose: () =>
                          _historyController.baseCtr.onSelect(item),
                      onDelete: (kid, business) =>
                          _historyController.baseCtr.delHistory(
                            item,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }(),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _historyController.onReload,
      ),
    };
  }
}
