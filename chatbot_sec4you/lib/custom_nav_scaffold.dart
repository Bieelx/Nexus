import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class CustomNavScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Widget body;

  const CustomNavScaffold({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.body,
  }) : super(key: key);

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: body,
      bottomNavigationBar: BottomAppBar(
        color: Colors.transparent,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home,
                color: currentIndex == 0
                    ? AppTheme.primaryColor
                    : AppTheme.textColor,
              ),
              onPressed: () => onTap(0),
            ),
            IconButton(
              icon: Icon(Icons.book,
                color: currentIndex == 1
                    ? AppTheme.primaryColor
                    : AppTheme.textColor,
              ),
              onPressed: () => onTap(1),
            ),
            const SizedBox(width: 48), // espaço pro FAB
            IconButton(
              icon: Icon(Icons.security,
                color: currentIndex == 3
                    ? AppTheme.primaryColor
                    : AppTheme.textColor,
              ),
              onPressed: () => onTap(3),
            ),
            IconButton(
              icon: Icon(Icons.person,
                color: currentIndex == 4
                    ? AppTheme.primaryColor
                    : AppTheme.textColor,
              ),
              onPressed: () => onTap(4),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: currentIndex == 2
                ? AppTheme.primaryColor
                : AppTheme.boxColor,
            width: 4,
          ),
        ),
        child: FloatingActionButton(
          onPressed: () => onTap(2),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Image.asset('assets/luizinho.png', width: 60, height: 60),
        ),
      ),
    );
  }
}
