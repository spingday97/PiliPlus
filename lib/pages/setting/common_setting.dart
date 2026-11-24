import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/models/common/setting_type.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:material_ui/material_ui.dart';
import 'package:PiliPlus/utils/neu_style.dart';

class CommonSetting extends StatefulWidget {
  const CommonSetting({
    super.key,
    required this.settingType,
    this.showAppBar = true,
  });

  final bool showAppBar;
  final SettingType settingType;

  @override
  State<CommonSetting> createState() => _CommonSettingState();
}

class _CommonSettingState extends State<CommonSetting> {
  late EdgeInsets padding;
  late List<SettingsModel> settings;

  void _initSetting() {
    settings = widget.settingType.settings;
  }

  @override
  void initState() {
    super.initState();
    _initSetting();
  }

  @override
  void didUpdateWidget(CommonSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settingType != oldWidget.settingType) {
      _initSetting();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    padding = MediaQuery.viewPaddingOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    return SimpleScaffold(
      appBar: showAppBar ? AppBar(title: Text(widget.settingType.title)) : null,
      body: Pref.iosStyleUi ? SingleChildScrollView(key: ValueKey(widget.settingType), padding: EdgeInsets.fromLTRB(16 + (showAppBar ? padding.left : 0), 10, 16 + (showAppBar ? padding.right : 0), padding.bottom + 100), child: Container(decoration: NeuStyle.raised(isDark: Theme.of(context).brightness == Brightness.dark, radius: 18, blur: 12, offset: 5), clipBehavior: Clip.antiAlias, child: Column(mainAxisSize: MainAxisSize.min, children: [for (int i = 0; i < settings.length; i++) ...[if (i > 0) const Divider(height: 0.5, thickness: 0.5), settings[i].widget]]))) : ListView.builder(
        key: ValueKey(widget.settingType),
        padding: EdgeInsets.only(
          top: Pref.modernCardUi ? 8 : 0,
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        itemCount: settings.length,
       itemBuilder: (context, index) => Pref.modernCardUi ? Container(margin: const EdgeInsets.fromLTRB(14, 0, 14, 8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12), width: 0.7)), clipBehavior: Clip.antiAlias, child: settings[index].widget) : settings[index].widget,
      ),
    );
  }
}
