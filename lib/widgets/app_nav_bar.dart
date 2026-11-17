import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const AppNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.lightGrey)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: AppTheme.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        iconSize: 28,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Feed',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Publicar'),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            label: 'Acessos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
