import 'package:flutter/material.dart';
import './core/theme/app_colors.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Responsivo: ajusta margens proporcionalmente
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width <= 440 ? 18.0 : width * 0.04;
    final bottomPadding = 46.84; // Ajuste se necessário para iOS/Android

    const selectedCircle = Color(0xFF242526);

    final icons = [
      Icons.home,
      Icons.menu_book_rounded,
      Icons.security,
      Icons.forum,
    ];
    final labels = ['Home', 'Cursos', 'Vazamentos', 'Fórum'];

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: bottomPadding,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // NavBar principal
          Expanded(
            child: Container(
              height: 56.16,
              decoration: BoxDecoration(
                color: AppColors.box.withOpacity(0.7),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(icons.length, (i) {
                  final selected = currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      child: Container(
                        height: 56.16,
                        decoration: selected
                            ? BoxDecoration(
                                color: selectedCircle,
                                borderRadius: BorderRadius.circular(28),
                              )
                            : null,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icons[i],
                              color: selected ? AppColors.primaryPurple : AppColors.white,
                              size: 28,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              labels[i],
                              style: TextStyle(
                                fontSize: 12,
                                color: selected ? AppColors.primaryPurple : AppColors.white,
                                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                fontFamily: 'JetBrainsMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          // Espaço entre NavBar e "Luizinho"
          const SizedBox(width: 38.84),
          // "Luizinho" botão: use a imagem real se quiser
          GestureDetector(
            onTap: () => onTap(4),
            child: Container(
              width: 56.16,
              height: 56.16,
              decoration: BoxDecoration(
                color: currentIndex == 4 ? AppColors.background : AppColors.box,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child:
                    Icon(
                      Icons.person,
                      size: 32,
                      color: currentIndex == 4 ? AppColors.primaryPurple : AppColors.white,
                    ),
                // Exemplo para imagem:
                // Image.asset(
                //   'assets/luizinho.png',
                //   width: 36,
                //   height: 36,
                // ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}