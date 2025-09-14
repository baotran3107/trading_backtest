import 'package:flutter/material.dart';
import '../../modules/chart/chart.dart';
import '../../model/candle_model.dart';
import '../../services/data_import_service.dart';

/// Demo page showing how to use the StockChart widget with XAUUSD data
class StockChartDemo extends StatefulWidget {
  const StockChartDemo({super.key});

  @override
  State<StockChartDemo> createState() => _StockChartDemoState();
}

class _StockChartDemoState extends State<StockChartDemo> {
  final DataImportService _dataImportService = DataImportService();
  List<CandleStick>? _xauusdData;
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _metadata;

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
      final metadata = await _dataImportService.getDataMetadata();

      // Load a subset of data for better performance (last 1000 candles)
      final allData = await _dataImportService.importXAUUSDData();
      final dataToShow = allData.length > 1000
          ? allData.sublist(allData.length - 1000)
          : allData;

      setState(() {
        _metadata = metadata;
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
            Text(
              _metadata != null
                  ? 'Period: ${_metadata!['period']}M | Bars: ${_xauusdData?.length ?? 0} | Currency: ${_metadata!['baseCurrency']}'
                  : 'Loading XAUUSD data...',
              style: const TextStyle(color: Colors.grey),
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
        height: double.infinity,
        candleWidth: 6,
        candleSpacing: 1,
        bullishColor: Colors.greenAccent,
        bearishColor: Colors.redAccent,
        backgroundColor: Colors.grey[900]!,
        gridColor: Colors.grey[700]!,
        textColor: Colors.white,
        wickColor: Colors.grey[400]!,
        showVolume: true,
        showGrid: true,
        showPriceLabels: true,
        showTimeLabels: true,
        enableInteraction: true,
        labelTextStyle: const TextStyle(color: Colors.white, fontSize: 10),
        onCandleTap: (candle) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.grey[800],
              content: Text(
                'XAUUSD - ${candle.time.day}/${candle.time.month}/${candle.time.year} ${candle.time.hour}:${candle.time.minute.toString().padLeft(2, '0')}\n'
                'O: \$${candle.open.toStringAsFixed(3)} H: \$${candle.high.toStringAsFixed(3)} L: \$${candle.low.toStringAsFixed(3)} C: \$${candle.close.toStringAsFixed(3)}\n'
                'Volume: ${candle.volume.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }
}
