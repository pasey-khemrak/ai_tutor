import 'package:flutter/material.dart';

/// Supported device form factors across the ReanAI visual tutor.
enum DeviceFormFactor {
  /// Handheld mobile devices (~390–430pt wide).
  phone,

  /// Tablets in portrait or landscape (~768–1279pt wide).
  tablet,

  /// Desktop monitors or wide web displays (1280pt+ wide).
  desktop,
}

/// Single source of truth for responsive breakpoints, content constraints,
/// and touch targets across the entire ReanAI client.
abstract final class AppBreakpoints {
  /// Upper bound for phone form factor width.
  static const double phoneMax = 767.0;

  /// Lower bound for tablet form factor width.
  static const double tabletMin = 768.0;

  /// Upper bound for tablet form factor width.
  static const double tabletMax = 1279.0;

  /// Lower bound for desktop form factor width.
  static const double desktopMin = 1280.0;

  /// Maximum content width on desktop to prevent lines from running 200+ characters.
  static const double maxContentWidthDesktop = 1440.0;

  /// Reading content max width for text-heavy sections.
  static const double maxReadingWidth = 760.0;

  /// Side panel width for tablet 2-column layout.
  static const double sidePanelWidthTablet = 340.0;

  /// Side panel width for desktop 2-column layout.
  static const double sidePanelWidthDesktop = 400.0;

  /// Minimum touch target dimension according to Apple HIG and Material guidelines.
  static const double minTouchTarget = 44.0;

  /// Minimum BoxConstraints satisfying minTouchTarget.
  static const BoxConstraints touchTargetConstraints = BoxConstraints(
    minWidth: minTouchTarget,
    minHeight: minTouchTarget,
  );

  /// Determine the form factor for a given pixel width.
  static DeviceFormFactor getFormFactor(double width) {
    if (width < tabletMin) return DeviceFormFactor.phone;
    if (width < desktopMin) return DeviceFormFactor.tablet;
    return DeviceFormFactor.desktop;
  }

  /// Convenience query from BuildContext.
  static DeviceFormFactor of(BuildContext context) {
    return getFormFactor(MediaQuery.sizeOf(context).width);
  }

  /// True if current device width corresponds to phone (< 768).
  static bool isPhone(BuildContext context) =>
      of(context) == DeviceFormFactor.phone;

  /// True if current device width corresponds to tablet (768..1279).
  static bool isTablet(BuildContext context) =>
      of(context) == DeviceFormFactor.tablet;

  /// True if current device width corresponds to desktop (>= 1280).
  static bool isDesktop(BuildContext context) =>
      of(context) == DeviceFormFactor.desktop;

  /// True if width corresponds to tablet or desktop (>= 768).
  static bool isWide(double width) => width >= tabletMin;

  /// True if width corresponds to phone (< 768).
  static bool isPhoneWidth(double width) => width < tabletMin;

  /// True if width corresponds to tablet (768..1279).
  static bool isTabletWidth(double width) =>
      width >= tabletMin && width < desktopMin;

  /// True if width corresponds to desktop (>= 1280).
  static bool isDesktopWidth(double width) => width >= desktopMin;
}
