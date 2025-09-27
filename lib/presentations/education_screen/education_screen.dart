import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Education'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              const SizedBox(height: AppSpacing.xxxlg),

              // Learning Path
              _buildLearningPath(),
              const SizedBox(height: AppSpacing.xxxlg),

              // Quick Lessons
              _buildQuickLessons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxxlg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.school,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Trading Education',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Learn trading strategies and improve your skills',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningPath() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning Path',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildPathStep(
          step: '1',
          title: 'Trading Basics',
          description: 'Learn fundamental concepts',
          isCompleted: true,
        ),
        _buildPathStep(
          step: '2',
          title: 'Technical Analysis',
          description: 'Chart patterns and indicators',
          isCompleted: true,
        ),
        _buildPathStep(
          step: '3',
          title: 'Risk Management',
          description: 'Protect your capital',
          isCompleted: false,
        ),
        _buildPathStep(
          step: '4',
          title: 'Advanced Strategies',
          description: 'Complex trading systems',
          isCompleted: false,
        ),
      ],
    );
  }

  Widget _buildPathStep({
    required String step,
    required String title,
    required String description,
    required bool isCompleted,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: isCompleted ? AppColors.success : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.textTertiary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusRound),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : Text(
                      step,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.success,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildQuickLessons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Lessons',
          style: AppTextStyles.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildLessonCard(
          title: 'Candlestick Patterns',
          duration: '5 min',
          difficulty: 'Beginner',
        ),
        _buildLessonCard(
          title: 'Support & Resistance',
          duration: '8 min',
          difficulty: 'Intermediate',
        ),
        _buildLessonCard(
          title: 'Risk Management',
          duration: '12 min',
          difficulty: 'Advanced',
        ),
      ],
    );
  }

  Widget _buildLessonCard({
    required String title,
    required String duration,
    required String difficulty,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: const Icon(
              Icons.play_circle_outline,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Text(
                      duration,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Text(
                        difficulty,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: AppColors.textTertiary,
            size: 16,
          ),
        ],
      ),
    );
  }
}
