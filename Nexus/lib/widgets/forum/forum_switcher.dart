import 'package:flutter/material.dart';

class ForumSwitcher extends StatelessWidget {
  final bool showGroups;            // true => "Grupos" selecionado; false => "Timeline" selecionado
  final ValueChanged<bool> onChanged;

  const ForumSwitcher({
    super.key,
    required this.showGroups,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalW = constraints.maxWidth;
        final pillW = totalW / 2;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 33,
            width: 380,
            child: Stack(
              children: [
              // trilho
              Container(
                width: totalW,
                height: 33,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F4968),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),

              // pílula deslizante
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                alignment: showGroups ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: pillW,
                  height: 33,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFFA259FF), Color(0xFF8447D6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              // rótulos + áreas clicáveis
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onChanged(false), // Timeline
                        child: Center(
                          child: Text(
                            'Timeline',
                            style: TextStyle(
                              color: showGroups ? Colors.white : const Color(0xFF202634),
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                              letterSpacing: 0.16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onChanged(true), // Grupos
                        child: Center(
                          child: Text(
                            'Grupos',
                            style: TextStyle(
                              color: showGroups ? const Color(0xFF202634) : Colors.white,
                              fontSize: 16,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                              letterSpacing: 0.16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}