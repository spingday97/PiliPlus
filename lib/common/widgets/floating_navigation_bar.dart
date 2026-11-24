// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/neu_style.dart';
import 'package:material_ui/material_ui.dart';

const double _kMaxLabelTextScaleFactor = 1.3;

const _kNavigationHeight = 58.0;
const _kIndicatorHeight = _kNavigationHeight - 2 * _kIndicatorPaddingInt;
const _kIndicatorWidth = 78.0;
const _kIndicatorPaddingInt = 4.0;
const _kIndicatorPadding = EdgeInsets.all(_kIndicatorPaddingInt);
const _kBorderRadius = BorderRadius.all(.circular(_kNavigationHeight / 2));
const _kNavigationShape = RoundedSuperellipseBorder(
  borderRadius: _kBorderRadius,
);

/// ref [NavigationBar]
class FloatingNavigationBar extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  FloatingNavigationBar({
    super.key,
    this.animationDuration = const Duration(milliseconds: 340),
    this.selectedIndex = 0,
    required this.destinations,
    this.onDestinationSelected,
    this.backgroundColor,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.indicatorColor,
    this.indicatorShape,
    this.labelBehavior,
    this.overlayColor,
    this.labelTextStyle,
    this.labelPadding,
    this.bottomPadding = 8.0,
  }) : assert(destinations.length >= 2),
       assert(0 <= selectedIndex && selectedIndex < destinations.length);

  final Duration animationDuration;
  final int selectedIndex;
  final List<Widget> destinations;
  final ValueChanged<int>? onDestinationSelected;
  final Color? backgroundColor;
  final double? elevation;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Color? indicatorColor;
  final ShapeBorder? indicatorShape;
  final NavigationDestinationLabelBehavior? labelBehavior;
  final WidgetStateProperty<Color?>? overlayColor;
  final WidgetStateProperty<TextStyle?>? labelTextStyle;
  final EdgeInsetsGeometry? labelPadding;
  final double bottomPadding;

  VoidCallback _handleTap(int index) {
    return onDestinationSelected != null
        ? () => onDestinationSelected!(index)
        : () {};
  }

  @override
  Widget build(BuildContext context) {
    final defaults = _NavigationBarDefaultsM3(context);
    final colors = Theme.of(context).colorScheme;
    final navigationBarTheme = NavigationBarTheme.of(context);
    final effectiveLabelBehavior =
        labelBehavior ??
        navigationBarTheme.labelBehavior ??
        defaults.labelBehavior!;

    final padding = MediaQuery.viewPaddingOf(context);
    final totalWidth = destinations.length * _kIndicatorWidth;
    final innerWidth = totalWidth - 2 * _kIndicatorPaddingInt;
    final itemWidth = innerWidth / destinations.length;
    final effectiveIndicatorColor =
        indicatorColor ??
        (Pref.iosStyleUi ? colors.primary.withValues(alpha: 0.12) : navigationBarTheme.indicatorColor ??
        defaults.indicatorColor)!;

    final baseBg = ElevationOverlay.applySurfaceTint(
      backgroundColor ??
          navigationBarTheme.backgroundColor ??
          defaults.backgroundColor!,
      surfaceTintColor ??
          navigationBarTheme.surfaceTintColor ??
          defaults.surfaceTintColor,
      elevation ?? navigationBarTheme.elevation ?? defaults.elevation!,
    );

    final isModern = Pref.modernCardUi && !Pref.iosStyleUi; final navHeight = isModern ? 52.0 : _kNavigationHeight; return Padding(
      padding: .fromLTRB(
        padding.left,
        0,
        padding.right,
        bottomPadding + padding.bottom,
      ),
      child: SizedBox(
        height: (Pref.modernCardUi && !Pref.iosStyleUi) ? 52.0 : _kNavigationHeight,
        width: totalWidth,
        child: DecoratedBox(
          decoration: Pref.iosStyleUi ? NeuStyle.raised(isDark: colors.isDark, radius: _kNavigationHeight / 2, blur: 14, offset: 5) : ShapeDecoration(
            color: Pref.iosStyleUi ? (colors.isDark ? const Color(0xFF1C1C1E).withValues(alpha: 0.90) : Colors.white.withValues(alpha: 0.90)) : (Pref.modernCardUi && !Pref.iosStyleUi) ? (colors.isDark ? const Color(0xFF1C1C1E) : Colors.white) : baseBg.withValues(alpha: 0.94),
            shadows: [
              BoxShadow(
                color: colors.isDark
                    ? Colors.black.withValues(alpha: 0.36)
                    : Colors.black.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
            shape: RoundedSuperellipseBorder(
              side: Pref.iosStyleUi ? BorderSide(color: colors.isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.08), width: 0.6) : (Pref.modernCardUi && !Pref.iosStyleUi) ? BorderSide(color: colors.isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08), width: 0.8) : defaults.borderSide,
              borderRadius: _kBorderRadius,
            ),
          ),
          child: Padding(
            padding: _kIndicatorPadding,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: animationDuration,
                  curve: Curves.easeOutBack,
                  left: selectedIndex * itemWidth,
                  top: 0,
                  bottom: 0,
                  width: itemWidth,
                  child: DecoratedBox(
                    decoration: Pref.iosStyleUi ? NeuStyle.inset(isDark: colors.isDark, radius: _kIndicatorHeight / 2) : ShapeDecoration(shape: indicatorShape ?? _kNavigationShape, color: (Pref.modernCardUi && !Pref.iosStyleUi) ? Colors.transparent : effectiveIndicatorColor), child: (Pref.modernCardUi && !Pref.iosStyleUi) ? Align(alignment: Alignment.bottomCenter, child: Container(width: 16, height: 3, decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(1.5)))) : null,
                  ),
                ),
                Row(
                  crossAxisAlignment: .stretch,
                  children: <Widget>[
                    for (int i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _SelectableAnimatedBuilder(
                          duration: animationDuration,
                          isSelected: i == selectedIndex,
                          builder: (context, animation) {
                            return _NavigationDestinationInfo(
                              index: i,
                              selectedIndex: selectedIndex,
                              totalNumberOfDestinations: destinations.length,
                              selectedAnimation: animation,
                              labelBehavior: effectiveLabelBehavior,
                              indicatorColor: indicatorColor,
                              indicatorShape: indicatorShape,
                              overlayColor: overlayColor,
                              onTap: _handleTap(i),
                              labelTextStyle: labelTextStyle,
                              labelPadding: labelPadding,
                              child: destinations[i],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FloatingNavigationDestination extends StatelessWidget {
  const FloatingNavigationDestination({
    super.key,
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.tooltip,
    this.enabled = true,
  });

  final Widget icon;

  final Widget? selectedIcon;

  final String label;

  final String? tooltip;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final info = _NavigationDestinationInfo.of(context);
    const selectedState = <WidgetState>{WidgetState.selected};
    const unselectedState = <WidgetState>{};
    const disabledState = <WidgetState>{WidgetState.disabled};

    final navigationBarTheme = NavigationBarTheme.of(context);
    final defaults = _NavigationBarDefaultsM3(context);
    final animation = info.selectedAnimation;
    final isSelected = info.index == info.selectedIndex;

    return _NavigationDestinationBuilder(
      label: label,
      tooltip: tooltip,
      enabled: enabled,
      buildIcon: (context) {
        final IconThemeData selectedIconTheme =
            navigationBarTheme.iconTheme?.resolve(selectedState) ??
            defaults.iconTheme!.resolve(selectedState)!;
        final IconThemeData unselectedIconTheme =
            navigationBarTheme.iconTheme?.resolve(unselectedState) ??
            defaults.iconTheme!.resolve(unselectedState)!;
        final IconThemeData disabledIconTheme =
            navigationBarTheme.iconTheme?.resolve(disabledState) ??
            defaults.iconTheme!.resolve(disabledState)!;

        final Widget selectedIconWidget = IconTheme.merge(
          data: enabled ? selectedIconTheme : disabledIconTheme,
          child: selectedIcon ?? icon,
        );
        final Widget unselectedIconWidget = IconTheme.merge(
          data: enabled ? unselectedIconTheme : disabledIconTheme,
          child: icon,
        );

        return AnimatedScale(
          scale: isSelected ? 1.08 : 0.96,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutBack,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(isSelected),
              child: isSelected ? selectedIconWidget : unselectedIconWidget,
            ),
          ),
        );
      },
      buildLabel: (context) {
        final TextStyle? effectiveSelectedLabelTextStyle =
            info.labelTextStyle?.resolve(selectedState) ??
            navigationBarTheme.labelTextStyle?.resolve(selectedState) ??
            defaults.labelTextStyle!.resolve(selectedState);
        final TextStyle? effectiveUnselectedLabelTextStyle =
            info.labelTextStyle?.resolve(unselectedState) ??
            navigationBarTheme.labelTextStyle?.resolve(unselectedState) ??
            defaults.labelTextStyle!.resolve(unselectedState);
        final TextStyle? effectiveDisabledLabelTextStyle =
            info.labelTextStyle?.resolve(disabledState) ??
            navigationBarTheme.labelTextStyle?.resolve(disabledState) ??
            defaults.labelTextStyle!.resolve(disabledState);
        final EdgeInsetsGeometry labelPadding =
            info.labelPadding ??
            navigationBarTheme.labelPadding ??
            defaults.labelPadding!;

        final textStyle = enabled
            ? animation.isForwardOrCompleted
                  ? effectiveSelectedLabelTextStyle
                  : effectiveUnselectedLabelTextStyle
            : effectiveDisabledLabelTextStyle;

        return Padding(
          padding: labelPadding,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: _kMaxLabelTextScaleFactor,
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: textStyle ?? const TextStyle(),
              child: Text(label),
            ),
          ),
        );
      },
    );
  }
}

class _NavigationDestinationBuilder extends StatefulWidget {
  const _NavigationDestinationBuilder({
    required this.buildIcon,
    required this.buildLabel,
    required this.label,
    this.tooltip,
    this.enabled = true,
  });

  final WidgetBuilder buildIcon;

  final WidgetBuilder buildLabel;

  final String label;

  final String? tooltip;

  final bool enabled;

  @override
  State<_NavigationDestinationBuilder> createState() =>
      _NavigationDestinationBuilderState();
}

class _NavigationDestinationBuilderState
    extends State<_NavigationDestinationBuilder> {
  final GlobalKey iconKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final info = _NavigationDestinationInfo.of(context);

    final child = GestureDetector(
      behavior: .opaque,
      onTap: widget.enabled ? info.onTap : null,
      child: _NavigationBarDestinationLayout(
        icon: widget.buildIcon(context),
        iconKey: iconKey,
        label: widget.buildLabel(context),
      ),
    );
    if (info.labelBehavior == .alwaysShow) {
      return child;
    }
    return _NavigationBarDestinationTooltip(
      message: widget.tooltip ?? widget.label,
      child: child,
    );
  }
}

class _NavigationDestinationInfo extends InheritedWidget {
  const _NavigationDestinationInfo({
    required this.index,
    required this.selectedIndex,
    required this.totalNumberOfDestinations,
    required this.selectedAnimation,
    required this.labelBehavior,
    required this.indicatorColor,
    required this.indicatorShape,
    required this.overlayColor,
    required this.onTap,
    this.labelTextStyle,
    this.labelPadding,
    required super.child,
  });

  final int index;

  final int selectedIndex;

  final int totalNumberOfDestinations;

  final Animation<double> selectedAnimation;

  final NavigationDestinationLabelBehavior labelBehavior;

  final Color? indicatorColor;

  final ShapeBorder? indicatorShape;

  final WidgetStateProperty<Color?>? overlayColor;

  final VoidCallback onTap;

  final WidgetStateProperty<TextStyle?>? labelTextStyle;

  final EdgeInsetsGeometry? labelPadding;

  static _NavigationDestinationInfo of(BuildContext context) {
    final _NavigationDestinationInfo? result = context
        .dependOnInheritedWidgetOfExactType<_NavigationDestinationInfo>();
    assert(
      result != null,
      'Navigation destinations need a _NavigationDestinationInfo parent, '
      'which is usually provided by NavigationBar.',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(_NavigationDestinationInfo oldWidget) {
    return index != oldWidget.index ||
        selectedIndex != oldWidget.selectedIndex ||
        totalNumberOfDestinations != oldWidget.totalNumberOfDestinations ||
        selectedAnimation != oldWidget.selectedAnimation ||
        labelBehavior != oldWidget.labelBehavior ||
        onTap != oldWidget.onTap;
  }
}

class _NavigationBarDestinationLayout extends StatelessWidget {
  const _NavigationBarDestinationLayout({
    required this.icon,
    required this.iconKey,
    required this.label,
  });

  final Widget icon;

  final GlobalKey iconKey;

  final Widget label;

  @override
  Widget build(BuildContext context) {
    return _DestinationLayoutAnimationBuilder(
      builder: (context, animation) {
        return CustomMultiChildLayout(
          delegate: _NavigationDestinationLayoutDelegate(animation: animation),
          children: <Widget>[
            LayoutId(
              id: _NavigationDestinationLayoutDelegate.iconId,
              child: KeyedSubtree(key: iconKey, child: icon),
            ),
            LayoutId(
              id: _NavigationDestinationLayoutDelegate.labelId,
              child: FadeTransition(
                alwaysIncludeSemantics: true,
                opacity: animation,
                child: label,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DestinationLayoutAnimationBuilder extends StatelessWidget {
  const _DestinationLayoutAnimationBuilder({required this.builder});

  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  Widget build(BuildContext context) {
    final info = _NavigationDestinationInfo.of(context);
    switch (info.labelBehavior) {
      case NavigationDestinationLabelBehavior.alwaysShow:
        return builder(context, kAlwaysCompleteAnimation);
      case NavigationDestinationLabelBehavior.alwaysHide:
        return builder(context, kAlwaysDismissedAnimation);
      case NavigationDestinationLabelBehavior.onlyShowSelected:
        return _CurvedAnimationBuilder(
          animation: info.selectedAnimation,
          curve: Curves.easeInOutCubicEmphasized,
          reverseCurve: Curves.easeInOutCubicEmphasized.flipped,
          builder: builder,
        );
    }
  }
}

class _NavigationBarDestinationTooltip extends StatelessWidget {
  const _NavigationBarDestinationTooltip({
    required this.message,
    required this.child,
  });

  final String message;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      verticalOffset: 34,
      excludeFromSemantics: true,
      preferBelow: false,
      child: child,
    );
  }
}

class _NavigationDestinationLayoutDelegate extends MultiChildLayoutDelegate {
  _NavigationDestinationLayoutDelegate({required this.animation})
    : super(relayout: animation);

  final Animation<double> animation;

  static const int iconId = 1;

  static const int labelId = 2;

  @override
  void performLayout(Size size) {
    double halfWidth(Size size) => size.width / 2;
    double halfHeight(Size size) => size.height / 2;

    final Size iconSize = layoutChild(iconId, BoxConstraints.loose(size));
    final Size labelSize = layoutChild(labelId, BoxConstraints.loose(size));

    final double yPositionOffset = Tween<double>(
      begin: halfHeight(iconSize),
      end: halfHeight(iconSize) + halfHeight(labelSize),
    ).transform(animation.value);
    final double iconYPosition = halfHeight(size) - yPositionOffset;

    positionChild(
      iconId,
      Offset(
        halfWidth(size) - halfWidth(iconSize),
        iconYPosition,
      ),
    );

    positionChild(
      labelId,
      Offset(
        halfWidth(size) - halfWidth(labelSize),
        iconYPosition + iconSize.height,
      ),
    );
  }

  @override
  bool shouldRelayout(_NavigationDestinationLayoutDelegate oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _SelectableAnimatedBuilder extends StatefulWidget {
  const _SelectableAnimatedBuilder({
    required this.isSelected,
    this.duration = const Duration(milliseconds: 200),
    this.alwaysDoFullAnimation = false,
    required this.builder,
  });

  final bool isSelected;

  final Duration duration;

  final bool alwaysDoFullAnimation;

  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  _SelectableAnimatedBuilderState createState() =>
      _SelectableAnimatedBuilderState();
}

class _SelectableAnimatedBuilderState extends State<_SelectableAnimatedBuilder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.duration = widget.duration;
    _controller.value = widget.isSelected ? 1.0 : 0.0;
  }

  @override
  void didUpdateWidget(_SelectableAnimatedBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.isSelected != widget.isSelected) {
      if (widget.isSelected) {
        _controller.forward(from: widget.alwaysDoFullAnimation ? 0 : null);
      } else {
        _controller.reverse(from: widget.alwaysDoFullAnimation ? 1 : null);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _controller);
  }
}

class _CurvedAnimationBuilder extends StatefulWidget {
  const _CurvedAnimationBuilder({
    required this.animation,
    required this.curve,
    required this.reverseCurve,
    required this.builder,
  });

  final Animation<double> animation;
  final Curve curve;
  final Curve reverseCurve;
  final Widget Function(BuildContext, Animation<double>) builder;

  @override
  _CurvedAnimationBuilderState createState() => _CurvedAnimationBuilderState();
}

class _CurvedAnimationBuilderState extends State<_CurvedAnimationBuilder> {
  late AnimationStatus _animationDirection;
  AnimationStatus? _preservedDirection;

  @override
  void initState() {
    super.initState();
    _animationDirection = widget.animation.status;
    _updateStatus(widget.animation.status);
    widget.animation.addStatusListener(_updateStatus);
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_updateStatus);
    super.dispose();
  }

  void _updateStatus(AnimationStatus status) {
    if (_animationDirection != status) {
      setState(() {
        _animationDirection = status;
      });
    }
    switch (status) {
      case AnimationStatus.forward || AnimationStatus.reverse
          when _preservedDirection != null:
        break;
      case AnimationStatus.forward || AnimationStatus.reverse:
        setState(() {
          _preservedDirection = status;
        });
      case AnimationStatus.completed || AnimationStatus.dismissed:
        setState(() {
          _preservedDirection = null;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldUseForwardCurve =
        (_preservedDirection ?? _animationDirection) != AnimationStatus.reverse;

    final Animation<double> curvedAnimation = CurveTween(
      curve: shouldUseForwardCurve ? widget.curve : widget.reverseCurve,
    ).animate(widget.animation);

    return widget.builder(context, curvedAnimation);
  }
}

class _NavigationBarDefaultsM3 extends NavigationBarThemeData {
  _NavigationBarDefaultsM3(this.context)
    : super(
        height: _kNavigationHeight,
        elevation: 3.0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      );

  final BuildContext context;
  late final _colors = Theme.of(context).colorScheme;
  late final _textTheme = Theme.of(context).textTheme;

  BorderSide get borderSide => _colors.isDark
      ? const BorderSide(color: Color(0x18FFFFFF), width: 0.8)
      : const BorderSide(color: Color(0x12000000), width: 0.8);

  @override
  Color? get backgroundColor => _colors.surfaceContainer;

  @override
  Color? get shadowColor => Colors.transparent;

  @override
  Color? get surfaceTintColor => Colors.transparent;

  @override
  WidgetStateProperty<IconThemeData?>? get iconTheme {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      return IconThemeData(
        size: 22.0,
        color: states.contains(WidgetState.disabled)
            ? _colors.onSurfaceVariant.withValues(alpha: 0.38)
            : states.contains(WidgetState.selected)
            ? _colors.onSecondaryContainer
            : _colors.onSurfaceVariant,
      );
    });
  }

  @override
  Color? get indicatorColor => _colors.secondaryContainer;

  @override
  ShapeBorder? get indicatorShape => const StadiumBorder();

  @override
  WidgetStateProperty<TextStyle?>? get labelTextStyle {
    return WidgetStateProperty.resolveWith((Set<WidgetState> states) {
      final TextStyle style = _textTheme.labelMedium!;
      return style.copyWith(
        fontSize: 11.5,
        fontWeight: states.contains(WidgetState.selected)
            ? FontWeight.w600
            : FontWeight.w500,
        color: states.contains(WidgetState.disabled)
            ? _colors.onSurfaceVariant.withValues(alpha: 0.38)
            : states.contains(WidgetState.selected)
            ? _colors.onSecondaryContainer
            : _colors.onSurfaceVariant,
      );
    });
  }

  @override
  EdgeInsetsGeometry? get labelPadding => const EdgeInsets.only(top: 1);
}
