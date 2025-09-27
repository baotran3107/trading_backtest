import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../modules/chart/chart.dart';
import '../../model/candle_model.dart';
import '../../model/closed_order_model.dart';
import '../../repository/trading_data_repository.dart';
import '../../utils/custom_notification.dart';
import 'widgets/trading_controls.dart';
import 'widgets/backtesting_controls.dart';
import 'widgets/price_display_panel.dart';
import 'widgets/state_widgets.dart';
import 'widgets/closed_orders_panel.dart';
import 'bloc/backtest_bloc.dart';

/// Demo page showing how to use the StockChart widget with XAUUSD data
class BackTestScreen extends StatefulWidget {
  const BackTestScreen({super.key});

  @override
  State<BackTestScreen> createState() => _BackTestScreenState();
}

class _BackTestScreenState extends State<BackTestScreen> {
  final TradingDataRepository _repository = TradingDataRepository();
  List<CandleStick>? _xauusdData;
  Map<String, dynamic>? _metadata;
  double? _previousPrice;

  // Trading controls state
  double _lotSize = 0.01;
  final List<double> _lotSizes = [0.01, 0.05, 0.10, 0.25, 0.50, 1.0];

  // Scroll functionality state
  bool _isLoadingPast = false;
  bool _isLoadingFuture = false;
  int _currentStartIndex = 0;
  int _currentEndIndex = 1000;
  List<CandleStick>? _allData; // Keep reference to all data

  // Order entry tracking for display
  final List<double> _buyEntries = [];
  final List<double> _sellEntries = [];
  final List<double> _stopLossPrices = [];
  final List<double> _takeProfitPrices = [];

  // Track lot sizes for each position (same order as entries)
  final List<double> _buyLotSizes = [];
  final List<double> _sellLotSizes = [];

  // Track entry types for P&L calculation
  final List<String> _entryTypes = []; // 'BUY' or 'SELL'

  // Track entry times for closed order history
  final List<DateTime> _entryTimes = [];

  // Store closed orders with P&L data
  final List<ClosedOrder> _closedOrders = [];

  // Track order IDs for unique identification
  int _orderIdCounter = 0;

  // Track which orders have been closed in the current candle to prevent duplicates
  final Set<int> _closedInCurrentCandle = {};

  // Track the last processed candle timestamp to detect new candles
  DateTime? _lastProcessedCandleTime;

  // Backtesting state handled by BLoC

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadMetadata() async {
    try {
      final metadata = await _repository.getDataMetadata();
      setState(() {
        _metadata = metadata;
      });
    } catch (e) {}
  }

