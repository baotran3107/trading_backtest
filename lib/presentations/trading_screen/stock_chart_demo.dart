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
  
  // Scroll functionality state
  bool _isLoadingPast = false;
  bool _isLoadingFuture = false;
  int _currentStartIndex = 0;
  int _currentEndIndex = 1000;
  List<CandleStick>? _allData; // Keep reference to all data

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
            icon: const Icon(Icons.refresh),
            onPressed: _loadXAUUSDData,
          ),
        ],
      ),
      backgroundColor: Colors.grey[900],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _metadata != null
                  ? '${_metadata!['symbol']} (${_metadata!['description']})'
                  : 'XAUUSD Chart',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _metadata != null
                      ? 'Period: ${_metadata!['period']}M | Bars: ${_xauusdData?.length ?? 0} | Currency: ${_metadata!['baseCurrency']}'
                      : 'Loading XAUUSD data...',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                if (_isLoadingPast || _isLoadingFuture)
                  Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.greenAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isLoadingPast ? 'Loading Past...' : 'Loading Future...',
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Instructions for scrolling
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Pan horizontally to scroll through time • Pinch to zoom • Double tap to reset',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildChart(),
            ),
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
}
