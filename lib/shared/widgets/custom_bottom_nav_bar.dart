import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          height: 78,
          backgroundColor: const Color(0xFF0A1746),
          indicatorColor: const Color(0xFF1A4FD9),
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 28,
              color: selected
                  ? Colors.white
                  : const Color(0xFFD4DCF2).withValues(alpha: 0.9),
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return theme.textTheme.labelLarge!.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: selected
                  ? Colors.white
                  : const Color(0xFFD4DCF2).withValues(alpha: 0.95),
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border_rounded),
              selectedIcon: Icon(Icons.favorite_outline_rounded),
              label: 'Wishlist',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag_rounded),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
