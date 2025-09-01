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
    const Color barColor = Color(0xFF434958);       // fundo dos pills e círculo central
    const Color iconUnselected = Color(0xFFDEE1E7);
    const Color highlightColor = Color(0xFF6C7691); // fundo circular quando selecionado
    const Color iconSelected = Color(0xFF202634);

    const double navBarHeight = 56.0; // igual ao mock
    const double sidePadding = 16.0;

    const items = <IconData>[
      Icons.home,
      Icons.menu_book_rounded,
      Icons.shield_outlined,
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
              // Centro sempre do diâmetro/altura da barra
              const double centerDiameter = navBarHeight; // 56
              // Figma: cada pill 125 em um container de 314 (125 + 56 + 125)
              // Para responsividade, se houver mais ou menos espaço, distribuímos
              // proporcionalmente mantendo o círculo central com 56 de diâmetro.
              final double segmentWidth = (totalWidth - centerDiameter) / 2.0;

              // Bridging connectors between the side pills and the center circle
              final double connectorWidth = 24.0;
              final double connectorHeight = navBarHeight * 0.64; // a bit thinner than the bar
              final double connectorTop = (navBarHeight - connectorHeight) / 2;

              return Stack(
                children: [
                  // ====== BACKGROUND: dois pills e o círculo central ======
                  Positioned(
                    left: 0,
                    top: 0,
                    width: segmentWidth,
                    height: navBarHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  // Conectores que ligam visualmente os pills ao círculo central
                  Positioned(
                    left: segmentWidth - (connectorWidth / 2),
                    top: connectorTop,
                    width: connectorWidth,
                    height: connectorHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Positioned(
                    left: segmentWidth + centerDiameter - (connectorWidth / 2),
                    top: connectorTop,
                    width: connectorWidth,
                    height: connectorHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  Positioned(
                    left: segmentWidth + centerDiameter,
                    top: 0,
                    width: segmentWidth,
                    height: navBarHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  // Círculo central (botão do Chatbot)
                  Positioned(
                    left: segmentWidth,
                    top: 0,
                    width: centerDiameter,
                    height: centerDiameter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(2),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: barColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // disco interno 44x44 mais escuro (como no mock)
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF202634),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Foto da Lua recortada
                            SizedBox(
                              width: 44,
                              height: 44,
                              child: ClipOval(child: _LuaAsset()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ====== FOREGROUND (ícones) ======
                  Positioned.fill(
                    child: Row(
                      children: [
                        // Lado esquerdo (ícones 0,1)
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
                                size: 44,
                              ),
                              _NavIcon(
                                icon: items[1],
                                selected: currentIndex == 1,
                                onTap: () => onTap(1),
                                highlightColor: highlightColor,
                                iconSelected: iconSelected,
                                iconUnselected: iconUnselected,
                                size: 44,
                              ),
                            ],
                          ),
                        ),

                        // Espaço central (círculo já foi pintado acima)
                        const SizedBox(width: centerDiameter, height: navBarHeight),

                        // Lado direito (ícones 2,3)
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
                                size: 44,
                              ),
                              _NavIcon(
                                icon: items[3],
                                selected: currentIndex == 3,
                                onTap: () => onTap(3),
                                highlightColor: highlightColor,
                                iconSelected: iconSelected,
                                iconUnselected: iconUnselected,
                                size: 44,
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

class _LuaAsset extends StatelessWidget {
  const _LuaAsset();

  @override
  Widget build(BuildContext context) {
    // Tenta carregar primeiro no caminho novo; se falhar, usa o antigo.
    return Image.asset(
      'assets/Lua/Lua.png',
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Image.asset(
          'assets-lua-lua.png',
          fit: BoxFit.cover,
        );
      },
    );
  }
}