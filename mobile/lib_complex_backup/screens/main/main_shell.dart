import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../services/navigation_service.dart';
import '../../widgets/common/custom_bottom_navigation.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: const CustomBottomNavigation(),
    );
  }
}

class CustomBottomNavigation extends StatelessWidget {
  const CustomBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).location;
    final selectedIndex = _getSelectedIndex(location);

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home,
                    label: 'Current',
                    index: 0,
                    selectedIndex: selectedIndex,
                    badgeCount: 0,
                    onTap: () => NavigationService.goToCurrent(),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.search_outlined,
                    selectedIcon: Icons.search,
                    label: 'Discover',
                    index: 1,
                    selectedIndex: selectedIndex,
                    badgeCount: 0,
                    onTap: () => NavigationService.goToDiscover(),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.favorite_outline,
                    selectedIcon: Icons.favorite,
                    label: 'Wishlist',
                    index: 2,
                    selectedIndex: selectedIndex,
                    badgeCount: appProvider.wishlistCount,
                    onTap: () => NavigationService.goToWishlist(),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.person_outline,
                    selectedIcon: Icons.person,
                    label: 'Profile',
                    index: 3,
                    selectedIndex: selectedIndex,
                    badgeCount: appProvider.unverifiedVisitsCount,
                    onTap: () => NavigationService.goToProfile(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required int selectedIndex,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.orange.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    key: ValueKey(isSelected),
                    color: isSelected 
                        ? Colors.orange 
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: _buildBadge(badgeCount),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected 
                    ? Colors.orange 
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
      constraints: const BoxConstraints(
        minWidth: 16,
        minHeight: 16,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/main/current')) return 0;
    if (location.startsWith('/main/discover')) return 1;
    if (location.startsWith('/main/wishlist')) return 2;
    if (location.startsWith('/main/profile')) return 3;
    return 0; // Default to current tab
  }
}

