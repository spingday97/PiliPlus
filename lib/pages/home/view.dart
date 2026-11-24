import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/custom_height_widget.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/neu_style.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends CommonPageState<HomePage>
    with AutomaticKeepAliveClientMixin {
  late ColorScheme _colorScheme;
  final _homeController = Get.putOrFind(HomeController.new);
  final _mainController = Get.find<MainController>();

  @override
  bool get needsCorrection => _homeController.hideTopBar;

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorScheme = ColorScheme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isModern = Pref.modernCardUi; final isIos = Pref.iosStyleUi;
    Widget tabBar;
    if (_homeController.tabs.length > 1) {
      tabBar = isIos ? Container(margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), padding: const EdgeInsets.all(3), decoration: NeuStyle.inset(isDark: Theme.of(context).brightness == Brightness.dark, radius: 14), child: TabBar(controller: _homeController.tabController, tabs: _homeController.tabs.map((e) => Tab(text: e.label)).toList(), isScrollable: true, dividerColor: Colors.transparent, dividerHeight: 0, splashBorderRadius: Style.mdRadius, tabAlignment: TabAlignment.center, indicatorSize: TabBarIndicatorSize.tab, indicator: NeuStyle.raised(isDark: Theme.of(context).brightness == Brightness.dark, radius: 10, blur: 6, offset: 2), labelColor: _colorScheme.onSurface, unselectedLabelColor: _colorScheme.outline, onTap: (_) { feedBack(); if (!_homeController.tabController.indexIsChanging) { _homeController.animateToTop(); } })) : Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SizedBox(
          height: 42,
          width: double.infinity,
          child: TabBar(
            controller: _homeController.tabController,
            tabs: _homeController.tabs.map((e) => Tab(text: e.label)).toList(),
            isScrollable: true,
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            splashBorderRadius: Style.mdRadius,
            tabAlignment:isModern ? TabAlignment.start :  TabAlignment.center,
            padding: isModern ? const EdgeInsets.symmetric(horizontal: 14) : null,
            indicatorSize: isModern ? TabBarIndicatorSize.tab : null,
indicatorPadding: isModern ? const EdgeInsets.symmetric(vertical: 5) : EdgeInsets.zero,
indicator: isModern ? BoxDecoration(color: _colorScheme.primary, borderRadius: BorderRadius.circular(18)) : null,
labelColor: isModern ? _colorScheme.onPrimary : null,
unselectedLabelColor: isModern ? _colorScheme.onSurfaceVariant : null,
            onTap: (_) {
              feedBack();
              if (!_homeController.tabController.indexIsChanging) {
                _homeController.animateToTop();
              }
            },
          ),
        ),
      );
      if (_homeController.hideTopBar &&
          _mainController.barHideType == .instant) {
        tabBar = Material(
          color: _colorScheme.surface,
          child: tabBar,
        );
      }
    } else {
      tabBar = const SizedBox(height: 6);
    }
    if ((Pref.modernCardUi || NeuStyle.enabled) && _homeController.hideTopBar) { final rawTabBar = tabBar; if (_mainController.barOffset case final barOffset?) { tabBar = Obx(() { final offset = barOffset.value.clamp(0.0, 46.0); return CustomHeightWidget(offset: Offset(0, -offset), height: (46.0 - offset).clamp(0.0, 46.0), child: rawTabBar); }); } else if (_homeController.showTopBar case final showTopBar?) { tabBar = Obx(() => AnimatedOpacity(opacity: showTopBar.value ? 1 : 0, duration: const Duration(milliseconds: 250), child: AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeInOutCubicEmphasized, height: showTopBar.value ? 46 : 0, child: rawTabBar))); } }
    
    return Column(
      children: [
        if (!_mainController.useSideBar && MediaQuery.isPortraitOf(context))
          customAppBar(),
        tabBar,
        Expanded(
          child: onBuild(
            tabBarView(
              controller: _homeController.tabController,
              children: _homeController.tabs.map((e) => e.page).toList(),
            ),
          ),
        ),
      ],
    );
  }
  Widget customAppBar() {
    final isModern = Pref.modernCardUi;
    final padding = isModern
        ? const EdgeInsets.fromLTRB(18, 8, 14, 0)
        : const EdgeInsets.fromLTRB(14, 6, 14, 0);
    final child = isModern
        ? Row(
        children: [
          Text(
            '探索',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
              color: _colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: _colorScheme.outline.withValues(alpha: 0.16),
                width: 0.8,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.search,
                size: 20,
                color: _colorScheme.onSurface,
              ),
              onPressed: () => Get.toNamed(
                '/search',
                parameters: _homeController.enableSearchWord
                    ? {'hintText': _homeController.defaultSearch.value}
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 6),
          NeuStyle.enabled ? Container(decoration: NeuStyle.raised(isDark: Theme.of(context).brightness == Brightness.dark, radius: 20, blur: 8, offset: 3), child: msgBadge(_mainController)) : msgBadge(_mainController),
          const SizedBox(width: 8),
          userAvatar(
            colorScheme: _colorScheme,
            mainController: _mainController,
          ),
        ],
          )
        : Row(
      children: [
        searchBar(),
        const SizedBox(width: 4),
        NeuStyle.enabled ? Container(decoration: NeuStyle.raised(isDark: Theme.of(context).brightness == Brightness.dark, radius: 20, blur: 8, offset: 3), child: msgBadge(_mainController)) : msgBadge(_mainController),
        const SizedBox(width: 8),
        NeuStyle.enabled ? Container(decoration: NeuStyle.raised(isDark: Theme.of(context).brightness == Brightness.dark, radius: 20, blur: 8, offset: 3), child: userAvatar(colorScheme: _colorScheme, mainController: _mainController)) : userAvatar(colorScheme: _colorScheme, mainController: _mainController),
      ],
    );
    if (_homeController.hideTopBar) {
      if (_mainController.barOffset case final barOffset?) {
        return Obx(
          () {
            final offset = barOffset.value;
            return CustomHeightWidget(
              offset: Offset(0, -offset),
              height: Style.topBarHeight - offset,
              child: Padding(
                padding: padding,
                child: child,
              ),
            );
          },
        );
      }
      if (_homeController.showTopBar case final showTopBar?) {
        return Obx(() {
          final showSearchBar = showTopBar.value;
          return AnimatedOpacity(
            opacity: showSearchBar ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              curve: Curves.easeInOutCubicEmphasized,
              duration: const Duration(milliseconds: 500),
              height: showSearchBar ? Style.topBarHeight : 0,
              padding: padding,
              child: child,
            ),
          );
        });
      }
    }
    return Container(
      height: Style.topBarHeight,
      padding: padding,
      child: child,
    );
  }

  Widget searchBar() {
    final isNeu = NeuStyle.enabled; final isDark = Theme.of(context).brightness == Brightness.dark; final borderRadius = BorderRadius.all(Radius.circular(isNeu ? 20 : 25));
    return Expanded(
      child: Container(decoration: isNeu ? NeuStyle.inset(isDark: isDark, radius: 20) : null,
        height: 44,
        child: Material(
          borderRadius: borderRadius,
          color: isNeu ? Colors.transparent : _colorScheme.onSecondaryContainer.withValues(alpha: 0.05),
          child: InkWell(
            borderRadius: borderRadius,
            splashColor: _colorScheme.primaryContainer.withValues(
              alpha: 0.3,
            ),
            onTap: () => Get.toNamed(
              '/search',
              parameters: _homeController.enableSearchWord
                  ? {'hintText': _homeController.defaultSearch.value}
                  : null,
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_outlined,
                  color: _colorScheme.onSecondaryContainer,
                  semanticLabel: '搜索',
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Obx(
                    () => Text(
                      _homeController.defaultSearch.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _colorScheme.outline),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget userAvatar({
  required ColorScheme colorScheme,
  required MainController mainController,
}) {
  return Semantics(
    label: "我的",
    child: Obx(
      () {
        if (mainController.accountService.isLogin.value) {
          return Stack(
            clipBehavior: .none,
            children: [
              NetworkImgLayer(
                type: .avatar,
                width: 34,
                height: 34,
                src: mainController.accountService.face.value,
              ),
              Positioned.fill(
                child: Material(
                  type: .transparency,
                  child: InkWell(
                    onTap: mainController.toMinePage,
                    splashColor: colorScheme.primaryContainer.withValues(
                      alpha: 0.3,
                    ),
                    customBorder: const CircleBorder(),
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Obx(
                  () => MineController.anonymity.value
                      ? IgnorePointer(
                          child: Container(
                            padding: const .all(2),
                            decoration: BoxDecoration(
                              shape: .circle,
                              color: colorScheme.secondaryContainer,
                            ),
                            child: Icon(
                              size: 14,
                              MdiIcons.incognito,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          );
        }
        return SizedBox(
          width: 38,
          height: 38,
          child: IconButton(
            tooltip: '点击登录',
            style: IconButton.styleFrom(
              padding: .zero,
              backgroundColor: colorScheme.onInverseSurface,
            ),
            onPressed: mainController.toMinePage,
            icon: Icon(
              Icons.person_rounded,
              size: 22,
              color: colorScheme.primary,
            ),
          ),
        );
      },
    ),
  );
}

Widget msgBadge(MainController mainController) {
  return Obx(
    () {
      if (mainController.accountService.isLogin.value) {
        final count = mainController.msgUnReadCount.value;
        final isNumBadge = mainController.msgBadgeMode == .number;
        return IconButton(
          tooltip: '消息',
          onPressed: () {
            mainController
              ..clearUnreadMsg()
              ..lastCheckUnreadAt = DateTime.now().millisecondsSinceEpoch;
            Get.toNamed('/whisper');
          },
          icon: Badge(
            isLabelVisible:
                mainController.msgBadgeMode != .hidden && count != null,
            alignment: isNumBadge
                ? const Alignment(0.0, -0.85)
                : const Alignment(1.0, -0.85),
            label: isNumBadge && count != null ? Text(count) : null,
            child: const Icon(Icons.notifications_none),
          ),
        );
      }
      return const SizedBox.shrink();
    },
  );
}
