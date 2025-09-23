import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../modules/chart/chart.dart';
import '../../model/candle_model.dart';
import '../../repository/trading_data_repository.dart';
import 'widgets/trading_controls.dart';
import 'widgets/backtesting_controls.dart';
import 'widgets/price_display_panel.dart';
import 'widgets/state_widgets.dart';
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
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Buy @ ${price?.toStringAsFixed(3) ?? '-'} · $_lotSize lots'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Handle sell action
  void _onSell() {
    final price = _currentVisiblePrice();
    if (price != null) {
      setState(() {
        _sellEntries.add(price);
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Sell @ ${price?.toStringAsFixed(3) ?? '-'} · $_lotSize lots'),
        backgroundColor: Colors.red,
      ),
    );
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

            // Chart area
            Expanded(
              child: _buildChart(),
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
        return PriceDisplayPanel(
          currentPrice: currentPrice,
          previousPrice: _previousPrice,
          symbol: _metadata?['symbol'] ?? 'XAUUSD',
          description: _metadata?['description'],
          isLoading: state.isLoading,
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
