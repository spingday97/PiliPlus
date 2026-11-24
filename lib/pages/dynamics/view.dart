import 'dart:async';

import 'package:PiliPlus/common/widgets/custom_height_widget.dart';
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
import 'package:PiliPlus/utils/neu_style.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
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

  Widget _circleIconBtn(
    ColorScheme colorScheme, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool primary = false, double size = 38, double iconSize = 20,
  }) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: primary ? colorScheme.primary : colorScheme.surface,
      shape: .circle,
      border: primary
          ? null
          : .all(
              color: colorScheme.outline.withValues(alpha: 0.16),
              width: 0.8,
            ),
    ),
    child: IconButton(
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(
        icon,
        size: iconSize,
        color: primary ? colorScheme.onPrimary : colorScheme.onSurface,
      ),
    ),
  );

  Widget _actionPill(ColorScheme colorScheme, {bool reverse = false}) {
    final items = <Widget>[
      IconButton(
        tooltip: _useLiveFirstLayout ? '切换为经典动态布局' : '切换为直播优先布局',
        visualDensity: .compact,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
        onPressed: _toggleLayout,
        icon: Icon(
          _useLiveFirstLayout
              ? Icons.view_sidebar_outlined
              : Icons.grid_view_rounded,
          size: 18,
          color: _useLiveFirstLayout
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
      IconButton(
        tooltip: '搜索关注的 UP 主',
        visualDensity: .compact,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
        onPressed: () => _showSearchUpSheet(context),
        icon: Icon(
          Icons.search,
          size: 19,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      IconButton(
        tooltip: '发布动态',
        visualDensity: .compact,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
        onPressed: () => CreateDynPanel.onCreateDyn(context),
        icon: Icon(
          Icons.add,
          size: 20,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    ];
    return Container(
      height: 36,
      margin: reverse ? const .only(left: 12) : const .only(right: 14),
      padding: const .symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: .circular(18),
        border: .all(
          color: colorScheme.outline.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: .min,
        children: reverse ? items.reversed.toList() : items,
      ),
    );
  }

  Widget _buildLiveStrip(ColorScheme colorScheme) {
    return Obx(() { final followUp = switch (_dynamicsController.loadingState.value) { Success(:final response) => response, _ => null }; final liveItems = followUp?.liveUsers?.items ?? const <LiveUserItem>[]; final upList = followUp?.upList ?? const <UpItem>[]; if (liveItems.isEmpty && upList.isEmpty) { return const SizedBox.shrink(); } final liveUids = liveItems.map((e) => e.mid).toSet(); final dedupUpList = upList.where((e) => !liveUids.contains(e.mid)).toList(); return SizedBox(height: 78, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), itemCount: 1 + liveItems.length + dedupUpList.length, separatorBuilder: (_, _) => const SizedBox(width: 12), itemBuilder: (context, index) { if (index == 0) { return GestureDetector(onTap: () => _dynamicsController.onSelectUp(-1), child: SizedBox(width: 56, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 48, height: 48, decoration: BoxDecoration(color: colorScheme.secondaryContainer, shape: BoxShape.circle), child: Icon(Icons.apps_rounded, size: 22, color: colorScheme.onSecondaryContainer)), const SizedBox(height: 4), Text('全部', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))]))); } if (index <= liveItems.length) { final item = liveItems[index - 1]; return GestureDetector(onTap: () => PageUtils.toLiveRoom(item.roomId), child: SizedBox(width: 56, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [Container(width: 48, height: 48, padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colorScheme.primary, width: 2)), child: NetworkImgLayer(width: 44, height: 44, type: ImageType.avatar, src: item.face)), Positioned(bottom: -3, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(4)), child: Text('LIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: colorScheme.onPrimary, height: 1.0))))]), const SizedBox(height: 4), Text(item.uname ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))]))); } final item = dedupUpList[index - 1 - liveItems.length]; return GestureDetector(onTap: () => _dynamicsController.onSelectUp(item.mid), child: SizedBox(width: 56, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Stack(clipBehavior: Clip.none, children: [NetworkImgLayer(width: 48, height: 48, type: ImageType.avatar, src: item.face), if (item.hasUpdate == true) Positioned(top: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.blue, shape: BoxShape.circle, border: Border.all(color: colorScheme.surface, width: 1.5))))]), const SizedBox(height: 4), Text(item.uname ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant))]))); })); });
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
    final isTop = NeuStyle.enabled || upPanelPosition == .top;
    final needBg = upPanelPosition.index > 2;
    final panel = Material(
      type: needBg ? .canvas : .transparency,
      color: needBg ? colorScheme.surface : null,
      child: SizedBox(
        width: isTop ? null : 64,
        height: isTop ? 80 : null,
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
    if (needBg) return panel;
    return Container(
      margin: isTop
          ? const .fromLTRB(10, 4, 10, 6)
          : const .fromLTRB(8, 6, 4, 8),
      decoration: NeuStyle.enabled ? NeuStyle.inset(isDark: colorScheme.brightness == Brightness.dark, radius: 18) : BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: .circular(16),
        border: .all(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 0.6,
        ),
      ),
      clipBehavior: .antiAlias,
      child: panel,
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
    final isModern = Pref.modernCardUi;
    final isIos = Pref.iosStyleUi;
    final isDark = colorScheme.brightness == Brightness.dark;
    Widget? drawer;
    Widget? endDrawer;

    Widget? leading;
    Widget? actions;

    final tabView = tabBarView(
      controller: _dynamicsController.tabController,
      children: _dynamicsController.tabs
          .map((e) => DynamicsTabPage(dynamicsType: e, upStripBuilder: (isModern || _useLiveFirstLayout) ? (_) => _buildLiveStrip(colorScheme) : null))
          .toList(),
    );

    Widget child = tabView;
    final neuTabBar = isIos ? Container(margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), padding: const EdgeInsets.all(4), decoration: NeuStyle.inset(isDark: isDark, radius: 14), child: SizedBox(height: 36, child: TabBar(dividerHeight: 0, isScrollable: false, dividerColor: Colors.transparent, indicatorSize: TabBarIndicatorSize.tab, indicatorWeight: 0, indicator: NeuStyle.raised(isDark: isDark, radius: 10, blur: 6, offset: 2), labelColor: colorScheme.onSurface, unselectedLabelColor: colorScheme.outline, controller: _dynamicsController.tabController, labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal), tabs: _dynamicsController.tabs.map((e) => Tab(text: e.label)).toList(), onTap: (index) { if (!_dynamicsController.tabController.indexIsChanging) { _dynamicsController.animateToTop(); } }))) : null;
    
    if (!isModern || isIos) {
      if (_useLiveFirstLayout && !isIos) {
        actions = _actionPill(colorScheme);
      } else {
        if (NeuStyle.enabled) { child = Column(children: [if (neuTabBar != null) neuTabBar, upPanelPart(colorScheme), Expanded(child: child)]); actions = Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 36, height: 36, margin: const EdgeInsets.only(right: 10), decoration: NeuStyle.raised(isDark: isDark, radius: 18, blur: 7, offset: 3), child: IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: '搜索关注的 UP 主', icon: const Icon(Icons.search, size: 19), onPressed: () => _showSearchUpSheet(context))), Container(width: 36, height: 36, margin: const EdgeInsets.only(right: 14), decoration: NeuStyle.raised(isDark: isDark, radius: 18, blur: 7, offset: 3), child: IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), tooltip: '发布动态', icon: const Icon(Icons.add, size: 20), onPressed: () => CreateDynPanel.onCreateDyn(context)))]); } else switch (upPanelPosition) {
          case .top:
            child = Column(
              children: [
                upPanelPart(colorScheme),
                Expanded(child: child),
              ],
            );
            actions = _actionPill(colorScheme);
          case .leftFixed:
            child = Row(
              children: [
                upPanelPart(colorScheme),
                Expanded(child: child),
              ],
            );
            actions = _actionPill(colorScheme);
          case .rightFixed:
            child = Row(
              children: [
                Expanded(child: child),
                upPanelPart(colorScheme),
              ],
            );
            actions = _actionPill(colorScheme);
          case .leftDrawer:
            drawer = upPanelPart(colorScheme);
            actions = _actionPill(colorScheme);
            leading = const DrawerButton();
          case .rightDrawer:
            endDrawer = upPanelPart(colorScheme);
            leading = _actionPill(colorScheme, reverse: true);
            actions = const EndDrawerButton();
        }
      }
    }

    final tabBar = isIos ? Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: colorScheme.surfaceContainer, borderRadius: BorderRadius.circular(12)), child: TabBar(dividerHeight: 0, isScrollable: true, tabAlignment: .start, dividerColor: Colors.transparent, indicatorSize: TabBarIndicatorSize.tab, indicatorWeight: 0, indicator: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))]), labelColor: colorScheme.onSurface, unselectedLabelColor: colorScheme.outline, controller: _dynamicsController.tabController, labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal), tabs: _dynamicsController.tabs.map((e) => Tab(text: e.label)).toList(), onTap: (index) { if (!_dynamicsController.tabController.indexIsChanging) { _dynamicsController.animateToTop(); } })) : TabBar(
      dividerHeight: 0,
      isScrollable: true,
      tabAlignment: .start,
      padding: isModern ? const .symmetric(horizontal: 14) : EdgeInsets.zero,
      dividerColor: Colors.transparent,
      indicatorSize: isModern
          ? TabBarIndicatorSize.tab
          : TabBarIndicatorSize.label,
      indicatorWeight: isModern ? 0 : 3,
      indicatorPadding: isModern
          ? const .symmetric(vertical: 6)
          : EdgeInsets.zero,
      indicator: isModern
          ? BoxDecoration(
              color: colorScheme.primary,
              borderRadius: .circular(18),
            )
          : null,
      indicatorColor: colorScheme.primary,
      labelColor: isModern ? colorScheme.onPrimary : colorScheme.primary,
      controller: _dynamicsController.tabController,
      unselectedLabelColor: colorScheme.onSurface,
      labelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.normal,
      ),
      tabs: _dynamicsController.tabs.map((e) => Tab(text: e.label)).toList(),
      onTap: (index) {
        if (!_dynamicsController.tabController.indexIsChanging) {
          _dynamicsController.animateToTop();
        }
      },
    );

    return Scaffold(
      primary: false,
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: .fromHeight(isModern && !isIos ? 94 : 50),
        child: isModern && !isIos
            ? Builder(builder: (context) { Widget buildHeader(double offset) => Material(color: Theme.of(context).scaffoldBackgroundColor, child: Column(mainAxisSize: .min,
                crossAxisAlignment: .start,
                children: [
                  ClipRect(child: CustomHeightWidget(offset: Offset(0, -offset), height: (50.0 - offset).clamp(0.0, 50.0), child: Container(
                    padding: const .fromLTRB(18, 8, 14, 0), height: 50,
                    child: Row(
                      children: [
                        Text(
                          '动态',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: .w800,
                            letterSpacing: -0.5,
                            color: colorScheme.onSurface, height: 1.1,
                          ),
                        ),
                        const Spacer(),
                        _circleIconBtn(
                          colorScheme,
                          icon: Icons.search,
                          tooltip: '搜索关注的 UP 主',
                          onPressed: () => _showSearchUpSheet(context),
                        ),
                        const SizedBox(width: 8),
                        _circleIconBtn(
                          colorScheme,
                          icon: Icons.add,
                          tooltip: '发布动态',
                          primary: true,
                          onPressed: () => CreateDynPanel.onCreateDyn(context),
                        ),
                      ],
                    ),
                  ),
                  ),), SizedBox(height: 44, child: Row(children: [Expanded(child: tabBar), if (offset > 2) Opacity(opacity: (offset / 50.0).clamp(0.0, 1.0), child: Row(mainAxisSize: .min, children: [_circleIconBtn(colorScheme, icon: Icons.search, tooltip: '搜索关注的 UP 主', size: 32, iconSize: 17, onPressed: () => _showSearchUpSheet(context)), const SizedBox(width: 6), _circleIconBtn(colorScheme, icon: Icons.add, tooltip: '发布动态', primary: true, size: 32, iconSize: 17, onPressed: () => CreateDynPanel.onCreateDyn(context)), const SizedBox(width: 12)]))])),
                ],
              )
            ); if (_mainController.barOffset case final barOffset?) { return Obx(() => buildHeader(barOffset.value.clamp(0.0, 50.0))); } return buildHeader(0.0); }) :isIos ? AppBar(primary: false, automaticallyImplyLeading: false, centerTitle: false, toolbarHeight: 50, backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, title: const Text('动态', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)), actions: [if (actions != null) actions]) :  Row(
                children: [
                  ?leading,
                  Expanded(child: tabBar),
                  ?actions,
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
