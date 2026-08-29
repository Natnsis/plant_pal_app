import 'package:flutter/material.dart';

/// PlantPal Design System Tokens — redesigned for fresh green/lime palette on white
class AppColors {
  AppColors._();

  // Backgrounds
  static const background = Color(0xFFFFFFFF);
  static const backgroundSecondary = Color(0xFFF8F9F6);

  // Text
  static const textPrimary = Color(0xFF1A1A1A);
  static const textDarkGreen = Color(0xFF1B4D3E);
  static const textMuted = Color(0xFF8E8E8E);
  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnLime = Color(0xFF1B4D3E);

  // Accent palette
  static const accentGreen = Color(0xFF4CAF64);
  static const accentLime = Color(0xFFA8E600);
  static const accentLimeDark = Color(0xFF8FC600);

  // Status / semantic
  static const redAlert = Color(0xFFE53935);
  static const redBadge = Color(0xFFE53935);
  static const amberWarning = Color(0xFFFFA726);

  // Card pastel fills for Timely Care stack
  static const cardSage = Color(0xFFD4E4D4);
  static const cardCharcoal = Color(0xFF1E1E1E);
  static const cardLimeYellow = Color(0xFFE8F56E);
  static const cardWarmOrange = Color(0xFFFFD8A8);
  static const cardCoolBlue = Color(0xFFD0E8F8);

  // Overlays / tints for plant thumbnails
  static const overlayWarmOrange = Color(0xCCFF8C42);
  static const overlayNeutral = Color(0x88000000);
  static const overlayCoolGreen = Color(0x884CAF64);

  // Navigation
  static const navBarBg = Color(0xFFF2F2F2);
  static const navActiveBg = Color(0xFF1B4D3E);
  static const navInactiveIcon = Color(0xFF9E9E9E);

  // Shadows
  static const cardShadow = Color(0x14000000);
  static const cardShadowStrong = Color(0x1F000000);
  static const navShadow = Color(0x1A000000);

  // Borders
  static const borderLight = Color(0x1A000000);
}

class AppRadius {
  AppRadius._();

  static const small = Radius.circular(12);
  static const medium = Radius.circular(20);
  static const card = Radius.circular(24);
  static const cardLarge = Radius.circular(28);
  static const pill = Radius.circular(999);
  static const circle = Radius.circular(999);
  static const phoneFrame = Radius.circular(36);
}

class AppShadows {
  AppShadows._();

  static const card = [
    BoxShadow(
      color: AppColors.cardShadow,
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  static const cardStrong = [
    BoxShadow(
      color: AppColors.cardShadowStrong,
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
  static const navBar = [
    BoxShadow(
      color: AppColors.navShadow,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
  static const phoneFrame = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 40,
      offset: Offset(0, 20),
      spreadRadius: -10,
    ),
  ];
}

class AppDimensions {
  AppDimensions._();

  static const double logoSize = 96;
  static const double heroAspectRatio = 4 / 3;
  static const double slideHorizontalPadding = 32;

  // New home screen dimensions
  static const double horizontalPadding = 20;
  static const double sectionSpacing = 28;
  static const double cardSpacing = 16;
  static const double statCardHeight = 100;
  static const double plantThumbSize = 88;
  static const double navBarHeight = 72;
  static const double phoneFrameHorizontalMargin = 16;
  static const double phoneFrameVerticalMargin = 24;
  static const double phoneFrameTopPadding = 8;
}