  /// Load historical data when scrolling to past
  Future<void> _onLoadPastData() async {
    if (_isLoadingPast || _allData == null || _currentStartIndex <= 0) return;

    setState(() {
      _isLoadingPast = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      final loadChunkSize = 500;
      final newStartIndex =
          (_currentStartIndex - loadChunkSize).clamp(0, _allData!.length);
      final pastData = _allData!.sublist(newStartIndex, _currentStartIndex);

      setState(() {
        _xauusdData = [...pastData, ..._xauusdData!];
        _currentStartIndex = newStartIndex;
        _isLoadingPast = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPast = false;
      });
    }
  }

  /// Load future data when scrolling to future
  Future<void> _onLoadFutureData() async {
    if (_isLoadingFuture || _allData == null) return;

    setState(() {
      _isLoadingFuture = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      final loadChunkSize = 500;
      final newEndIndex =
          (_currentEndIndex + loadChunkSize).clamp(0, _allData!.length);

      if (newEndIndex > _currentEndIndex) {
        final futureData = _allData!.sublist(_currentEndIndex, newEndIndex);

        setState(() {
          _xauusdData = [..._xauusdData!, ...futureData];
          _currentEndIndex = newEndIndex;
          _isLoadingFuture = false;
        });
      } else {
        setState(() {
          _isLoadingFuture = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFuture = false;
      });
    }
  }

  /// Handle buy action
  void _onBuy() {
    final price = _currentVisiblePrice();
    if (price != null) {
      setState(() {
        _buyEntries.add(price);
        _buyLotSizes.add(_lotSize);
        _entryTypes.add('BUY');
        _entryTimes.add(DateTime.now());
        // Auto SL/TP: example offsets for XAUUSD
        _stopLossPrices.add(price - 1.0);
        _takeProfitPrices.add(price + 2.0);
      });
    }
  }

  /// Handle sell action
  void _onSell() {
    final price = _currentVisiblePrice();
    if (price != null) {
      setState(() {
        _sellEntries.add(price);
        _sellLotSizes.add(_lotSize);
        _entryTypes.add('SELL');
        _entryTimes.add(DateTime.now());
        // Auto SL/TP for sell
        _stopLossPrices.add(price + 1.0);
        _takeProfitPrices.add(price - 2.0);
      });
    }
  }

  double? _currentVisiblePrice() {
    final ctx = context;
    final blocState = ctx.read<BacktestBloc>().state;
    if (blocState.visibleCandles.isNotEmpty) {
      return blocState.visibleCandles.last.close;
    }
    if (_xauusdData?.isNotEmpty == true) {
      return _xauusdData!.last.close;
    }
    return null;
  }

  /// Calculate P&L for a position
  double _calculatePnL({
    required double entryPrice,
    required double exitPrice,
    required double lotSize,
    required String entryType,
  }) {
    // For XAUUSD, 1 lot = 100 ounces
    // P&L = (exitPrice - entryPrice) * lotSize * 100
    // For SELL positions, reverse the calculation
    final double priceDifference =
        entryType == 'BUY' ? exitPrice - entryPrice : entryPrice - exitPrice;

    return priceDifference * lotSize * 100; // 100 ounces per lot
  }

  /// Get P&L for stop loss at given index
  double? _getStopLossPnL(int index) {
    if (index >= _stopLossPrices.length) return null;

    final slPrice = _stopLossPrices[index];
    final entryType = index < _entryTypes.length ? _entryTypes[index] : 'BUY';
    final lotSize = entryType == 'BUY'
        ? (index < _buyLotSizes.length ? _buyLotSizes[index] : _lotSize)
        : (index < _sellLotSizes.length ? _sellLotSizes[index] : _lotSize);

    final entryPrice = entryType == 'BUY'
        ? (index < _buyEntries.length ? _buyEntries[index] : 0.0)
        : (index < _sellEntries.length ? _sellEntries[index] : 0.0);

    if (entryPrice == 0.0) return null;

    return _calculatePnL(
      entryPrice: entryPrice,
      exitPrice: slPrice,
      lotSize: lotSize,
      entryType: entryType,
    );
  }

  /// Get P&L for take profit at given index
  double? _getTakeProfitPnL(int index) {
    if (index >= _takeProfitPrices.length) return null;

    final tpPrice = _takeProfitPrices[index];
    final entryType = index < _entryTypes.length ? _entryTypes[index] : 'BUY';
    final lotSize = entryType == 'BUY'
        ? (index < _buyLotSizes.length ? _buyLotSizes[index] : _lotSize)
        : (index < _sellLotSizes.length ? _sellLotSizes[index] : _lotSize);

    final entryPrice = entryType == 'BUY'
        ? (index < _buyEntries.length ? _buyEntries[index] : 0.0)
        : (index < _sellEntries.length ? _sellEntries[index] : 0.0);

    if (entryPrice == 0.0) return null;

    return _calculatePnL(
      entryPrice: entryPrice,
      exitPrice: tpPrice,
      lotSize: lotSize,
      entryType: entryType,
    );
  }

  /// Check for price crossings and close orders if needed
  void _checkOrderCrossings() {
    // Get the latest candle to check high/low prices
    final latestCandle = _getLatestCandle();
    if (latestCandle == null) return;

    // Check if this is a new candle - reset closed orders tracking
    if (_lastProcessedCandleTime != latestCandle.time) {
      _closedInCurrentCandle.clear();
      _lastProcessedCandleTime = latestCandle.time;
    }

    final List<int> ordersToClose = [];

    // Check stop loss crossings using candle high/low
    for (int i = 0; i < _stopLossPrices.length; i++) {
      if (i >= _entryTypes.length || _closedInCurrentCandle.contains(i))
        continue;

      final slPrice = _stopLossPrices[i];
      final entryType = _entryTypes[i];

      bool shouldClose = false;
      double executionPrice = slPrice;

      if (entryType == 'BUY' && latestCandle.low <= slPrice) {
        // BUY order: close if candle low touches or passes SL
        shouldClose = true;
        // Use the actual SL price as execution price
        executionPrice = slPrice;
      } else if (entryType == 'SELL' && latestCandle.high >= slPrice) {
        // SELL order: close if candle high touches or passes SL
        shouldClose = true;
        // Use the actual SL price as execution price
        executionPrice = slPrice;
      }

      if (shouldClose) {
        ordersToClose.add(i);
        _closedInCurrentCandle.add(i);
        _closeOrder(i, executionPrice, 'SL');
      }
    }

    // Check take profit crossings using candle high/low
    for (int i = 0; i < _takeProfitPrices.length; i++) {
      if (i >= _entryTypes.length || _closedInCurrentCandle.contains(i))
        continue;

      final tpPrice = _takeProfitPrices[i];
      final entryType = _entryTypes[i];

      bool shouldClose = false;
      double executionPrice = tpPrice;

      if (entryType == 'BUY' && latestCandle.high >= tpPrice) {
        // BUY order: close if candle high touches or passes TP
        shouldClose = true;
        // Use the actual TP price as execution price
        executionPrice = tpPrice;
      } else if (entryType == 'SELL' && latestCandle.low <= tpPrice) {
        // SELL order: close if candle low touches or passes TP
        shouldClose = true;
        // Use the actual TP price as execution price
        executionPrice = tpPrice;
      }

      if (shouldClose) {
        ordersToClose.add(i);
        _closedInCurrentCandle.add(i);
        _closeOrder(i, executionPrice, 'TP');
      }
    }

    // Remove closed orders from all lists (in reverse order to maintain indices)
    if (ordersToClose.isNotEmpty) {
      setState(() {
        ordersToClose.sort((a, b) => b.compareTo(a)); // Sort descending
        for (final index in ordersToClose) {
          _removeOrderAtIndex(index);
        }
      });
    }
  }

  /// Get the latest candle for crossing detection
  CandleStick? _getLatestCandle() {
    final ctx = context;
    final blocState = ctx.read<BacktestBloc>().state;
    if (blocState.visibleCandles.isNotEmpty) {
      return blocState.visibleCandles.last;
    }
    if (_xauusdData?.isNotEmpty == true) {
      return _xauusdData!.last;
    }
    return null;
  }

  /// Close an order and store P&L data
  void _closeOrder(int index, double exitPrice, String closeReason) {
    if (index >= _entryTypes.length) return;

    final entryType = _entryTypes[index];
    final entryPrice = entryType == 'BUY'
        ? (index < _buyEntries.length ? _buyEntries[index] : 0.0)
        : (index < _sellEntries.length ? _sellEntries[index] : 0.0);
    final lotSize = entryType == 'BUY'
        ? (index < _buyLotSizes.length ? _buyLotSizes[index] : _lotSize)
        : (index < _sellLotSizes.length ? _sellLotSizes[index] : _lotSize);
    final entryTime =
        index < _entryTimes.length ? _entryTimes[index] : DateTime.now();

    if (entryPrice == 0.0) return;

    final closedOrder = ClosedOrder.fromEntry(
      id: 'ORDER_${_orderIdCounter++}',
      entryType: entryType,
      entryPrice: entryPrice,
      lotSize: lotSize,
      entryTime: entryTime,
      exitPrice: exitPrice,
      closeReason: closeReason,
    );

    _closedOrders.add(closedOrder);

    // Show notification
    final pnlText = closedOrder.pnlText;
    final color = closedOrder.isProfitable ? Colors.green : Colors.red;
    final icon =
        closedOrder.isProfitable ? Icons.trending_up : Icons.trending_down;

    context.showCustomNotification(
      message:
          'Order closed: $closeReason @ ${exitPrice.toStringAsFixed(3)} · $pnlText',
      backgroundColor: color,
      textColor: Colors.white,
      icon: icon,
      duration: const Duration(seconds: 3),
    );
  }

  /// Remove order at specific index from all tracking lists
  void _removeOrderAtIndex(int index) {
    if (index >= _entryTypes.length) return;

    final entryType = _entryTypes[index];

    // Remove from appropriate entry list
    if (entryType == 'BUY' && index < _buyEntries.length) {
      _buyEntries.removeAt(index);
      if (index < _buyLotSizes.length) {
        _buyLotSizes.removeAt(index);
      }
    } else if (entryType == 'SELL' && index < _sellEntries.length) {
      _sellEntries.removeAt(index);
      if (index < _sellLotSizes.length) {
        _sellLotSizes.removeAt(index);
      }
    }

    // Remove from common lists
    if (index < _entryTypes.length) _entryTypes.removeAt(index);
    if (index < _entryTimes.length) _entryTimes.removeAt(index);
    if (index < _stopLossPrices.length) _stopLossPrices.removeAt(index);
    if (index < _takeProfitPrices.length) _takeProfitPrices.removeAt(index);
  }

  /// Show indicator selection dialog
  void _showIndicatorSelection() {
    // TODO: Implement indicator selection
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Indicators'),
          content: const Text('Indicator selection coming soon...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Show timeframe selection dialog
  void _showTimeframeSelection() {
    // TODO: Implement timeframe selection
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Timeframe'),
          content: const Text('Timeframe selection coming soon...'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // BLoC now handles backtesting actions

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.grey[900],
      body: LayoutBuilder(
        builder: (context, constraints) {
          return _buildResponsiveLayout(constraints);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_metadata != null
          ? '${_metadata!['symbol']} - ${_metadata!['description']}'
          : 'XAUUSD Chart'),
      backgroundColor: Colors.grey[900],
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.timeline),
          onPressed: _showIndicatorSelection,
          tooltip: 'Indicators',
        ),
        IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: _showTimeframeSelection,
          tooltip: 'Timeframe',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            // TODO: Add general settings
          },
          tooltip: 'Settings',
        ),
      ],
    );
  }

  Widget _buildResponsiveLayout(BoxConstraints constraints) {
    final isPortrait = constraints.maxHeight > constraints.maxWidth;
    final screenWidth = constraints.maxWidth;

    // Determine if we should use mobile or tablet/desktop layout
    final isMobile = screenWidth < 600;

    if (isMobile && isPortrait) {
      return _buildMobilePortraitLayout();
    } else if (isMobile && !isPortrait) {
      return _buildMobileLandscapeLayout();
    } else {
      return _buildTabletDesktopLayout(constraints);
    }
  }

  Widget _buildMobilePortraitLayout() {
    return SafeArea(
      child: Column(
        children: [
          // Price display panel
          _buildPricePanel(),

          // Chart takes most of the space
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildChart(),
            ),
          ),

          // Controls at bottom
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(child: _buildBacktestingControlsWidget()),
                  const SizedBox(height: 8),
                  Expanded(child: _buildTradingControlsWidget()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLandscapeLayout() {
    return SafeArea(
      child: Row(
        children: [
          // Chart takes most space on the left
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _buildPricePanel(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildChart(),
                  ),
                ),
              ],
            ),
          ),

          // Controls on the right side
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(child: _buildBacktestingControlsWidget()),
                  const SizedBox(height: 8),
                  Expanded(child: _buildTradingControlsWidget()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletDesktopLayout(BoxConstraints constraints) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Price panel
            _buildPricePanel(),

            const SizedBox(height: 16),

            // Main content area with chart and orders
            Expanded(
              child: Row(
                children: [
                  // Chart area
                  Expanded(
                    flex: 3,
                    child: _buildChart(),
                  ),

                  const SizedBox(width: 16),

                  // Closed orders panel
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClosedOrdersPanel(
                        closedOrders: _closedOrders,
                        onClear: () {
                          setState(() {
                            _closedOrders.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Controls row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildBacktestingControlsWidget(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: _buildTradingControlsWidget(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return BlocBuilder<BacktestBloc, BacktestState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const LoadingStateWidget(
            message: 'Loading XAUUSD data...',
          );
        }

        if (state.errorMessage != null) {
          return ErrorStateWidget(
            errorMessage: state.errorMessage!,
            onRetry: () =>
                context.read<BacktestBloc>().add(const BacktestInitialized()),
          );
        }

        if (state.visibleCandles.isEmpty) {
          return const EmptyStateWidget(
            message: 'No trading data available',
            icon: Icons.show_chart,
          );
        }

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[700]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[900],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: StockChart(
              candles: state.visibleCandles,
              height: double.infinity,
              candleWidth: 6,
              candleSpacing: 1,
              bullishColor: Colors.greenAccent,
              bearishColor: Colors.redAccent,
              backgroundColor: Colors.grey[900]!,
              gridColor: Colors.grey[700]!,
              textColor: Colors.white,
              wickColor: Colors.grey[400]!,
              showVolume: false,
              showGrid: true,
              showPriceLabels: true,
              showTimeLabels: true,
              enableInteraction: true,
              labelTextStyle:
                  const TextStyle(color: Colors.white, fontSize: 10),
              onLoadPastData: _onLoadPastData,
              onLoadFutureData: _onLoadFutureData,
              // Use provider-driven rendering to keep interactions working
              useProvidedCandlesDirectly: false,
              autoFollowLatest: true,
              isPlaying: state.isPlaying,
              futurePaddingCandles: 20,
              buyEntryPrices: _buyEntries,
              sellEntryPrices: _sellEntries,
              stopLossPrices: _stopLossPrices,
              takeProfitPrices: _takeProfitPrices,
              onStopLossPricesChanged: (updated) {
                setState(() {
                  _stopLossPrices
                    ..clear()
                    ..addAll(updated);
                });
              },
              onTakeProfitPricesChanged: (updated) {
                setState(() {
                  _takeProfitPrices
                    ..clear()
                    ..addAll(updated);
                });
              },
              getStopLossPnL: () {
                return List.generate(_stopLossPrices.length,
                    (index) => _getStopLossPnL(index) ?? 0.0);
              },
              getTakeProfitPnL: () {
                return List.generate(_takeProfitPrices.length,
                    (index) => _getTakeProfitPnL(index) ?? 0.0);
              },
              onPriceUpdate: _checkOrderCrossings,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPricePanel() {
    return BlocBuilder<BacktestBloc, BacktestState>(
      builder: (context, state) {
        final currentPrice = state.visibleCandles.isNotEmpty
            ? state.visibleCandles.last.close
            : null;

        // Calculate P&L summary
        final totalPnL =
            _closedOrders.fold<double>(0.0, (sum, order) => sum + order.pnl);
        final profitableTrades =
            _closedOrders.where((order) => order.isProfitable).length;
        final winRate = _closedOrders.isNotEmpty
            ? (profitableTrades / _closedOrders.length) * 100
            : 0.0;

        return PriceDisplayPanel(
          currentPrice: currentPrice,
          previousPrice: _previousPrice,
          symbol: _metadata?['symbol'] ?? 'XAUUSD',
          description: _metadata?['description'],
          isLoading: state.isLoading,
          totalPnL: totalPnL,
          totalTrades: _closedOrders.length,
          winRate: winRate,
        );
      },
    );
  }

  Widget _buildTradingControlsWidget() {
    final currentPrice =
        _xauusdData?.isNotEmpty == true ? _xauusdData!.last.close : 0.0;

    return TradingControls(
      currentPrice: currentPrice,
      lotSize: _lotSize,
      availableLotSizes: _lotSizes,
      onBuy: _onBuy,
      onSell: _onSell,
      onLotSizeChanged: (newSize) {
        setState(() {
          _lotSize = newSize;
        });
      },
    );
  }

  Widget _buildBacktestingControlsWidget() {
    return BlocBuilder<BacktestBloc, BacktestState>(
      builder: (context, state) {
        return BacktestingControls(
          isPlaying: state.isPlaying,
          onBack: () =>
              context.read<BacktestBloc>().add(const BacktestStepBack()),
          onPlayPause: () =>
              context.read<BacktestBloc>().add(const BacktestPlayToggled()),
          onNext: () =>
              context.read<BacktestBloc>().add(const BacktestStepNext()),
        );
      },
    );
  }
}
