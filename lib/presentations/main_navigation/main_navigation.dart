import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../home_screen/home_screen.dart';
import '../performance_screen/performance_screen.dart';
import '../backtest_screen/backtest_screen.dart';
import '../education_screen/education_screen.dart';
import '../settings_screen/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PerformanceScreen(),
    const BackTestScreen(),
    const EducationScreen(),
    const SettingsScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    NavigationItem(
      icon: Icons.trending_up_outlined,
      activeIcon: Icons.trending_up,
      label: 'Performance',
    ),
    NavigationItem(
      icon: Icons.show_chart_outlined,
      activeIcon: Icons.show_chart,
      label: 'Backtest',
    ),
    NavigationItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      label: 'Education',
    ),
    NavigationItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      extendBody: true,
      bottomNavigationBar: _buildAnimatedNotchBottomBar(context),
    );
  }

  Widget _buildAnimatedNotchBottomBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navigationItems.length, (index) {
                final item = _navigationItems[index];
                final isSelected = _currentIndex == index;
                final isCenter = index == 2; // Backtest is the center item

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = index;
                    });
                    _animationController.reset();
                    _animationController.forward();
                  },
                  child: Container(
                    width: isCenter ? 60 : 50,
                    height: 60,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Animated background for center item
                        if (isCenter && isSelected)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        // Icon
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isCenter && isSelected
                              ? Colors.white
                              : isSelected
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                          size: isCenter ? 24 : 22,
                        ),
                        // Label
                        Positioned(
                          bottom: 2,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textTertiary,
                            ),
                            child: Text(item.label),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
