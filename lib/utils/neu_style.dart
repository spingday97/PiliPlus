import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';

abstract final class NeuStyle {
  static bool get enabled => Pref.iosStyleUi;

  static Color canvasColor(bool isDark) =>
    isDark ? const Color(0xFF1D2129) : const Color(0xFFE4EAF1);

  static Color grooveColor(bool isDark) =>
      isDark ? const Color(0xFF151820) : const Color(0xFFD8E0EA);

  static BoxDecoration raised({
    required bool isDark,
    double radius = 16,
    Color? color,
    double blur = 13,
    double offset = 5.5,
  }) {
    return BoxDecoration(
      color: color ?? canvasColor(isDark),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? const Color(0xFF2D3442)
              : Colors.white,
          offset: Offset(-offset, -offset),
          blurRadius: blur,
        ),
        BoxShadow(
          color: isDark
              ? const Color(0xFF0D0F14).withValues(alpha: 0.90)
              : const Color(0xFF9AA8BE).withValues(alpha: 0.60),
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
