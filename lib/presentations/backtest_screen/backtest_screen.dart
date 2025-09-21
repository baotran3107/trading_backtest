import 'package:flutter/material.dart';
import '../../modules/chart/chart.dart';
import '../../model/candle_model.dart';
import '../../repository/trading_data_repository.dart';
import 'widgets/trading_controls.dart';
import 'widgets/backtesting_controls.dart';
import 'widgets/price_display_panel.dart';
import 'widgets/state_widgets.dart';

/// Demo page showing how to use the StockChart widget with XAUUSD data
class StockChartDemo extends StatefulWidget {
  const StockChartDemo({super.key});

  @override
  State<StockChartDemo> createState() => _StockChartDemoState();
}

class _StockChartDemoState extends State<StockChartDemo> {
  final TradingDataRepository _repository = TradingDataRepository();
  List<CandleStick>? _xauusdData;
  bool _isLoading = true;
  String? _errorMessage;
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

  // Backtesting state
  bool _isBacktesting = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadXAUUSDData();
  }

  Future<void> _loadXAUUSDData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load metadata first
      final metadata = await _repository.getDataMetadata();

      // Load all data but show a subset initially
      final allData = await _repository.getAllXAUUSDData();
      
      // Take a middle chunk of the data to allow scrolling in both directions
      final totalData = allData.length;
      final centerIndex = totalData ~/ 2;
      final halfChunk = 500; // Show 1000 candles initially
      
      _currentStartIndex = (centerIndex - halfChunk).clamp(0, totalData);
      _currentEndIndex = (centerIndex + halfChunk).clamp(0, totalData);
      
      final dataToShow = allData.sublist(_currentStartIndex, _currentEndIndex);

      setState(() {
        _metadata = metadata;
        _allData = allData;
        // Store previous price before updating
        if (_xauusdData?.isNotEmpty == true) {
          _previousPrice = _xauusdData!.last.close;
        }
        _xauusdData = dataToShow;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load XAUUSD data: $e';
        _isLoading = false;
      });
    }
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
      final newStartIndex = (_currentStartIndex - loadChunkSize).clamp(0, _allData!.length);
      final pastData = _allData!.sublist(newStartIndex, _currentStartIndex);
      
      setState(() {
        _xauusdData = [...pastData, ..._xauusdData!];
        _currentStartIndex = newStartIndex;
        _isLoadingPast = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPast = false;
        _errorMessage = 'Error loading past data: $e';
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
      final newEndIndex = (_currentEndIndex + loadChunkSize).clamp(0, _allData!.length);
      
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
        _errorMessage = 'Error loading future data: $e';
      });
    }
  }

  /// Handle buy action
  void _onBuy() {
    // TODO: Implement buy logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Buy order placed: $_lotSize lots'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Handle sell action
  void _onSell() {
    // TODO: Implement sell logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sell order placed: $_lotSize lots'),
        backgroundColor: Colors.red,
      ),
    );
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

  /// Handle back button for backtesting
  void _onBacktestBack() {
    // TODO: Implement back functionality for backtesting
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Back: Previous step'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Handle play/pause button for backtesting
  void _onBacktestPlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isPlaying ? 'Backtesting: Playing' : 'Backtesting: Paused'),
        backgroundColor: _isPlaying ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Handle next button for backtesting
  void _onBacktestNext() {
    // TODO: Implement next functionality for backtesting
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Next: Forward step'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
  }

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
    if (_isLoading) {
      return const LoadingStateWidget(
        message: 'Loading XAUUSD data...',
      );
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        errorMessage: _errorMessage!,
        onRetry: _loadXAUUSDData,
      );
    }

    if (_xauusdData == null || _xauusdData!.isEmpty) {
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
          candles: _xauusdData!,
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
          labelTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
          onLoadPastData: _onLoadPastData,
          onLoadFutureData: _onLoadFutureData,
        ),
      ),
    );
  }

  Widget _buildPricePanel() {
    final currentPrice = _xauusdData?.isNotEmpty == true ? _xauusdData!.last.close : null;
    
    return PriceDisplayPanel(
      currentPrice: currentPrice,
      previousPrice: _previousPrice,
      symbol: _metadata?['symbol'] ?? 'XAUUSD',
      description: _metadata?['description'],
      isLoading: _isLoading,
    );
  }

  Widget _buildTradingControlsWidget() {
    final currentPrice = _xauusdData?.isNotEmpty == true ? _xauusdData!.last.close : 0.0;
    
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
    return BacktestingControls(
      isPlaying: _isPlaying,
      onBack: _onBacktestBack,
      onPlayPause: _onBacktestPlayPause,
      onNext: _onBacktestNext,
    );
  }

}
