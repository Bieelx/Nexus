import 'package:flutter/material.dart';
import 'app_theme.dart'; // importa as cores que você já definiu

class ChatStyles {
  static const Color background = AppTheme.backgroundColor; // #242526
  static const Color botBubble = AppTheme.boxColor;         // #393939
  static const Color userBubble = AppTheme.primaryColor;    // #A259FF
  static const Color userColor = AppTheme.primaryColor;     // mesmo do botão
  static const Color text = AppTheme.textColor;             // #FAF9F6
  static const Color hint = Colors.grey;
  static const Color inputFill = AppTheme.boxColor;

  static const TextStyle messageText = TextStyle(
    color: text,
    fontSize: 16,
    fontFamily: 'JetBrainsMono',
  );

  static const TextStyle titleStyle = TextStyle(
    color: text,
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'JetBrainsMono',
  );
}
