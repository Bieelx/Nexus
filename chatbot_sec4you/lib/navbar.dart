import 'package:flutter/material.dart';

/// Barra inferior com dois "pills" laterais conectados por um círculo central.
/// Ícones sem rótulo; o ícone selecionado recebe um destaque circular.
/// Mantém a mesma API de antes:
///   CustomNavBar(currentIndex: _index, onTap: _onTap)
class CustomNavBar extends StatelessWidget {
  final int currentIndex; // 0..3
  final ValueChanged<int> onTap;

  const CustomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Paleta
    const Color barColor = Color(0xFF434958); // fundo dos pills e círculo central
    const Color iconUnselected = Color(0xFFDEE1E7);
    const Color highlightColor = Color(0xFF6C7691); // círculo de seleção
    const Color iconSelected = Color(0xFF202634);
    const double bridgeWidth = 28.0, bridgeHeight = 20.0; // “ponte” estreita entre os pills e o círculo

    const double navBarHeight = 56.0; // mesma referência do seu mock
    const double sidePadding = 16.0;
    const double highlightSize = 44.0; // diâmetro do círculo de seleção

    const items = <IconData>[
      Icons.home,
      Icons.menu_book_rounded,
      Icons.shield_outlined, // ajuste se quiser usar outro ícone (ex.: incognito)
      Icons.person_outline,
    ];

    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: sidePadding),
        child: SizedBox(
          height: navBarHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              final double centerDiameter = navBarHeight; // círculo central
              final double segmentWidth = (totalWidth - centerDiameter) / 2;

              return Stack(
                children: [
                  // ====== BACKGROUND ======
                  // Left pill
                  Positioned(
                    left: 0,
                    top: 0,
                    width: segmentWidth,
                    height: navBarHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(navBarHeight / 2),
                      ),
                    ),
                  ),
                  // Right pill
                  Positioned(
                    left: segmentWidth + centerDiameter,
                    top: 0,
                    width: segmentWidth,
                    height: navBarHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(navBarHeight / 2),
                      ),
                    ),
                  ),
                  // Center circle connector
                  Positioned(
                    left: segmentWidth,
                    top: 0,
                    width: centerDiameter,
                    height: navBarHeight,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: barColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Bridges para conectar visualmente os blocos (sem “buraco”)
                  Positioned(
                    left: segmentWidth - (bridgeWidth / 2),
                    top: (navBarHeight - bridgeHeight) / 2,
                    width: bridgeWidth,
                    height: bridgeHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(bridgeHeight / 2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: segmentWidth + centerDiameter - (bridgeWidth / 2),
                    top: (navBarHeight - bridgeHeight) / 2,
                    width: bridgeWidth,
                    height: bridgeHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(bridgeHeight / 2),
                      ),
                    ),
                  ),

                  // ====== FOREGROUND (ícones + toques) ======
                  // Área clicável/flex de ícones
                  Positioned.fill(
                    child: Row(
                      children: [
                        // Left segment -> dois itens: 0,1
                        SizedBox(
                          width: segmentWidth,
                          height: navBarHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _NavIcon(
                                icon: items[0],
                                selected: currentIndex == 0,
                                onTap: () => onTap(0),
                                highlightColor: highlightColor,
                                iconSelected: iconSelected,
                                iconUnselected: iconUnselected,
                                size: highlightSize,
                              ),
                              _NavIcon(
                                icon: items[1],
                                selected: currentIndex == 1,
                                onTap: () => onTap(1),
                                highlightColor: highlightColor,
                                iconSelected: iconSelected,
                                iconUnselected: iconUnselected,
                                size: highlightSize,
                              ),
                            ],
                          ),
                        ),

                        // Center spacer (não clicável)
                        SizedBox(width: centerDiameter, height: navBarHeight),

                        // Right segment -> dois itens: 2,3
                        SizedBox(
                          width: segmentWidth,
                          height: navBarHeight,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _NavIcon(
                                icon: items[2],
                                selected: currentIndex == 2,
                                onTap: () => onTap(2),
                                highlightColor: highlightColor,
                                iconSelected: iconSelected,
                                iconUnselected: iconUnselected,
                                size: highlightSize,
                              ),
                              _NavIcon(
                                icon: items[3],
                                selected: currentIndex == 3,
                                onTap: () => onTap(3),
                                highlightColor: highlightColor,
                                iconSelected: iconSelected,
                                iconUnselected: iconUnselected,
                                size: highlightSize,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color highlightColor;
  final Color iconSelected;
  final Color iconUnselected;
  final double size;

  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.highlightColor,
    required this.iconSelected,
    required this.iconUnselected,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: selected ? highlightColor : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: selected ? iconSelected : iconUnselected,
        ),
      ),
    );
  }
}