import 'package:flutter/material.dart';

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
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!, width: 1),
      ),
      child: Row(
        children: [
          _buildControlButton(
            icon: Icons.skip_previous,
            onPressed: onBack,
            color: Colors.blue[600]!,
            tooltip: 'Previous Step',
          ),
          _buildControlButton(
            icon: isPlaying ? Icons.pause : Icons.play_arrow,
            onPressed: onPlayPause,
            color: isPlaying ? Colors.orange[600]! : Colors.green[600]!,
            tooltip: isPlaying ? 'Pause' : 'Play',
          ),
          _buildControlButton(
            icon: Icons.skip_next,
            onPressed: onNext,
            color: Colors.blue[600]!,
            tooltip: 'Next Step',
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
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
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}