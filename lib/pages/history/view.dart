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

  HistoryController currCtr([int? index]) {
    try {
      index ??= _historyController.tabController!.index;
      if (index != 0) {
        return Get.find<HistoryController>(
          tag: _historyController.tabs[index - 1].type,
        );
      }
    } catch (_) {}
    return _historyController;
  }

  @override
  void dispose() {
    Get.delete<HistoryBaseController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final isModern = Pref.modernCardUi;
    Widget child = refreshIndicator(
      onRefresh: _historyController.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _historyController.scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: 14,
              right: 14,
              top: 8,
              bottom: padding.bottom + 100,
            ),
            sliver: Obx(
              () => _buildBody(_historyController.loadingState.value),
            ),
          ),
        ],
      ),
    );
    if (widget.type != null) {
      return child;
    }
    return Obx(
      () {
        final enableMultiSelect =
            _historyController.baseCtr.enableMultiSelect.value;
        final colorScheme = Theme.of(context).colorScheme;
        return popScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              currCtr().handleSelect();
            }
          },
          child: SimpleScaffold(
            appBar: MultiSelectAppBarWidget(
              visible: enableMultiSelect,
              ctr: currCtr(),
              child: _buildAppBar,
            ),
            body: Padding(
              padding: .only(left: padding.left, right: padding.right),
              child: Obx(() {
                final tabs = _historyController.tabs;
                if (tabs.isEmpty) {
                  return child;
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ?_buildPauseTip,
                    Padding(
                      padding: isModern
                          ? const .symmetric(horizontal: 14, vertical: 2)
                          : EdgeInsets.zero,
                      child: TabBar(
                        controller: _historyController.tabController,
                        dividerHeight: 0,
                        indicatorSize: isModern
                            ? TabBarIndicatorSize.tab
                            : TabBarIndicatorSize.label,
                        indicatorWeight: isModern ? 0 : 3,
                        indicatorPadding: isModern
                            ? const .symmetric(vertical: 4)
                            : EdgeInsets.zero,
                        indicator: isModern
                            ? BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: .circular(18),
                              )
                            : null,
                        indicatorColor: colorScheme.primary,
                        labelColor: isModern
                            ? colorScheme.onPrimary
                            : colorScheme.primary,
                        unselectedLabelColor: colorScheme.onSurface,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                        ),
                        onTap: (index) {
                          if (!(_historyController
                                  .tabController
                                  ?.indexIsChanging ??
                              false)) {
                            currCtr().scrollController.animToTop();
                          } else {
                            if (enableMultiSelect) {
                              currCtr(
                                _historyController.tabController!.previousIndex,
                              ).handleSelect();
                            }
                          }
                        },
                        tabs: [
                          const Tab(height: 38, text: '全部'),
                          ...tabs.map((item) => Tab(height: 38, text: item.name)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        physics: enableMultiSelect
                            ? const NeverScrollableScrollPhysics()
                            : tabBarScrollPhysics,
                        controller: _historyController.tabController,
                        horizontalDragGestureRecognizer:
                            CustomHorizontalDragGestureRecognizer.new,
                        children: [
                          KeepAliveWrapper(child: child),
                          ...tabs.map(
                            (item) => HistoryPage(type: item.type),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  AppBar get _buildAppBar {
    final colorScheme = Theme.of(context).colorScheme;
    final isModern = Pref.modernCardUi;
    final menuBtn = PopupMenuButton(
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: () => _historyController.baseCtr.onPauseHistory(context),
          child: Text(
            !_historyController.baseCtr.pauseStatus.value
                ? '暂停观看记录'
                : '恢复观看记录',
          ),
        ),
        PopupMenuItem(
          onTap: () => _historyController.baseCtr.onClearHistory(
            context,
            () {
              _historyController.loadingState.value = const Success(null);
              if (_historyController.tabController != null) {
                for (final item in _historyController.tabs) {
                  try {
                    Get.find<HistoryController>(
                      tag: item.type,
                    ).loadingState.value = const Success(
                      null,
                    );
                  } catch (_) {}
                }
              }
            },
          ),
          child: const Text('清空观看记录'),
        ),
        PopupMenuItem(
          onTap: currCtr().onDelViewedHistory,
          child: const Text('删除已看记录'),
        ),
      ],
    );
    if (isModern) {
      return AppBar(
        automaticallyImplyLeading: !widget.isTab,
        toolbarHeight: 50,
        titleSpacing: widget.isTab ? 18 : 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '历史',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        actions: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.16),
                width: 0.8,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: '搜索',
              onPressed: () => Get.toNamed('/historySearch'),
              icon: Icon(Icons.search, size: 20, color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: 6),
          menuBtn,
          const SizedBox(width: 6),
        ],
      );
    }

    return AppBar(
      automaticallyImplyLeading: !widget.isTab,
      titleSpacing: widget.isTab ? 16 : 0,
      title: SizedBox(
        height: 42,
        child: Material(
          color: colorScheme.onSecondaryContainer.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(25),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Get.toNamed('/historySearch'),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '搜索观看记录...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.outline,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
      actions: [
        menuBtn,
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildContinueWatchingStrip(
    List<HistoryItemModel> items,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '继续观看',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(
            height: 146,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final cover = item.cover?.isNotEmpty == true
                    ? item.cover
                    : item.covers?.firstOrNull;
                final ratio = (item.progress != null &&
                        item.duration != null &&
                        item.duration! > 0)
                    ? (item.progress! / item.duration!).clamp(0.05, 1.0)
                    : 0.35;
                return Material(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      final h = item.history;
                      if (h.business == 'live' && h.oid != null) {
                        PageUtils.toLiveRoom(h.oid);
                      } else if (h.bvid != null && h.cid != null) {
                        PageUtils.toVideoPage(
                          aid: h.oid,
                          bvid: h.bvid,
                          cid: h.cid!,
                          cover: cover,
                          title: item.title,
                        );
                      }
                    },
                    child: SizedBox(
                      width: 156,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              NetworkImgLayer(
                                src: cover,
                                width: 156,
                                height: 88,
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 3,
                                  backgroundColor: Colors.black26,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                            child: Text(
                              item.title ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                height: 1.25,
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
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<HistoryItemModel>?> loadingState) {
    final colorScheme = Theme.of(context).colorScheme;
    final isModern = Pref.modernCardUi;
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverMainAxisGroup(
                slivers: [
                  if (isModern && widget.type == null)
                    SliverToBoxAdapter(
                      child: _buildContinueWatchingStrip(
                        response
                            .where(
                              (e) =>
                                  (e.cover?.isNotEmpty == true) ||
                                  (e.covers?.isNotEmpty == true),
                            )
                            .take(6)
                            .toList(),
                        colorScheme,
                      ),
                    ),
                  SliverGrid.builder(
                    gridDelegate: gridDelegate,
                    itemBuilder: (context, index) {
                      if (index == response.length - 1) {
                        _historyController.onLoadMore();
                      }
                      final item = response[index];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          color: isModern
                              ? colorScheme.surface
                              : colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(isModern ? 16 : 14),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.10),
                            width: 0.6,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: HistoryItem(
                            item: item,
                            ctr: _historyController,
                            onDelete: (kid, business) =>
                                _historyController.delHistory(item),
                          ),
                        ),
                      );
                    },
                    itemCount: response.length,
                  ),
                ],
              )
            : HttpError(onReload: _historyController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _historyController.onReload,
      ),
    };
  }

  PreferredSizeWidget? get _buildPauseTip {
    if (_historyController.baseCtr.pauseStatus.value) {
      final theme = Theme.of(context).colorScheme;
      return PreferredSize(
        preferredSize: const Size.fromHeight(38),
        child: Container(
          height: 38,
          color: theme.secondaryContainer.withValues(alpha: 0.8),
          padding: const EdgeInsets.only(left: 16, right: 6),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  strutStyle: const StrutStyle(height: 1, leading: 0),
                  style: TextStyle(
                    height: 1,
                    color: theme.onSecondaryContainer,
                  ),
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.onSecondaryContainer,
                        ),
                      ),
                      const TextSpan(text: ' 历史记录功能已关闭'),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _historyController.baseCtr.onPauseHistory(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  child: Text(
                    '点击开启',
                    strutStyle: const StrutStyle(height: 1, leading: 0),
                    style: TextStyle(height: 1, color: theme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return null;
  }

  @override
  bool get wantKeepAlive => widget.type != null || widget.isTab;
}
