import 'package:flutter/material.dart';
import 'app_theme.dart';

class LeakStyles {
  // Cores
  static Color background = AppTheme.backgroundColor;
  static Color box = AppTheme.boxColor;
  static Color primary = AppTheme.primaryColor;
  static Color text = AppTheme.textColor;

  // Espaçamentos
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 16);
  static const EdgeInsets titlePadding = EdgeInsets.only(bottom: 40);
  static const EdgeInsets containerPadding = EdgeInsets.all(20);
  static const EdgeInsets labelPadding = EdgeInsets.only(bottom: 10);
  static const EdgeInsets fieldSpacing = EdgeInsets.only(top: 15);
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 32, vertical: 15);
  static const EdgeInsets resultPadding = EdgeInsets.only(top: 20);

  // Bordas e decorações
  static final BorderRadius containerRadius = BorderRadius.circular(20);
  static final BorderRadius fieldRadius = BorderRadius.circular(10);
  static final BorderRadius buttonRadius = BorderRadius.circular(30);

  static InputDecoration fieldDecoration({required Icon icon, required String hint}) =>
      InputDecoration(
        filled: true,
        fillColor: background,
        prefixIcon: icon,
        hintText: hint,
        hintStyle: TextStyle(color: primary),
        border: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide.none,
        ),
      );

  static TextStyle dropdownTextStyle = TextStyle(
    fontFamily: 'JetBrainsMono',
    color: primary,
    fontSize: 16,
  );

  static InputDecoration dropdownDecoration = InputDecoration(
    filled: true,
    fillColor: background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
    border: OutlineInputBorder(
      borderRadius: fieldRadius,
      borderSide: BorderSide.none,
    ),
  );

  static ButtonStyle gradientButtonStyle = ButtonStyle(
    padding: MaterialStateProperty.all(buttonPadding),
    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: buttonRadius)),
    backgroundColor: MaterialStateProperty.all(Colors.transparent),
    shadowColor: MaterialStateProperty.all(Colors.transparent),
  );

  // Texto
  static TextStyle titleText = TextStyle(color: primary, fontSize: 22, fontWeight: FontWeight.bold);
  static TextStyle labelText = TextStyle(color: primary, fontSize: 16);
  static TextStyle buttonText = TextStyle(color: text, fontSize: 18);
  static TextStyle resultText = TextStyle(color: primary, fontSize: 16, fontWeight: FontWeight.bold);

  // Loader
  static const double loaderSize = 20;
  static const double loaderStrokeWidth = 2;
}
