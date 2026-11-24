import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';

abstract final class NeuStyle {
  static bool get enabled => Pref.iosStyleUi;

  static Color canvasColor(bool isDark) =>
    isDark ? const Color(0xFF1E222A) : const Color(0xFFE9EEF4);

  static Color grooveColor(bool isDark) =>
      isDark ? const Color(0xFF171A21) : const Color(0xFFDDE3EC);

  static BoxDecoration raised({
    required bool isDark,
    double radius = 16,
    Color? color,
    double blur = 10,
    double offset = 4,
  }) {
    return BoxDecoration(
      color: color ?? canvasColor(isDark),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color(0xFF2B313D)
              : Colors.white.withValues(alpha: 0.90),
          offset: Offset(-offset, -offset),
          blurRadius: blur,
        ),
        BoxShadow(
          color: isDark
              ? const Color(0xFF101318).withValues(alpha: 0.85)
              : const Color(0xFFA3B1C6).withValues(alpha: 0.45),
          offset: Offset(offset, offset),
          blurRadius: blur,
        ),
      ],
    );
  }

  static BoxDecoration inset({
    required bool isDark,
    double radius = 14,
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? grooveColor(isDark),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.70),
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color(0xFF12151B).withValues(alpha: 0.70)
              : const Color(0xFFA3B1C6).withValues(alpha: 0.28),
          offset: const Offset(2, 2),
          blurRadius: 4,
        ),
      ],
    );
  }
}  
