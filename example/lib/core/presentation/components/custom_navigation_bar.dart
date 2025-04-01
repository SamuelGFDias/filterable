import 'dart:ui';

import 'package:flutter/material.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;

  const CustomNavigationBar({super.key, required this.selectedIndex});

  BoxDecoration _navigationBarDecoration() => BoxDecoration(
        color: Colors.black54,
        border: const Border(
          top: BorderSide(color: Colors.white24),
        ),
      );

  Widget _buildNavigationBar() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          decoration: _navigationBarDecoration(),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: selectedIndex,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Buscar',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildNavigationBar();
  }
}
