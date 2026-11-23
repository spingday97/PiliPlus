import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/models/common/setting_type.dart';
import 'package:PiliPlus/pages/about/view.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/setting/common_setting.dart';
import 'package:PiliPlus/pages/setting/widgets/multi_select_dialog.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class _SettingsModel {
  final SettingType type;
  final String? subtitle;
  final Icon icon;

  const _SettingsModel({
    required this.type,
    this.subtitle,
    required this.icon,
  });
}

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late SettingType _type = .privacySetting;
  final RxBool _noAccount = Accounts.account.isEmpty.obs;
  late bool _isPortrait;
  late ThemeData theme;

  static const List<_SettingsModel> _items = [
    _SettingsModel(
      type: .styleSetting,
      subtitle: '横屏适配（平板）、侧栏、列宽、首页、动态红点、主题、字号、图片、帧率等',
      icon: Icon(Icons.style_outlined),
    ),
    _SettingsModel(
      type: .videoSetting,
      subtitle: '画质、音质、解码、缓冲、音频输出等',
      icon: Icon(Icons.video_settings_outlined),
    ),
    _SettingsModel(
      type: .playSetting,
      subtitle: '双击/长按、全屏、后台播放、弹幕、字幕、底部进度条等',
      icon: Icon(Icons.touch_app_outlined),
    ),
    _SettingsModel(
      type: .dmSetting,
      subtitle: '点击弹幕、弹幕行高、彩色弹幕、合并弹幕',
      icon: Icon(CustomIcons.dm_settings),
    ),
    _SettingsModel(
      type: .recommendSetting,
      subtitle: '推荐来源（web/app）、刷新保留内容、过滤器',
      icon: Icon(Icons.explore_outlined),
    ),
    _SettingsModel(
      type: .replySetting,
      subtitle: '过滤、屏蔽、记录、默认展示等',
      icon: Icon(Icons.comment_outlined),
    ),
    _SettingsModel(
      type: .dynSetting,
      subtitle: '过滤、屏蔽、默认展示等',
      icon: Icon(CustomIcons.motion_photos_on_outlined),
    ),
    _SettingsModel(
      type: .privacySetting,
      subtitle: '账号、黑名单',
      icon: Icon(Icons.privacy_tip_outlined),
    ),
    _SettingsModel(
      type: .extraSetting,
      subtitle: '震动、搜索、收藏、ai、评论、动态、代理、更新检查等',
      icon: Icon(Icons.extension_outlined),
    ),
    _SettingsModel(
      type: .about,
      icon: Icon(Icons.info_outline),
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    _isPortrait = MediaQuery.isPortraitOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return SimpleScaffold(
      appBar: AppBar(
        title: _isPortrait ? const Text('设置') : Text(_type.title),
      ),
      body: ViewSafeArea(
        child: _isPortrait
            ? _buildList(theme)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildList(theme),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    flex: 6,
                    child: switch (_type) {
                      .about => const AboutPage(showAppBar: false),
                      _ => CommonSetting(settingType: _type, showAppBar: false),
                    },
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _noAccount.close();
    super.dispose();
  }

  void _toPage(SettingType type) {
    if (_isPortrait) {
      Get.to(
        () => switch (type) {
          .about => const AboutPage(),
          _ => CommonSetting(settingType: type),
        },
      );
    } else {
      _type = type;
      setState(() {});
    }
  }

  Color? _getTileColor(ThemeData theme, SettingType type) {
    if (_isPortrait) {
      return null;
    } else {
      return type == _type ? theme.colorScheme.onInverseSurface : null;
    }
  }

  Widget _buildList(ThemeData theme) {
    final padding = MediaQuery.viewPaddingOf(context);
    TextStyle titleStyle = theme.textTheme.titleMedium!;
    TextStyle subTitleStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    if (Pref.modernCardUi) {
      return _buildModernList(theme, padding, titleStyle, subTitleStyle);
    }
    return ListView(
      padding: EdgeInsets.only(bottom: padding.bottom + 100),
      children: [
        _buildSearchItem(theme),
        ..._items
            .take(_items.length - 1)
            .map(
              (item) => ListTile(
                tileColor: _getTileColor(theme, item.type),
                onTap: () => _toPage(item.type),
                leading: item.icon,
                title: Text(item.type.title, style: titleStyle),
                subtitle: item.subtitle == null
                    ? null
                    : Text(item.subtitle!, style: subTitleStyle),
              ),
            ),
        ListTile(
          onTap: () => LoginPageController.switchAccountDialog(context),
          leading: const Icon(Icons.switch_account_outlined),
          title: Text('切换账号', style: titleStyle),
        ),
        Obx(
          () => _noAccount.value
              ? const SizedBox.shrink()
              : ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  onTap: () => _logoutDialog(context),
                  title: Text('退出登录', style: titleStyle),
                ),
        ),
        ListTile(
          tileColor: _getTileColor(theme, _items.last.type),
          onTap: () => _toPage(_items.last.type),
          leading: _items.last.icon,
          title: Text(_items.last.type.title, style: titleStyle),
        ),
      ],
    );
  }

  Future<void> _removeAccounts(Set<LoginAccount> accounts) async {
    await Accounts.deleteAll(accounts);
    if (mounted) _noAccount.value = Accounts.account.isEmpty;
  }

  static Future<LoginAccount?> _logoutWrapper(LoginAccount account) async {
    try {
      final res = await LoginHttp.logout(account);
      return res.isSuccess ? account : null;
    } catch (e, s) {
      Utils.reportError(e, s);
      return null;
    }
  }

  Future<void> _logoutDialog(BuildContext context) async {
    final result = await showDialog<Set<LoginAccount>>(
      context: context,
      builder: (context) => MultiSelectDialog<LoginAccount>(
        title: '选择要登出的账号uid',
        initValues: const Iterable.empty(),
        values: {
          for (final i in Accounts.account.values) i: i.mid.toString(),
        },
      ),
    );
    if (!context.mounted || result == null || result.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('提示'),
          content: Text(
            "确认要退出以下账号登录吗\n\n${result.map((i) => i.mid).join('\n')}",
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text(
                '点错了',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                _removeAccounts(result);
              },
              child: Text(
                '仅登出',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            TextButton(
              onPressed: () async {
                SmartDialog.showLoading();
                final res = await Future.wait(result.map(_logoutWrapper));
                SmartDialog.dismiss();
                final logoutAccounts = res.nonNulls.toSet();
                if (logoutAccounts.isEmpty) {
                  SmartDialog.showToast('所选账号均退出登录失败');
                } else {
                  Get.back();
                  _removeAccounts(logoutAccounts);
                  if (logoutAccounts.length != result.length) {
                    result.removeWhere(logoutAccounts.contains);
                    SmartDialog.showToast(
                      '账号 ${result.map((i) => i.mid).join(",")} 退出登录失败',
                    );
                  }
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

    Widget _buildModernList(
    ThemeData theme,
    EdgeInsets padding,
    TextStyle titleStyle,
    TextStyle subTitleStyle,
  ) {
    _SettingsModel itemOf(SettingType type) =>
        _items.firstWhere((e) => e.type == type); Color _badgeColor(SettingType type) => switch (type) { SettingType.styleSetting => const Color(0xFFFF2D55), SettingType.videoSetting => const Color(0xFF007AFF), SettingType.playSetting => const Color(0xFFAF52DE), SettingType.dmSetting => const Color(0xFFFF9500), SettingType.recommendSetting => const Color(0xFF34C759), SettingType.replySetting => const Color(0xFF30B0C7), SettingType.dynSetting => const Color(0xFF5856D6), SettingType.privacySetting => const Color(0xFFFF3B30), SettingType.extraSetting => const Color(0xFFFFCC00), SettingType.about => const Color(0xFF8E8E93) };

    Widget buildTile({
      required Widget icon,
      required String title,
      String? subtitle,
      required VoidCallback onTap,
      Color? iconColor,
      bool selected = false,
    }) {
      final color = iconColor ?? theme.colorScheme.primary;
      return ListTile(
        selected: selected,
        tileColor: selected ? theme.colorScheme.onInverseSurface : null,
        onTap: onTap,
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          child: IconTheme(
            data: const IconThemeData(color: Colors.white, size: 17),
            child: icon,
          ),
        ),
        title: Text(title, style: titleStyle),
        subtitle: subtitle == null ? null : Text(subtitle, style: subTitleStyle),
        trailing: Icon(Icons.chevron_right_rounded, size: 20, color: theme.colorScheme.outline.withValues(alpha: 0.55)),
      );
    }

    Widget buildSettingTile(SettingType type, String title) {
      final item = itemOf(type);
      return buildTile(
        icon: item.icon,
        title: title,
        subtitle: item.subtitle, iconColor: _badgeColor(item.type),
        selected: !_isPortrait && _type == type,
        onTap: () => _toPage(type),
      );
    }

    Widget buildGroup(String title, List<Widget> children) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.dividerColor,
                  width: 0.5,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [for (int i = 0; i < children.length; i++) ...[if (i > 0) Divider(height: 0.5, thickness: 0.5, color: theme.dividerColor), children[i]]]),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.only(bottom: padding.bottom + 100),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
                width: 0.7,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildSearchItem(theme),
          ),
        ),
        buildGroup('外观与交互', [
          buildSettingTile(SettingType.styleSetting, '外观与界面'),
          buildSettingTile(SettingType.dynSetting, '动态与动态流'),
          buildSettingTile(SettingType.recommendSetting, '推荐与首页'),
        ]),
        buildGroup('播放与体验', [
          buildSettingTile(SettingType.videoSetting, '音视频解码'),
          buildSettingTile(SettingType.playSetting, '播放控制'),
          buildSettingTile(SettingType.dmSetting, '弹幕设置'),
          buildSettingTile(SettingType.replySetting, '评论设置'),
        ]),
        buildGroup('账号与安全', [
          buildSettingTile(SettingType.privacySetting, '隐私与账号'),
          buildTile(
            icon: const Icon(Icons.switch_account_outlined),
            title: '切换账号',
            onTap: () => LoginPageController.switchAccountDialog(context),
          ),
          Obx(
            () => _noAccount.value
                ? const SizedBox.shrink()
                : buildTile(
                    icon: const Icon(Icons.logout_outlined),
                    iconColor: theme.colorScheme.error,
                    title: '退出登录',
                    onTap: () => _logoutDialog(context),
                  ),
          ),
        ]),
        buildGroup('系统与关于', [
          buildSettingTile(SettingType.extraSetting, '更多设置'),
          buildSettingTile(SettingType.about, '关于与检查更新'),
        ]),
      ],
    );
  }

  Widget _buildSearchItem(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: 8,
    ),
    child: Material(
      color: theme.colorScheme.onInverseSurface,
      borderRadius: const BorderRadius.all(Radius.circular(50)),
      child: InkWell(
        onTap: () => Get.toNamed('/settingsSearch'),
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  size: 18,
                  applyTextScaling: true,
                  Icons.search,
                ),
                Text(
                  ' 搜索',
                  style: TextStyle(height: 1),
                  strutStyle: StrutStyle(height: 1, leading: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
