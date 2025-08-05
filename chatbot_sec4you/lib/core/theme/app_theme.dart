import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundColor = Color.fromRGBO(36, 37, 38, 100);
  static const Color boxColor = Color(0xFF393939);
  static const Color primaryColor    = Color(0xFFA259FF);
  static const Color textColor       = Color(0xFFFAF9F6);

  static ThemeData darkTheme() {
    // Base do tema escuro
    final base = ThemeData.dark();

    // Nosso ColorScheme
    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      onPrimary: textColor,
      background: backgroundColor,
      surface: boxColor,
      onSurface: textColor,
    );

    // Aplica JetBrainsMono no TextTheme e no PrimaryTextTheme
    final textTheme = base.textTheme.apply(
      fontFamily: 'JetBrainsMono',
      bodyColor: textColor,
      displayColor: textColor,
    );
    final primaryTextTheme = base.primaryTextTheme.apply(
      fontFamily: 'JetBrainsMono',
      bodyColor: textColor,
      displayColor: textColor,
    );

    return base.copyWith(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,

      // Componentes
      cardTheme: CardTheme(color: boxColor),
      dialogTheme: DialogTheme(backgroundColor: boxColor),
      appBarTheme: AppBarTheme(
        backgroundColor: boxColor,
        foregroundColor: textColor,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: boxColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: textColor.withOpacity(0.6),
        ),
      ),
    );
  }
}
