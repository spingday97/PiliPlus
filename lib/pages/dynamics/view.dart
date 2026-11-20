import 'dart:async';

import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/member.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/common/dynamic/up_panel_position.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models/dynamics/up.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/dynamics/widgets/up_panel.dart';
import 'package:PiliPlus/pages/dynamics_create/view.dart';
import 'package:PiliPlus/pages/dynamics_tab/view.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide DraggableScrollableSheet;

class DynamicsPage extends StatefulWidget {
  const DynamicsPage({super.key});

  @override
  State<DynamicsPage> createState() => _DynamicsPageState();
}

class _DynamicsPageState extends CommonPageState<DynamicsPage>
    with AutomaticKeepAliveClientMixin {
  static const String _liveFirstLayoutKey = 'dynLiveFirstLayout';

  final _dynamicsController = Get.putOrFind(DynamicsController.new);
  UpPanelPosition get upPanelPosition => _dynamicsController.upPanelPosition;
  late final MainController _mainController = Get.find<MainController>();

  late bool _useLiveFirstLayout = GStorage.setting.get(
    _liveFirstLayoutKey,
    defaultValue: false,
  );

  @override
  bool get wantKeepAlive => true;

  void _toggleLayout() {
    final next = !_useLiveFirstLayout;
    setState(() => _useLiveFirstLayout = next);
    GStorage.setting.put(_liveFirstLayoutKey, next);
  }

  Widget _layoutToggleBtn(ColorScheme colorScheme) => Container(
    width: 34,
    height: 34,
    margin: const .only(right: 8),
    child: IconButton(
      tooltip: _useLiveFirstLayout ? '切换为经典动态布局' : '切换为直播优先布局',
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(
          _useLiveFirstLayout
              ? colorScheme.primaryContainer
              : colorScheme.secondaryContainer,
        ),
      ),
      onPressed: _toggleLayout,
      icon: Icon(
        _useLiveFirstLayout
            ? Icons.view_sidebar_outlined
            : Icons.view_agenda_outlined,
        size: 18,
        color: _useLiveFirstLayout
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSecondaryContainer,
      ),
    ),
  );

  Widget _searchUpBtn(ColorScheme colorScheme) => Container(
    width: 34,
    height: 34,
    margin: const .only(right: 8),
    child: IconButton(
      tooltip: '搜索关注的 UP 主',
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        backgroundColor: WidgetStatePropertyAll(
          colorScheme.secondaryContainer,
        ),
      ),
      onPressed: () => _showSearchUpSheet(context),
      icon: Icon(
        Icons.search,
        size: 18,
        color: colorScheme.onSecondaryContainer,
      ),
    ),
  );

  Widget _createDynamicBtn(ColorScheme colorScheme, {bool isRight = true}) =>
      Container(
        width: 34,
        height: 34,
        margin: isRight ? const .only(right: 16) : const .only(left: 16),
        child: IconButton(
          tooltip: '发布动态',
          style: ButtonStyle(
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            backgroundColor: WidgetStatePropertyAll(
              colorScheme.secondaryContainer,
            ),
          ),
          onPressed: () => CreateDynPanel.onCreateDyn(context),
          icon: Icon(
            Icons.add,
            size: 18,
            color: colorScheme.onSecondaryContainer,
          ),
        ),
      );

  Widget _buildLiveStrip(ColorScheme colorScheme) {
    return Obx(() {
      final state = _dynamicsController.loadingState.value;
      if (state is! Success<FollowUpModel>) {
        return const SizedBox.shrink();
      }
      final items = state.response.liveUsers?.items;
      if (items == null || items.isEmpty) {
        return const SizedBox.shrink();
      }
      return Container(
        margin: const .only(top: 6, bottom: 4),
        child: Column(
          crossAxisAlignment: .start,
          mainAxisSize: .min,
          children: [
            Padding(
              padding: const .symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const .only(right: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: .circle,
                    ),
                  ),
                  Text(
                    '正在直播 (${items.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: .w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: .horizontal,
                padding: const .symmetric(horizontal: 14),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Material(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: .circular(14),
                    clipBehavior: .antiAlias,
                    child: InkWell(
                      onTap: () {
                        if (item.roomId != null) {
                          PageUtils.toLiveRoom(item.roomId);
                        }
                      },
                      child: Container(
                        width: 196,
                        padding: const .symmetric(horizontal: 10, vertical: 8),
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: .none,
                              children: [
                                Container(
                                  padding: const .all(2),
                                  decoration: BoxDecoration(
                                    shape: .circle,
                                    border: .all(
                                      color: colorScheme.primary,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: NetworkImgLayer(
                                    src: item.face,
                                    width: 38,
                                    height: 38,
                                    type: ImageType.avatar,
                                  ),
                                ),
                                Positioned(
                                  bottom: -2,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const .symmetric(
                                        horizontal: 4,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        borderRadius: .circular(4),
                                      ),
                                      child: Text(
                                        'LIVE',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: .bold,
                                          color: colorScheme.onPrimary,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: .start,
                                mainAxisAlignment: .center,
                                children: [
                                  Text(
                                    item.uname ?? '',
                                    maxLines: 1,
                                    overflow: .ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: .w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.title ?? '直播中',
                                    maxLines: 2,
                                    overflow: .ellipsis,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      height: 1.25,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
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
    });
  }

  void _showSearchUpSheet(BuildContext context) {
    final followUp = switch (_dynamicsController.loadingState.value) {
      Success(:final response) => response,
      _ => null,
    };
    final liveItems = followUp?.liveUsers?.items ?? const <LiveUserItem>[];
    final localUpList = followUp?.upList ?? const <UpItem>[];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: .vertical(top: .circular(24)),
      ),
      builder: (sheetContext) => _SearchUpBottomSheet(
        liveItems: liveItems,
        localUpList: localUpList,
        onSelectUp: (mid) {
          Navigator.of(sheetContext).pop();
          _dynamicsController.onSelectUp(mid);
        },
        onOpenMember: (mid) {
          Navigator.of(sheetContext).pop();
          Get.toNamed('/member?mid=$mid');
        },
      ),
    );
  }

  Widget upPanelPart(ColorScheme colorScheme) {
    final isTop = upPanelPosition == .top;
    final needBg = upPanelPosition.index > 2;
    return Material(
      type: needBg ? .canvas : .transparency,
      color: needBg ? colorScheme.surface : null,
      child: SizedBox(
        width: isTop ? null : 64,
        height: isTop ? 76 : null,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent - 300) {
              _dynamicsController.onLoadMore();
            }
            return false;
          },
          child: Obx(
            () => _buildUpPanel(_dynamicsController.loadingState.value),
          ),
        ),
      ),
    );
  }

  Widget _buildUpPanel(LoadingState<FollowUpModel> upState) {
    return switch (upState) {
      Loading() => const SizedBox.shrink(),
      Success(:final response) => UpPanel(
        upData: response,
        dynamicsController: _dynamicsController,
      ),
      Error() => Center(
        child: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _dynamicsController.onReload,
        ),
      ),
    };
  }

  bool get checkPage =>
      _mainController.navigationBars[0] != .dynamics &&
      _mainController.selectedIndex.value == 0;

  @override
  bool onNotificationType1(UserScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType1(notification);
  }

  @override
  bool onNotificationType2(ScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType2(notification);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = ColorScheme.of(context);

    Widget? drawer;
    Widget? endDrawer;

    Widget? leading;
    Widget actions;

    final tabView = tabBarView(
      controller: _dynamicsController.tabController,
      children: DynamicsTabType.values
          .map((e) => DynamicsTabPage(dynamicsType: e))
          .toList(),
    );

    Widget child = _useLiveFirstLayout
        ? Column(
            children: [
              _buildLiveStrip(colorScheme),
              Expanded(child: tabView),
            ],
          )
        : tabView;

    if (_useLiveFirstLayout) {
      actions = Row(
        mainAxisSize: .min,
        children: [
          _layoutToggleBtn(colorScheme),
          _searchUpBtn(colorScheme),
          _createDynamicBtn(colorScheme),
        ],
      );
    } else {
      switch (upPanelPosition) {
        case .top:
          child = Column(
            children: [
              upPanelPart(colorScheme),
              Expanded(child: child),
            ],
          );
          actions = Row(
            mainAxisSize: .min,
            children: [
              _layoutToggleBtn(colorScheme),
              _searchUpBtn(colorScheme),
              _createDynamicBtn(colorScheme),
            ],
          );
        case .leftFixed:
          child = Row(
            children: [
              upPanelPart(colorScheme),
              Expanded(child: child),
            ],
          );
          actions = Row(
            mainAxisSize: .min,
            children: [
              _layoutToggleBtn(colorScheme),
              _searchUpBtn(colorScheme),
              _createDynamicBtn(colorScheme),
            ],
          );
        case .rightFixed:
          child = Row(
            children: [
              Expanded(child: child),
              upPanelPart(colorScheme),
            ],
          );
          actions = Row(
            mainAxisSize: .min,
            children: [
              _layoutToggleBtn(colorScheme),
              _searchUpBtn(colorScheme),
              _createDynamicBtn(colorScheme),
            ],
          );
        case .leftDrawer:
          drawer = upPanelPart(colorScheme);
          actions = Row(
            mainAxisSize: .min,
            children: [
              _layoutToggleBtn(colorScheme),
              _searchUpBtn(colorScheme),
              _createDynamicBtn(colorScheme),
            ],
          );
          leading = const DrawerButton();
        case .rightDrawer:
          endDrawer = upPanelPart(colorScheme);
          leading = Row(
            mainAxisSize: .min,
            children: [
              _createDynamicBtn(colorScheme, isRight: false),
              const SizedBox(width: 8),
              _searchUpBtn(colorScheme),
              _layoutToggleBtn(colorScheme),
            ],
          );
          actions = const EndDrawerButton();
      }
    }

    return Scaffold(
      primary: false,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const .fromHeight(50),
        child: Row(
          children: [
            ?leading,
            Expanded(
              child: TabBar(
                dividerHeight: 0,
                isScrollable: true,
                tabAlignment: .start,
                dividerColor: Colors.transparent,
                labelColor: colorScheme.primary,
                indicatorColor: colorScheme.primary,
                controller: _dynamicsController.tabController,
                unselectedLabelColor: colorScheme.onSurface,
                labelStyle:
                    TabBarTheme.of(context).labelStyle
                        ?.copyWith(fontSize: 13) ??
                    const TextStyle(fontSize: 13),
                tabs: DynamicsTabType.values
                    .map((e) => Tab(text: e.label))
                    .toList(),
                onTap: (index) {
                  if (!_dynamicsController.tabController.indexIsChanging) {
                    _dynamicsController.animateToTop();
                  }
                },
              ),
            ),
            actions,
          ],
        ),
      ),
      drawer: drawer,
      endDrawer: endDrawer,
      body: onBuild(child),
    );
  }
}

class _SearchUpEntry {
  final int mid;
  final String uname;
  final String? face;
  final bool isLive;
  final bool hasUpdate;
  final int? roomId;

  const _SearchUpEntry({
    required this.mid,
    required this.uname,
    this.face,
    this.isLive = false,
    this.hasUpdate = false,
    this.roomId,
  });
}

class _SearchUpBottomSheet extends StatefulWidget {
  const _SearchUpBottomSheet({
    required this.liveItems,
    required this.localUpList,
    required this.onSelectUp,
    required this.onOpenMember,
  });

  final List<LiveUserItem> liveItems;
  final List<UpItem> localUpList;
  final ValueChanged<int> onSelectUp;
  final ValueChanged<int> onOpenMember;

  @override
  State<_SearchUpBottomSheet> createState() => _SearchUpBottomSheetState();
}

class _SearchUpBottomSheetState extends State<_SearchUpBottomSheet> {
  final _textController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  List<_SearchUpEntry> _remoteResults = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  List<_SearchUpEntry> _buildLocalEntries(String query) {
    final q = query.trim().toLowerCase();
    final map = <int, _SearchUpEntry>{};

    for (final item in widget.liveItems) {
      final name = item.uname ?? '';
      if (q.isEmpty || name.toLowerCase().contains(q)) {
        map[item.mid] = _SearchUpEntry(
          mid: item.mid,
          uname: name,
          face: item.face,
          isLive: true,
          hasUpdate: item.hasUpdate ?? false,
          roomId: item.roomId,
        );
      }
    }

    for (final item in widget.localUpList) {
      final name = item.uname ?? '';
      if (q.isEmpty || name.toLowerCase().contains(q)) {
        map.putIfAbsent(
          item.mid,
          () => _SearchUpEntry(
            mid: item.mid,
            uname: name,
            face: item.face,
            hasUpdate: item.hasUpdate ?? false,
          ),
        );
      }
    }

    return map.values.toList();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _remoteResults = const [];
      });
      return;
    }

    setState(() {});
    if (!Accounts.main.isLogin) return;

    _debounce = Timer(const Duration(milliseconds: 280), () async {
      if (!mounted) return;
      setState(() => _isSearching = true);
      final res = await MemberHttp.getfollowSearch(
        mid: Accounts.main.mid,
        ps: 20,
        pn: 1,
        name: q,
      );
      if (!mounted || _textController.text.trim() != q) return;
      if (res case Success(:final response)) {
        final list = response.list ?? const [];
        setState(() {
          _isSearching = false;
          _remoteResults = list
              .map(
                (e) => _SearchUpEntry(
                  mid: e.mid,
                  uname: e.uname ?? '',
                  face: e.face,
                ),
              )
              .toList();
        });
      } else {
        setState(() => _isSearching = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final q = _textController.text.trim();
    final local = _buildLocalEntries(q);
    final merged = <int, _SearchUpEntry>{
      for (final item in local) item.mid: item,
      for (final item in _remoteResults)
        if (!local.any((e) => e.mid == item.mid)) item.mid: item,
    }.values.toList();

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.62,
        child: Column(
          children: [
            Padding(
              padding: const .fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Text(
                    '搜索关注的 UP 主',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: .w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (_isSearching)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const .symmetric(horizontal: 16),
              child: TextField(
                controller: _textController,
                autofocus: true,
                onChanged: _onQueryChanged,
                decoration: InputDecoration(
                  hintText: '输入 UP 主昵称搜索...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: q.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _textController.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  contentPadding: const .symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: .circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: merged.isEmpty
                  ? Center(
                      child: Text(
                        _isSearching ? '正在搜索...' : '未找到匹配的 UP 主',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const .symmetric(horizontal: 8, vertical: 4),
                      itemCount: merged.length,
                      itemBuilder: (context, index) {
                        final entry = merged[index];
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: .circular(14),
                          ),
                          onTap: () => widget.onSelectUp(entry.mid),
                          leading: NetworkImgLayer(
                            src: entry.face,
                            width: 42,
                            height: 42,
                            type: ImageType.avatar,
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  entry.uname,
                                  maxLines: 1,
                                  overflow: .ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: .w500,
                                  ),
                                ),
                              ),
                              if (entry.isLive) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const .symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: .circular(8),
                                  ),
                                  child: Text(
                                    '直播中',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: .w600,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ] else if (entry.hasUpdate) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: .circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: TextButton(
                            onPressed: () => widget.onOpenMember(entry.mid),
                            style: TextButton.styleFrom(
                              padding: const .symmetric(horizontal: 10),
                              minimumSize: const Size(0, 32),
                            ),
                            child: const Text('进主页'),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
