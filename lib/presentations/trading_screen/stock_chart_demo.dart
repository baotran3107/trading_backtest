import 'package:flutter/material.dart';
import '../../modules/chart/chart.dart';
import '../../model/candle_model.dart';
import '../../repository/trading_data_repository.dart';

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
      appBar: AppBar(
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
      ),
      backgroundColor: Colors.grey[900],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _buildChart(),
            ),
            const SizedBox(height: 16),
            _buildBacktestingControls(),
            const SizedBox(height: 12),
            _buildTradingControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.greenAccent),
            SizedBox(height: 16),
            Text(
              'Loading XAUUSD data...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadXAUUSDData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_xauusdData == null || _xauusdData!.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[700]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: StockChart(
        candles: _xauusdData!,
        height: 600, // Fixed height instead of double.infinity
        candleWidth: 6,
        candleSpacing: 1,
        bullishColor: Colors.greenAccent,
        bearishColor: Colors.redAccent,
        backgroundColor: Colors.grey[900]!,
        gridColor: Colors.grey[700]!,
        textColor: Colors.white,
        wickColor: Colors.grey[400]!,
        showVolume: false, // Disabled volume
        showGrid: true,
        showPriceLabels: true,
        showTimeLabels: true,
        enableInteraction: true,
        labelTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
        onLoadPastData: _onLoadPastData,
        onLoadFutureData: _onLoadFutureData,
      ),
    );
  }

  Widget _buildTradingControls() {
    // Get current price from the latest candle
    final currentPrice = _xauusdData?.isNotEmpty == true ? _xauusdData!.last.close : 0.0;
    final sellPrice = currentPrice - 0.05; // Bid price (slightly lower)
    final buyPrice = currentPrice + 0.05;  // Ask price (slightly higher)

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _onSell,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red[600],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SELL',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sellPrice.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[600]!, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  value: _lotSize,
                  isExpanded: true,
                  dropdownColor: Colors.grey[800],
                  icon: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(Icons.expand_more, color: Colors.grey[400], size: 18),
                  ),
                  style: const TextStyle(color: Colors.white),
                  selectedItemBuilder: (BuildContext context) {
                    return _lotSizes.map<Widget>((double value) {
                      return Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          value.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList();
                  },
                  onChanged: (double? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _lotSize = newValue;
                      });
                    }
                  },
                  items: _lotSizes.map<DropdownMenuItem<double>>((double value) {
                    return DropdownMenuItem<double>(
                      value: value,
                      child: Center(
                        child: Text(
                          value.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: _onBuy,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green[600],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'BUY',
                      style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      buyPrice.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBacktestingControls() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Back Button
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: _onBacktestBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.skip_previous, size: 24),
              ),
            ),
          ),
          // Play/Pause Button
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: _onBacktestPlayPause,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPlaying ? Colors.orange[600] : Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow, 
                  size: 24,
                ),
              ),
            ),
          ),
          // Next Button
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: ElevatedButton(
                onPressed: _onBacktestNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.skip_next, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
