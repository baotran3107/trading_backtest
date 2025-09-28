import 'package:flutter/material.dart';
import '../../../theme/theme_colors.dart';

class BacktestingControls extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onBack;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  const BacktestingControls({
    super.key,
    required this.isPlaying,
    required this.onBack,
    required this.onPlayPause,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: ThemeColors.surfaceContainer(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.border(context), width: 1),
      ),
      child: Row(
        children: [
          _buildControlButton(
            context,
            icon: Icons.skip_previous,
            onPressed: onBack,
            color: ThemeColors.buttonLightPrimary(context),
            tooltip: 'Previous Step',
          ),
          _buildControlButton(
            context,
            icon: isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: onPlayPause,
            color: isPlaying
                ? ThemeColors.buttonLightWarning(context)
                : ThemeColors.buttonLightSuccess(context),
            iconColor: ThemeColors.textPrimary(context),
            tooltip: isPlaying ? 'Pause' : 'Play',
          ),
          _buildControlButton(
            context,
            icon: Icons.skip_next,
            onPressed: onNext,
            color: ThemeColors.buttonLightPrimary(context),
            tooltip: 'Next Step',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    Color? iconColor,
    required String tooltip,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: ThemeColors.border(context),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: ThemeColors.shadow(context),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor ?? color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
