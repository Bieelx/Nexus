import 'package:flutter/material.dart';

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
    const double navBarHeight = 60.0;
    const Color barColor = Color(0xFF434958);
    const Color pillColor = Color(0xFF6B7691);

    final items = <_NavItem>[
      _NavItem(Icons.home, 'Home'),
      _NavItem(Icons.menu_book_rounded, 'Cursos'),
      _NavItem(Icons.privacy_tip_outlined, 'Vazamentos'),
      _NavItem(Icons.group_outlined, 'Fórum'), // <-- ÍCONE ALTERADO AQUI
    ];

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: navBarHeight,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(navBarHeight / 2),
                ),
                child: Row(
                  // Distribui os itens, permitindo que o selecionado ocupe mais espaço
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                  children: List.generate(items.length, (index) {
                    return _NavBarItem(
                      item: items[index],
                      isSelected: index == currentIndex,
                      pillColor: pillColor,
                      onTap: () => onTap(index),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _AiButton(
              isSelected: currentIndex == 4,
              onTap: () => onTap(4),
              size: navBarHeight,
              pillColor: pillColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final Color pillColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.pillColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color iconSelectedColor = Color(0xFF202634);
    const Color iconUnselectedColor = Color(0xFFDEE1E7);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        height: 48, // Altura fixa para a pílula interna
        // Ajusta o padding horizontal para permitir o texto
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 20.0 : 12.0), 
        decoration: BoxDecoration(
          color: isSelected ? pillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Importante: permite o Row se ajustar ao conteúdo
          children: [
            Icon(item.icon, size: 24, color: isSelected ? iconSelectedColor : iconUnselectedColor),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12, // Tamanho de fonte ajustado para evitar overflow
                          fontWeight: FontWeight.w700,
                          color: iconSelectedColor,
                        ),
                      ),
                    )
                  : const SizedBox(width: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final double size;
  final Color pillColor;

  const _AiButton({
    required this.isSelected,
    required this.onTap,
    required this.size,
    required this.pillColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isSelected ? pillColor : const Color(0xFF434958),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: Color(0xFFDEE1E7),
          size: 30,
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}