import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment(0.54, 0.51),
    end: Alignment(-0.04, 0.95),
    colors: [Color(0xFF1B202E), Color(0xFF252C3A)],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: mainGradient),
      // Mantém o gradiente por trás de tudo
      child: child,
    );
  }
}