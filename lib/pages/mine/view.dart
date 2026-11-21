import 'dart:async';
import 'dart:io';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/mine_tab_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/mine/widgets/fav_item.dart';
import 'package:PiliPlus/pages/mine/widgets/history_item.dart';
import 'package:PiliPlus/pages/mine/widgets/later_item.dart';
import 'package:PiliPlus/pages/mine/widgets/sub_item.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class MinePage extends StatefulWidget {
  const MinePage({super.key, this.showBackBtn = false});

  final bool showBackBtn;

  @override
  State<MinePage> createState() => _MediaPageState();
}

class _MediaPageState extends CommonPageState<MinePage>
    with AutomaticKeepAliveClientMixin {
  static const String _customBgKey = 'mineCustomBgPath';

  final MineController controller = Get.putOrFind(MineController.new);
  late final MainController _mainController = Get.find<MainController>();
  late ThemeData theme;
  String? _customBgPath;

  @override
  bool get wantKeepAlive => true;

  bool get checkPage =>
      _mainController.navigationBars[0] != NavigationBarType.mine &&
      _mainController.selectedIndex.value == 0;

  @override
  void initState() {
    super.initState();
    final savedPath = GStorage.setting.get(_customBgKey) as String?;
    if (savedPath != null && File(savedPath).existsSync()) {
      _customBgPath = savedPath;
    }
  }

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  Future<void> _pickCustomBg() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    String finalPath = picked.path;
    final settingPath = GStorage.setting.path;
    if (settingPath != null) {
      final dir = File(settingPath).parent;
      final ext = picked.path.contains('.')
          ? picked.path.split('.').last
          : 'img';
      final target = File(
        '${dir.path}/mine_custom_bg_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await File(picked.path).copy(target.path);
      finalPath = target.path;
    }
    final oldPath = _customBgPath;
    if (oldPath != null && oldPath != finalPath) {
      try {
        final oldFile = File(oldPath);
        if (oldFile.existsSync()) {
          await oldFile.delete();
        }
      } catch (_) {}
    }
    await GStorage.setting.put(_customBgKey, finalPath);
    if (mounted) {
      setState(() {
        _customBgPath = finalPath;
      });
    }
  }

  Future<void> _resetCustomBg() async {
    final oldPath = _customBgPath;
    if (oldPath != null) {
      try {
        final oldFile = File(oldPath);
        if (oldFile.existsSync()) {
          await oldFile.delete();
        }
      } catch (_) {}
    }
    await GStorage.setting.delete(_customBgKey);
    if (mounted) {
      setState(() {
        _customBgPath = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final secondary = theme.colorScheme.secondary;
    final topPadding = MediaQuery.paddingOf(context).top;
    final hasCustomBg =
        _customBgPath != null && File(_customBgPath!).existsSync();
    final content = Stack(
      children: [
        MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: Material(
            type: .transparency,
            child: refreshIndicator(
              onRefresh: controller.onRefresh,
              child: onBuild(
                ListView(
                  padding: const .only(bottom: 150),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildTopBannerAndUser(
                      theme,
                      secondary,
                      topPadding,
                      hasCustomBg,
                    ),
                    _buildUserStatsRow(theme, secondary),
if (Pref.modernCardUi)
  (theme)
else
                    _buildActions(secondary),
                    for (final tab in controller.mineTabs)
                      switch (tab) {
                        .favorite => Obx(_buildFav),
                        .history => Obx(_buildHistory),
                        .later => Obx(_buildLater),
                        .sub => Obx(_buildSub),
                      },
                  ],
                ),
              ),
            ),
          ),
        ),
        if (widget.showBackBtn)
          Positioned(
            top: topPadding + 6,
            left: 8,
            child: BackButton(
              color: hasCustomBg ? Colors.white : null,
            ),
          ),
        Positioned(
          top: topPadding + 6,
          right: 10,
          child: _buildSingleMenuButton(theme, hasCustomBg),
        ),
      ],
    );

    if (PlatformUtils.isMobile && hasCustomBg) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
          systemStatusBarContrastEnforced: false,
        ),
        child: content,
      );
    }
    return content;
  }

  
    Widget _buildBentoGrid(ThemeData theme) { final isDark = theme.brightness == Brightness.dark; final cs = theme.colorScheme; final historyBg = isDark ? cs.secondaryContainer : const Color(0xFF5F748D); final historyFg = isDark ? cs.onSecondaryContainer : Colors.white; final downloadBg = isDark ? cs.surfaceContainerHighest : const Color(0xFF43556B); final downloadFg = isDark ? cs.onSurface : Colors.white; final laterBg = isDark ? cs.surfaceContainerHighest : const Color(0xFFE6DFD5); final laterFg = isDark ? cs.onSurface : const Color(0xFF2B2D30); final subBg = isDark ? cs.surfaceContainerHighest : const Color(0xFF6D829B); final subFg = isDark ? cs.onSurface : Colors.white; final settingBg = isDark ? cs.surfaceContainerHighest : const Color(0xFFEAE3DA); final settingFg = isDark ? cs.onSurface : const Color(0xFF2B2D30); return Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), child: Column(children: [Row(children: [Expanded(flex: 5, child: Material(color: historyBg, borderRadius: BorderRadius.circular(20), clipBehavior: Clip.antiAlias, child: InkWell(onTap: () => Get.toNamed('/history'), child: SizedBox(height: 152, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.history_rounded, color: historyFg, size: 28), const SizedBox(height: 10), Text('观看历史', style: TextStyle(color: historyFg, fontSize: 16, fontWeight: FontWeight.w600))]), ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: 0.62, minHeight: 5, backgroundColor: historyFg.withValues(alpha: 0.2), valueColor: AlwaysStoppedAnimation<Color>(historyFg.withValues(alpha: 0.85))))])))))), const SizedBox(width: 10), Expanded(flex: 6, child: Column(children: [SizedBox(height: 71, child: _buildBentoTile(title: '离线缓存', icon: Icons.download_rounded, bgColor: downloadBg, fgColor: downloadFg, onTap: () => Get.toNamed('/download'))), const SizedBox(height: 10), SizedBox(height: 71, child: _buildBentoTile(title: '稍后再看', icon: Icons.watch_later_outlined, bgColor: laterBg, fgColor: laterFg, onTap: () => Get.toNamed('/later')))]))]), const SizedBox(height: 10), Row(children: [Expanded(child: SizedBox(height: 68, child: _buildBentoTile(title: '我的订阅', icon: Icons.subscriptions_outlined, bgColor: subBg, fgColor: subFg, onTap: () => Get.toNamed('/subscription')))), const SizedBox(width: 10), Expanded(child: SizedBox(height: 68, child: _buildBentoTile(title: '系统设置', icon: Icons.settings_outlined, bgColor: settingBg, fgColor: settingFg, onTap: () => Get.toNamed('/setting'))))]),])); }

  Widget _buildBentoTile({
    required String title,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
    bool isLarge = false,
  }) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(isLarge ? 20 : 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isLarge ? 20 : 16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isLarge ? 20 : 14,
          ),
          child: Row(
            children: [
              Icon(icon, color: fgColor, size: isLarge ? 26 : 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isLarge ? 15 : 14,
                    fontWeight: FontWeight.w600,
                    color: fgColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBannerAndUser(
    ThemeData theme,
    Color secondary,
    double topPadding,
    bool hasCustomBg,
  ) {
    final bgColor = theme.scaffoldBackgroundColor;
    if (!hasCustomBg) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding + 56, bottom: 4),
        child: _buildUserIdentityRow(theme, secondary),
      );
    }
    return Stack(
      children: [
        Obx(() {
          final idx = _mainController.selectedIndex.value;
          final isMineActive =
              widget.showBackBtn ||
              (idx < _mainController.navigationBars.length &&
                  _mainController.navigationBars[idx] == NavigationBarType.mine);
          return TickerMode(
            enabled: isMineActive,
            child: Image.file(
              File(_customBgPath!),
              width: double.infinity,
              fit: BoxFit.fitWidth,
              errorBuilder: (_, _, _) => SizedBox(height: topPadding + 120),
            ),
          );
        }),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 150,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.55, 1.0],
                colors: [
                  bgColor.withValues(alpha: 0.0),
                  bgColor.withValues(alpha: 0.85),
                  bgColor,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 4,
          child: _buildUserIdentityRow(theme, secondary),
        ),
      ],
    );
  }

  Widget _buildSingleMenuButton(ThemeData theme, bool hasCustomBg) {
    return PopupMenuButton<String>(
      tooltip: '更多操作',
      icon: Icon(
        Icons.more_vert,
        size: 22,
        color: hasCustomBg ? Colors.white : theme.colorScheme.onSurface,
        shadows: hasCustomBg
            ? const [
                Shadow(
                  color: Color(0x73000000),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      onSelected: (value) {
        switch (value) {
          case 'search':
            Get.toNamed('/search');
          case 'reply':
            Get.toNamed('/myReply');
          case 'anonymity':
            MineController.onChangeAnonymity();
          case 'switch_account':
            LoginPageController.switchAccountDialog(context);
          case 'theme':
            controller.onChangeTheme();
          case 'pick_bg':
            _pickCustomBg();
          case 'reset_bg':
            _resetCustomBg();
          case 'setting':
            Get.toNamed('/setting', preventDuplicates: false);
        }
      },
      itemBuilder: (_) => [
        if (!_mainController.hasHome)
          const PopupMenuItem(
            value: 'search',
            child: Row(
              spacing: 10,
              children: [
                Icon(Icons.search, size: 20),
                Text('搜索'),
              ],
            ),
          ),
        if (GStorage.reply != null)
          const PopupMenuItem(
            value: 'reply',
            child: Row(
              spacing: 10,
              children: [
                Icon(Icons.message_outlined, size: 20),
                Text('评论记录'),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'anonymity',
          child: Row(
            spacing: 10,
            children: [
              Icon(
                MineController.anonymity.value
                    ? MdiIcons.incognito
                    : MdiIcons.incognitoOff,
                size: 20,
              ),
              Text(MineController.anonymity.value ? '退出无痕模式' : '进入无痕模式'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'switch_account',
          child: Row(
            spacing: 10,
            children: [
              Icon(Icons.switch_account_outlined, size: 20),
              Text('切换账号'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'theme',
          child: Row(
            spacing: 10,
            children: [
              Icon(controller.themeType.value.icon.icon, size: 20),
              Text('切换至${controller.nextThemeType.label}主题'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'pick_bg',
          child: Row(
            spacing: 10,
            children: [
              Icon(Icons.wallpaper_outlined, size: 20),
              Text('自定义背景图'),
            ],
          ),
        ),
        if (_customBgPath != null)
          const PopupMenuItem(
            value: 'reset_bg',
            child: Row(
              spacing: 10,
              children: [
                Icon(Icons.restore_outlined, size: 20),
                Text('清除背景图'),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'setting',
          child: Row(
            spacing: 10,
            children: [
              Icon(Icons.settings_outlined, size: 20),
              Text('设置'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(Color primary) {
    return Row(
      mainAxisAlignment: .spaceEvenly,
      children: controller.list
          .map(
            (e) => Flexible(
              child: InkWell(
                onTap: e.onTap,
                borderRadius: Style.mdRadius,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Column(
                      spacing: 6,
                      mainAxisSize: .min,
                      mainAxisAlignment: .center,
                      children: [
                        Icon(e.icon, color: primary),
                        Text(
                          e.title,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildUserIdentityRow(ThemeData theme, Color secondary) {
    final coinLabelStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      color: theme.colorScheme.outline,
    );
    final coinValStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      fontWeight: FontWeight.bold,
      color: secondary,
    );
    return Obx(() {
      final userInfo = controller.userInfo.value;
      final levelInfo = userInfo.levelInfo;
      final hasLevel = levelInfo != null;
      final isVip = userInfo.vipStatus != null && userInfo.vipStatus! > 0;
      return GestureDetector(
        behavior: .opaque,
        onTap: controller.onLogin,
        onLongPress: () {
          Feedback.forLongPress(context);
          controller.onLogin(true);
        },
        onSecondaryTap: PlatformUtils.isMobile
            ? null
            : () => controller.onLogin(true),
        child: Row(
          mainAxisSize: .min,
          children: [
            const SizedBox(width: 20),
            userInfo.face != null
                ? Stack(
                    clipBehavior: .none,
                    children: [
                      NetworkImgLayer(
                        src: userInfo.face,
                        type: .avatar,
                        width: 55,
                        height: 55,
                      ),
                      if (isVip)
                        Positioned(
                          right: -1,
                          bottom: -2,
                          child: SvgPicture.asset(
                            Assets.vipIcon,
                            height: 19,
                            semanticsLabel: "大会员",
                          ),
                        ),
                    ],
                  )
                : ClipOval(
                    child: Image.asset(
                      width: 55,
                      height: 55,
                      cacheHeight: 55.cacheSize(context),
                      Assets.avatarPlaceHolder,
                      semanticLabel: "默认头像",
                    ),
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: .min,
                mainAxisAlignment: .center,
                crossAxisAlignment: .start,
                children: [
                  Row(
                    spacing: 6,
                    children: [
                      Flexible(
                        child: Text(
                          userInfo.uname ?? '点击登录',
                          style: theme.textTheme.titleMedium!.copyWith(
                            height: 1,
                            color: isVip && userInfo.vipType == 2
                                ? theme.colorScheme.vipColor
                                : null,
                          ),
                          maxLines: 1,
                          overflow: .ellipsis,
                        ),
                      ),
                      BiliUtils.levelPicture(
                        levelInfo?.currentLevel ?? 0,
                        isSeniorMember: userInfo.isSeniorMember == 1,
                        height: 10,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '硬币 ',
                          style: coinLabelStyle,
                        ),
                        TextSpan(
                          text: userInfo.money?.toString() ?? '-',
                          style: coinValStyle,
                        ),
                        TextSpan(
                          text: "      经验 ",
                          style: coinLabelStyle,
                        ),
                        TextSpan(
                          text: levelInfo?.currentExp?.toString() ?? '-',
                          style: coinValStyle,
                        ),
                        TextSpan(
                          text: "/${levelInfo?.nextExp ?? '-'}",
                          style: coinLabelStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 225),
                    child: LinearProgressIndicator(
                      minHeight: 2.25,
                      value: hasLevel
                          ? levelInfo.currentExp! / levelInfo.nextExp!
                          : 0,
                      backgroundColor: theme.colorScheme.outline.withValues(
                        alpha: 0.4,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(secondary),
                      stopIndicatorColor: Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      );
    });
  }

  Widget _buildUserStatsRow(ThemeData theme, Color secondary) {
    final style = TextStyle(
      fontSize: theme.textTheme.titleMedium!.fontSize,
      fontWeight: FontWeight.bold,
    );
    final labelStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    return Obx(() {
      final userStat = controller.userStat.value;
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          mainAxisAlignment: .spaceEvenly,
          children: [
            _btn(
              count: userStat.dynamicCount,
              countStyle: style,
              name: '动态',
              labelStyle: labelStyle,
              onTap: () => controller.push('memberDynamics'),
            ),
            _btn(
              count: userStat.following,
              countStyle: style,
              name: '关注',
              labelStyle: labelStyle,
              onTap: () => controller.push('follow'),
            ),
            _btn(
              count: userStat.follower,
              countStyle: style,
              name: '粉丝',
              labelStyle: labelStyle,
              onTap: () => controller.push('fan'),
            ),
          ],
        ),
      );
    });
  }

  Widget _btn({
    required int? count,
    required TextStyle countStyle,
    required String name,
    required TextStyle? labelStyle,
    required VoidCallback onTap,
  }) {
    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: Style.mdRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: AspectRatio(
            aspectRatio: 1,
            child: Column(
              spacing: 4,
              mainAxisSize: .min,
              mainAxisAlignment: .center,
              children: [
                Text(
                  count?.toString() ?? '-',
                  style: countStyle,
                ),
                Text(
                  name,
                  style: labelStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _autoRefresh(MineRefreshMixin tabCtr) => Timer(
    const Duration(milliseconds: 150),
    () => tabCtr.onRefresh(isManual: false),
  );

  Widget _buildFav() {
    return _buildTab(
      .favorite,
      controller.favCtr!,
      itemBuilder: (element) => FavFolderItem(
        item: element,
        onPop: () => _autoRefresh(controller.favCtr!),
      ),
      onPushDetail: () => Get.toNamed(
        '/fav',
      )?.whenComplete(() => _autoRefresh(controller.favCtr!)),
    );
  }

  Widget _buildHistory() {
    return _buildTab(
      .history,
      controller.historyCtr!,
      itemBuilder: (element) => MineHistoryItem(
        item: element,
        onPop: () => _autoRefresh(controller.historyCtr!),
      ),
      onPushDetail: () => Get.toNamed(
        '/history',
      )?.whenComplete(() => _autoRefresh(controller.historyCtr!)),
    );
  }

  Widget _buildLater() {
    return _buildTab(
      .later,
      controller.laterCtr!,
      itemBuilder: (element) => MineLaterItem(
        item: element,
        onPop: () => _autoRefresh(controller.laterCtr!),
      ),
      onPushDetail: () => Get.toNamed(
        '/later',
      )?.whenComplete(() => _autoRefresh(controller.laterCtr!)),
    );
  }

  Widget _buildSub() {
    return _buildTab(
      .sub,
      controller.subCtr!,
      itemBuilder: (element) => MineSubItem(
        item: element,
        onPop: () => _autoRefresh(controller.subCtr!),
      ),
      onPushDetail: () => Get.toNamed(
        '/subscription',
      )?.whenComplete(() => _autoRefresh(controller.subCtr!)),
    );
  }

  Widget _buildTab<R, T>(
    MineTabType tab,
    MineRefreshMixin<R, T> tabCtr, {
    required Widget Function(T element) itemBuilder,
    required VoidCallback onPushDetail,
  }) {
    final Widget child;
    switch (tabCtr.loadingState.value) {
      case Loading():
        return const SizedBox.shrink();
      case Success(:final response):
        if (response == null || response.isEmpty) {
          return const SizedBox.shrink();
        }
        child = SizedBox(
          height: 180,
          child: ListView.separated(
            itemCount: response.length,
            controller: tabCtr.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const .only(left: 20, top: 10, right: 20),
            itemBuilder: (context, index) {
              if (index == response.length - 1) {
                tabCtr.onLoadMore();
              }
              return SizedBox(width: 180, child: itemBuilder(response[index]));
            },
            scrollDirection: .horizontal,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
          ),
        );
      case Error(:final errMsg):
        if (errMsg == null) return const SizedBox.shrink();
        child = SizedBox(
          height: 160,
          child: Center(child: Text(errMsg, textAlign: .center)),
        );
    }
    final secondary = theme.colorScheme.secondary;
    return Column(
      children: [
        Divider(
          height: 20,
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        ListTile(
          dense: true,
          onTap: onPushDetail,
          title: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${tab.label} ',
                    style: const TextStyle(fontSize: 16, fontWeight: .bold),
                  ),
                  if (tabCtr.count != null)
                    TextSpan(
                      text: '${tabCtr.count} ',
                      style: TextStyle(color: secondary),
                    ),
                  WidgetSpan(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          trailing: IconButton(
            tooltip: '刷新',
            onPressed: tabCtr.onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ),
        child,
      ],
    );
  }
}
