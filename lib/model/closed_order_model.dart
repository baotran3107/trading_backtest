import 'package:flutter/material.dart';

/// Represents a closed order with P&L data
class ClosedOrder {
  final String id;
  final String entryType; // 'BUY' or 'SELL'
  final double entryPrice;
  final double exitPrice;
  final double lotSize;
  final double pnl;
  final String closeReason; // 'SL' or 'TP'
  final DateTime entryTime;
  final DateTime exitTime;
  final Color color; // Visual color for display

  const ClosedOrder({
    required this.id,
    required this.entryType,
    required this.entryPrice,
    required this.exitPrice,
    required this.lotSize,
    required this.pnl,
    required this.closeReason,
    required this.entryTime,
    required this.exitTime,
    required this.color,
  });

  /// Calculate P&L for a position
  static double calculatePnL({
    required double entryPrice,
    required double exitPrice,
    required double lotSize,
    required String entryType,
  }) {
    // For XAUUSD, 1 lot = 100 ounces
    final double priceDifference =
        entryType == 'BUY' ? exitPrice - entryPrice : entryPrice - exitPrice;

    return priceDifference * lotSize * 100; // 100 ounces per lot
  }

  /// Create a closed order from entry data
  factory ClosedOrder.fromEntry({
    required String id,
    required String entryType,
    required double entryPrice,
    required double lotSize,
    required DateTime entryTime,
    required double exitPrice,
    required String closeReason,
  }) {
    final pnl = calculatePnL(
      entryPrice: entryPrice,
      exitPrice: exitPrice,
      lotSize: lotSize,
      entryType: entryType,
    );

    return ClosedOrder(
      id: id,
      entryType: entryType,
      entryPrice: entryPrice,
      exitPrice: exitPrice,
      lotSize: lotSize,
      pnl: pnl,
      closeReason: closeReason,
      entryTime: entryTime,
      exitTime: DateTime.now(),
      color: entryType == 'BUY' ? Colors.green : Colors.red,
    );
  }

  /// Get formatted P&L text
  String get pnlText {
    final sign = pnl >= 0 ? '+' : '';
    return '$sign\$${pnl.toStringAsFixed(2)}';
  }

  /// Get formatted entry price
  String get entryPriceText => entryPrice.toStringAsFixed(3);

  /// Get formatted exit price
  String get exitPriceText => exitPrice.toStringAsFixed(3);

  /// Get formatted lot size
  String get lotSizeText => lotSize.toString();

  /// Check if this is a profitable trade
  bool get isProfitable => pnl > 0;

  /// Get duration of the trade
  Duration get duration => exitTime.difference(entryTime);
}
