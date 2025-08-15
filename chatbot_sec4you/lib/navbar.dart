import 'package:flutter/material.dart';

/// Barra inferior personalizada com "pílula" expansível no item selecionado
/// e botão circular do Luizinho ao lado direito.
/// Use assim:
/// CustomNavBar(currentIndex: _selectedIndex, onTap: _onTabTapped)
class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Cores (novo esquema)
    const Color barColor = Color(0xFF434958); // fundo da barra
    const Color pillColor = Color(0xFF6B7691); // fundo da pílula
    const Color iconSelected = Color(0xFF202634); // ícone/label selecionados
    const Color iconUnselected = Color(0xFFDEE1E7); // ícones não selecionados

    const double navBarHeight = 56.16;
    const double horizontalPadding = 16; // espaço lateral
    const double verticalGap = 5; // “respiro” top/bottom quando selecionado

    // Largura “base” do Figma para escalar a largura da pílula
    const double baseNavWidth = 281;
    const double basePillWidth = 108;

    // Reservamos ~72px para o “Luizinho” ao lado
    final double availableNavWidth =
        MediaQuery.of(context).size.width - (horizontalPadding * 2) - 72;

    final double scale = (availableNavWidth / baseNavWidth).clamp(0.75, 1.25);
    final double pillWidth = basePillWidth * scale; // usado para padding mínimo
    final double pillHeight = navBarHeight - (verticalGap * 2);

    const items = <_NavItem>[
      _NavItem(Icons.home, 'Home'),
      _NavItem(Icons.menu_book_rounded, 'Cursos'),
      _NavItem(Icons.shield_outlined, 'Vazamentos'),
      _NavItem(Icons.person_outline, 'Perfil'),
    ];

    return SafeArea(
      bottom: true,
      minimum: const EdgeInsets.only(bottom: 12), // evita encostar no rodapé
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // ------- Barra principal -------
            Expanded(
              child: Container(
                height: navBarHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(navBarHeight / 2),
                ),
                child: Row(
                  children: List.generate(items.length, (i) {
                    final bool selected = i == currentIndex;

                    // Usa flex maior no selecionado para “empurrar” os vizinhos
                    final int flex = selected ? 4 : 2;

                    return Expanded(
                      flex: flex,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          margin: EdgeInsets.symmetric(
                            vertical: selected ? verticalGap : 0,
                            horizontal: 6,
                          ),
                          height: selected ? pillHeight : navBarHeight,
                          decoration: selected
                              ? BoxDecoration(
                                  color: pillColor,
                                  borderRadius:
                                      BorderRadius.circular(navBarHeight / 2),
                                )
                              : const BoxDecoration(),
                          constraints: BoxConstraints(
                            minWidth: selected ? pillWidth : 0, // evita a “sumida” do label
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: selected ? 12 : 0,
                          ),
                          child: Row(
                            mainAxisAlignment: selected
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              Icon(
                                items[i].icon,
                                size: 24,
                                color: selected ? iconSelected : iconUnselected,
                              ),
                              if (selected) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    items[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                      color: iconSelected,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Espaço entre a barra e o botão do "Luizinho"
            const SizedBox(width: 12),

            // ------- Botão "Luizinho" -------
            GestureDetector(
              onTap: () => onTap(4), // índice reservado para o chat/IA
              child: Container(
                width: navBarHeight,
                height: navBarHeight,
                decoration: BoxDecoration(
                  color: currentIndex == 4 ? pillColor : barColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/luizinho.png', // garanta que está declarado no pubspec.yaml
                      width: navBarHeight * 0.66,
                      height: navBarHeight * 0.66,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Item da barra (ícone + label).
class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}