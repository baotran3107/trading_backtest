import 'package:flutter/material.dart';
import '../../../model/closed_order_model.dart';

class ClosedOrdersPanel extends StatelessWidget {
  final List<ClosedOrder> closedOrders;
  final VoidCallback? onClear;

  const ClosedOrdersPanel({
    super.key,
    required this.closedOrders,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (closedOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Text(
            'No closed orders yet',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Calculate total P&L
    final totalPnL =
        closedOrders.fold<double>(0.0, (sum, order) => sum + order.pnl);
    final profitableTrades =
        closedOrders.where((order) => order.isProfitable).length;
    final winRate = closedOrders.isNotEmpty
        ? (profitableTrades / closedOrders.length) * 100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Closed Orders (${closedOrders.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onClear != null)
                TextButton(
                  onPressed: onClear,
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // P&L Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total P&L',
                  totalPnL >= 0
                      ? '+${totalPnL.toStringAsFixed(2)}'
                      : totalPnL.toStringAsFixed(2),
                  totalPnL >= 0 ? Colors.green : Colors.red,
                ),
                _buildSummaryItem(
                  'Win Rate',
                  '${winRate.toStringAsFixed(1)}%',
                  Colors.white,
                ),
                _buildSummaryItem(
                  'Trades',
                  '${closedOrders.length}',
                  Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Orders list
          Expanded(
            child: ListView.builder(
              itemCount: closedOrders.length,
              itemBuilder: (context, index) {
                final order = closedOrders[
                    closedOrders.length - 1 - index]; // Show newest first
                return _buildOrderItem(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(ClosedOrder order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: order.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Order type and close reason
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: order.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${order.entryType} ${order.closeReason}',
              style: TextStyle(
                color: order.color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Price info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.entryPriceText} → ${order.exitPriceText}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${order.lotSizeText} lots • ${_formatDuration(order.duration)}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // P&L
          Text(
            order.pnlText,
            style: TextStyle(
              color: order.isProfitable ? Colors.green : Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds}s';
    } else if (duration.inHours < 1) {
      return '${duration.inMinutes}m';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }
}
