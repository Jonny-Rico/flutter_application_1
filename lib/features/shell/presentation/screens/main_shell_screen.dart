import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            key: ValueKey('nav-tasks'),
            icon: Icon(Icons.checklist_rounded),
            selectedIcon: Icon(Icons.checklist_rtl_rounded),
            label: 'Tasks',
          ),
          NavigationDestination(
            key: ValueKey('nav-shop'),
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart_rounded),
            label: 'Shop',
          ),
          NavigationDestination(
            key: ValueKey('nav-family'),
            icon: Icon(Icons.family_restroom_outlined),
            selectedIcon: Icon(Icons.family_restroom),
            label: 'Family',
          ),
          NavigationDestination(
            key: ValueKey('nav-dashboard'),
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Dash',
          ),
          NavigationDestination(
            key: ValueKey('nav-notes'),
            icon: Icon(Icons.notes_outlined),
            selectedIcon: Icon(Icons.notes_rounded),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}