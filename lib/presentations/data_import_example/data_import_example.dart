import 'package:flutter/material.dart';
import '../../repository/trading_data_repository.dart';
import '../../model/candle_model.dart';

/// Example widget demonstrating XAUUSD data import and display
class DataImportExample extends StatefulWidget {
  const DataImportExample({Key? key}) : super(key: key);

  @override
  State<DataImportExample> createState() => _DataImportExampleState();
}

class _DataImportExampleState extends State<DataImportExample> {
  final TradingDataRepository _repository = TradingDataRepository();

  List<CandleStick>? _sampleData;
  Map<String, dynamic>? _metadata;
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  Future<void> _loadSampleData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load sample data (first 100 records)
      final sampleData = await _repository.getSampleData();

      // Load metadata
      final metadata = await _repository.getDataMetadata();

      // Load statistics
      final statistics = await _repository.getDataStatistics();

      setState(() {
        _sampleData = sampleData;
        _metadata = metadata;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('XAUUSD Data Import Example'),
        backgroundColor: Colors.amber,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading data:',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSampleData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metadata Section
                      _buildMetadataCard(),
                      const SizedBox(height: 16),

                      // Statistics Section
                      _buildStatisticsCard(),
                      const SizedBox(height: 16),

                      // Sample Data Section
                      _buildSampleDataCard(),

                      const SizedBox(height: 16),

                      // Action Buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetadataCard() {
    if (_metadata == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dataset Metadata',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Symbol', _metadata!['symbol']?.toString() ?? 'N/A'),
            _buildInfoRow(
                'Description', _metadata!['description']?.toString() ?? 'N/A'),
            _buildInfoRow(
                'Company', _metadata!['company']?.toString() ?? 'N/A'),
            _buildInfoRow('Period', '${_metadata!['period']} minute(s)'),
            _buildInfoRow(
                'Total Bars', _metadata!['bars']?.toString() ?? 'N/A'),
            _buildInfoRow('Digits', _metadata!['digits']?.toString() ?? 'N/A'),
            _buildInfoRow(
                'Point Value', _metadata!['point']?.toString() ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (_statistics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dataset Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
                'Total Records', _statistics!['count']?.toString() ?? 'N/A'),
            _buildInfoRow('Min Price',
                '\$${_statistics!['minPrice']?.toStringAsFixed(3) ?? 'N/A'}'),
            _buildInfoRow('Max Price',
                '\$${_statistics!['maxPrice']?.toStringAsFixed(3) ?? 'N/A'}'),
            _buildInfoRow('Avg Price',
                '\$${_statistics!['avgPrice']?.toStringAsFixed(3) ?? 'N/A'}'),
            _buildInfoRow('Total Volume',
                _statistics!['totalVolume']?.toStringAsFixed(0) ?? 'N/A'),
            if (_statistics!['timeRange'] != null) ...[
              _buildInfoRow(
                  'Start Time', _statistics!['timeRange']['start'] ?? 'N/A'),
              _buildInfoRow(
                  'End Time', _statistics!['timeRange']['end'] ?? 'N/A'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSampleDataCard() {
    if (_sampleData == null || _sampleData!.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No sample data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sample Data (First ${_sampleData!.length} records)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 300,
              child: ListView.builder(
                itemCount:
                    _sampleData!.length.clamp(0, 10), // Show max 10 for demo
                itemBuilder: (context, index) {
                  final candle = _sampleData![index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(
                        'O: \$${candle.open.toStringAsFixed(3)} | '
                        'H: \$${candle.high.toStringAsFixed(3)} | '
                        'L: \$${candle.low.toStringAsFixed(3)} | '
                        'C: \$${candle.close.toStringAsFixed(3)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      subtitle: Text(
                        'Time: ${candle.time} | Volume: ${candle.volume.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: candle.close >= candle.open
                            ? Colors.green
                            : Colors.red,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _loadSampleData,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload Data'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _repository.clearCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared')),
                  );
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Cache'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              // Example of loading latest 50 records
              try {
                setState(() => _isLoading = true);
                final latestData = await _repository.getLatestXAUUSDData(50);
                setState(() {
                  _sampleData = latestData;
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Loaded latest ${latestData.length} records')),
                );
              } catch (e) {
                setState(() {
                  _error = e.toString();
                  _isLoading = false;
                });
              }
            },
            icon: const Icon(Icons.timeline),
            label: const Text('Load Latest 50 Records'),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
