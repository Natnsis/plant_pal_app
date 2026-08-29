import 'package:flutter/material.dart';

/// Design tokens lifted straight from the PlantPal design canvas.
class PP {
  PP._();

  // Core palette
  static const ink = Color(0xFF16180F);
  static const bone = Color(0xFFEEF0E6); // screen background
  static const forest = Color(0xFF2F5D33); // primary green
  static const forestMid = Color(0xFF3C7340);
  static const forestLight = Color(0xFF4F8A4A);
  static const lime = Color(0xFF86E86A); // accent
  static const limeDim = Color(0xFF75DC58); // accent pressed
  static const sage = Color(0xFFA3B790); // canvas base
  static const sageTop = Color(0xFFB3C6A0);
  static const sageBottom = Color(0xFF93A87E);

  // Greens / surfaces
  static const pale1 = Color(0xFFE4EBD7);
  static const pale2 = Color(0xFFDCEBCD);
  static const pale3 = Color(0xFFDDE3D0);
  static const pale4 = Color(0xFFE1E7D5);
  static const field = Color(0xFFF2F4EA);
  static const card = Color(0xFFFFFFFF);
  static const doneCard = Color(0xFFE6EBDA);

  // Semantic
  static const amberBg = Color(0xFFF0D9A8);
  static const amberFg = Color(0xFF7A5211);
  static const danger = Color(0xFFB4482F);
  static const mint = Color(0xFFDFF3C8);

  // Image placeholder gradient
  static const imgGradA = Color(0xFFE3E9D6);
  static const imgGradB = Color(0xFFC6D9AC);

  static const canvasGradient = LinearGradient(
    begin: Alignment(-0.6, -1),
    end: Alignment(0.6, 1),
    colors: [sageTop, sage, sageBottom],
    stops: [0.0, 0.45, 1.0],
  );

  static const plantImage = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [imgGradA, imgGradB],
  );

  static Color inkA(double o) => ink.withValues(alpha: o);
  static Color boneA(double o) => bone.withValues(alpha: o);

  /// Tight tracking used on display headings (~ -0.04em).
  static double track(double fontSize, [double em = -0.04]) => fontSize * em;
}

ThemeData buildPlantPalTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    scaffoldBackgroundColor: PP.bone,
    colorScheme: ColorScheme.fromSeed(
      seedColor: PP.forest,
      primary: PP.forest,
      surface: PP.bone,
      brightness: Brightness.light,
    ),
    splashFactory: InkRipple.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: PP.ink,
      displayColor: PP.ink,
      fontFamily: 'Outfit',
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: PP.forest,
      selectionColor: Color(0x3386E86A),
      selectionHandleColor: PP.forest,
    ),
  );
}
