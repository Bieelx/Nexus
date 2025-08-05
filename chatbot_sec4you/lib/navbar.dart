import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedFontSize: 0,
        unselectedFontSize: 0,
        type: BottomNavigationBarType.fixed,
        iconSize: 36,
        currentIndex: currentIndex,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home,
                color: currentIndex == 0
                    ? colorScheme.primary
                    : colorScheme.onSurface),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book,
                color: currentIndex == 1
                    ? colorScheme.primary
                    : colorScheme.onSurface),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: colorScheme.background,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentIndex == 2
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: 4,
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    '../assets/luizinho.png',
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
            ),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.security,
                color: currentIndex == 3
                    ? colorScheme.primary
                    : colorScheme.onSurface),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person,
                color: currentIndex == 4
                    ? colorScheme.primary
                    : colorScheme.onSurface),
            label: '',
          ),
        ],
      ),
    );
  }
}
