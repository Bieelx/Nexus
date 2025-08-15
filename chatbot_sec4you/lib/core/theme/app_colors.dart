import 'package:flutter/material.dart';

/// Central palette for the whole app.
/// Add new colors here and reference them via `AppColors.*`
/// so we keep styling consistent across screens.
class AppColors {
  // Base
  /// Solid color used as the app background.
  static const Color background = Color(0xFF1E1E1E); // Page background (solid)
  static const Color box = Color(0xFF393939);        // Cards/containers
  static const Color surfaceDark = Color(0xFF242526); // Dark chips / selected bg
  static const Color outline = Color(0xFF4A4A4A);     // Subtle borders/dividers

  // ---- Gradient Background (new app default) ----
  /// Gradient used as the app background.
  /// Usage:
  ///   Container(
  ///     decoration: AppColors.backgroundBox,
  ///     child: Scaffold(backgroundColor: Colors.transparent, ...),
  ///   )
  static const Color bgStart = Color(0xFF1B202E);
  static const Color bgEnd = Color(0xFF252C3A);

  // Alignment from Figma
  static const Alignment bgBegin = Alignment(0.54, 0.51);
  static const Alignment bgEndAlign = Alignment(-0.04, 0.95);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: bgBegin,
    end: bgEndAlign,
    colors: [bgStart, bgEnd],
  );

  /// Reusable BoxDecoration for the gradient background.
  static const BoxDecoration backgroundBox = BoxDecoration(
    gradient: backgroundGradient,
  );

  // Brand
  static const Color primaryPurple = Color(0xFFA259FF);
  static const Color white = Color(0xFFFAF9F6);

  // Chat specific
  static const Color chatUserBubble = Color(0xFF2B2B2B);
  static const Color chatBotBubble = Color(0xFFA259FF);
  static const Color chatTextOnUser = white;
  static const Color chatTextOnBot = Color(0xFFFFFFFF);

  // Inputs
  static const Color inputBg = box;
  static const Color inputHint = primaryPurple;
}