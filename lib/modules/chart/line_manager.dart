import 'package:flutter/material.dart';
// No external constants needed here

/// Manages drag and drop interactions for stop loss and take profit lines
class LineManager {
  static const double _dragTolerance =
      36.0; // Easier to grab: 36px vertical tolerance
  static const double _handleSize = 12.0;
  static const double _lineThickness = 2.0;
  // Thickness is controlled by painter; keep constants minimal here

  final List<double> stopLossPrices;
  final List<double> takeProfitPrices;
  final VoidCallback? onStopLossChanged;
  final VoidCallback? onTakeProfitChanged;

  // Drag state
  bool _isDragging = false;
  int? _draggedIndex;
  LineType? _draggedType;
  // Drag start position not needed for simple vertical drag

  // Hover state
  bool _isHoveringLine = false;
  int? _hoveredIndex;
  LineType? _hoveredType;

  LineManager({
    required this.stopLossPrices,
    required this.takeProfitPrices,
    this.onStopLossChanged,
    this.onTakeProfitChanged,
  });

  /// Check if a point is near any draggable line
  LineHitResult? checkHit(
      Offset position, Map<String, double> priceData, double chartHeight) {
    final y = position.dy;

    // Check stop loss lines
    for (int i = 0; i < stopLossPrices.length; i++) {
      final lineY = _priceToY(stopLossPrices[i], priceData, chartHeight);
      if ((lineY - y).abs() <= _dragTolerance) {
        return LineHitResult(
          type: LineType.stopLoss,
          index: i,
          price: stopLossPrices[i],
          y: lineY,
        );
      }
    }

    // Check take profit lines
    for (int i = 0; i < takeProfitPrices.length; i++) {
      final lineY = _priceToY(takeProfitPrices[i], priceData, chartHeight);
      if ((lineY - y).abs() <= _dragTolerance) {
        return LineHitResult(
          type: LineType.takeProfit,
          index: i,
          price: takeProfitPrices[i],
          y: lineY,
        );
      }
    }

    return null;
  }

  /// Start dragging a line
  bool startDrag(LineHitResult hit) {
    if (_isDragging) return false;

    _isDragging = true;
    _draggedIndex = hit.index;
    _draggedType = hit.type;
    return true;
  }

  /// Update drag position
  double? updateDrag(
      Offset position, Map<String, double> priceData, double chartHeight) {
    if (!_isDragging || _draggedIndex == null || _draggedType == null)
      return null;

    final newPrice = _yToPrice(position.dy, priceData, chartHeight);

    // Update the appropriate list
    if (_draggedType == LineType.stopLoss &&
        _draggedIndex! < stopLossPrices.length) {
      stopLossPrices[_draggedIndex!] = newPrice;
      onStopLossChanged?.call();
    } else if (_draggedType == LineType.takeProfit &&
        _draggedIndex! < takeProfitPrices.length) {
      takeProfitPrices[_draggedIndex!] = newPrice;
      onTakeProfitChanged?.call();
    }

    return newPrice;
  }

  /// End drag operation
  void endDrag() {
    _isDragging = false;
    _draggedIndex = null;
    _draggedType = null;
  }

  /// Update hover state
  void updateHover(
      Offset position, Map<String, double> priceData, double chartHeight) {
    final hit = checkHit(position, priceData, chartHeight);
    _isHoveringLine = hit != null;
    _hoveredIndex = hit?.index;
    _hoveredType = hit?.type;
  }

  /// Get cursor for current hover state
  MouseCursor get cursor {
    if (_isDragging || _isHoveringLine) {
      return SystemMouseCursors.resizeUpDown;
    }
    return SystemMouseCursors.basic;
  }

  /// Check if currently dragging
  bool get isDragging => _isDragging;

  /// Get hover state
  bool get isHovering => _isHoveringLine;

  /// Expose current hovered metadata for renderers
  int? get hoveredIndex => _hoveredIndex;
  LineType? get hoveredType => _hoveredType;

  /// Expose current dragged metadata for renderers
  int? get draggedIndex => _draggedIndex;
  LineType? get draggedType => _draggedType;

  /// Convert price to Y coordinate
  double _priceToY(
      double price, Map<String, double> priceData, double chartHeight) {
    final minPrice = priceData['min']!;
    final maxPrice = priceData['max']!;
    final range = maxPrice - minPrice;

    if (range == 0) return chartHeight / 2;

    final ratio = (maxPrice - price) / range;
    return ratio * chartHeight;
  }

  /// Convert Y coordinate to price
  double _yToPrice(
      double y, Map<String, double> priceData, double chartHeight) {
    final minPrice = priceData['min']!;
    final maxPrice = priceData['max']!;
    final range = maxPrice - minPrice;

    if (chartHeight == 0) return minPrice;

    final ratio = y / chartHeight;
    return maxPrice - (ratio * range);
  }

  /// Get visual properties for rendering
  LineVisualProperties getVisualProperties(
      LineType type, int index, bool isHovered, bool isDragged) {
    final isStopLoss = type == LineType.stopLoss;
    final baseColor = isStopLoss ? Colors.orange : Colors.blue;
    final thickness = isDragged ? _lineThickness + 1.0 : _lineThickness;
    final opacity = isHovered || isDragged ? 1.0 : 0.8;

    return LineVisualProperties(
      color: baseColor.withOpacity(opacity),
      thickness: thickness,
      showHandle: isHovered || isDragged,
      handleSize: _handleSize,
    );
  }
}

/// Result of a line hit test
class LineHitResult {
  final LineType type;
  final int index;
  final double price;
  final double y;

  LineHitResult({
    required this.type,
    required this.index,
    required this.price,
    required this.y,
  });
}

/// Type of line
enum LineType { stopLoss, takeProfit }

/// Visual properties for rendering lines
class LineVisualProperties {
  final Color color;
  final double thickness;
  final bool showHandle;
  final double handleSize;

  LineVisualProperties({
    required this.color,
    required this.thickness,
    required this.showHandle,
    required this.handleSize,
  });
}
