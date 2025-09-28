import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';
import '../auth/auth_screen.dart';
import '../../core/extensions/navigation_extension.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<WelcomePageData> _pages = [
    WelcomePageData(
      title: 'Welcome to Trading Game',
      subtitle: 'Master the markets with confidence',
      description:
          'Learn trading strategies, practice with real market data, and improve your skills in a risk-free environment.',
      icon: '📈',
      color: AppColors.primary,
    ),
    WelcomePageData(
      title: 'Advanced Analytics',
      subtitle: 'Powerful tools for better decisions',
      description:
          'Access comprehensive charts, backtesting capabilities, and performance analytics to refine your trading strategies.',
      icon: '📊',
      color: AppColors.secondary,
    ),
    WelcomePageData(
      title: 'Ready to Start?',
      subtitle: 'Your trading journey begins here',
      description:
          'Join thousands of traders who are already improving their skills. Start your journey to trading mastery today.',
      icon: '🚀',
      color: AppColors.success,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeWelcome();
    }
  }

  void _skipWelcome() {
    _completeWelcome();
  }

  Future<void> _completeWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_completed', true);

    if (mounted) {
      context.pushReplacement(const AuthScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _skipWelcome,
                  child: Text(
                    'Skip',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildWelcomePage(_pages[index]);
                },
              ),
            ),

            // Bottom section with indicators and button
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(WelcomePageData pageData) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: pageData.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Text(
                pageData.icon,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            pageData.title,
            style: AppTextStyles.displayMedium.copyWith(
              color: pageData.color,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            pageData.subtitle,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            pageData.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textTertiary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildPageIndicator(index),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Next/Get Started button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentPage == _pages.length - 1
                    ? AppColors.success
                    : AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                style: AppTextStyles.buttonLarge.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class WelcomePageData {
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final Color color;

  WelcomePageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}
