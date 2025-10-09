import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'bloc/manage_data_bloc.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class ManageDataScreen extends StatefulWidget {
  const ManageDataScreen({super.key});

  @override
  State<ManageDataScreen> createState() => _ManageDataScreenState();
}

class _ManageDataScreenState extends State<ManageDataScreen> {
  final List<_Instrument> _instruments = const [
    _Instrument(
        symbol: 'EURUSD', displayName: 'Euro / US Dollar', color: Colors.blue),
    _Instrument(
        symbol: 'XAUUSD', displayName: 'Gold / US Dollar', color: Colors.amber),
    _Instrument(
        symbol: 'BTCUSD',
        displayName: 'Bitcoin / US Dollar',
        color: Colors.orange),
    _Instrument(
        symbol: 'ETHUSD',
        displayName: 'Ethereum / US Dollar',
        color: Colors.deepPurple),
    _Instrument(
        symbol: 'USDJPY',
        displayName: 'US Dollar / Japanese Yen',
        color: Colors.green),
    _Instrument(
        symbol: 'GBPUSD',
        displayName: 'British Pound / US Dollar',
        color: Colors.indigo),
  ];

  String? _downloadingSymbol;
  final Set<String> _downloaded = <String>{};

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Manage Data'),
        elevation: 0,
      ),
      body: BlocProvider(
        create: (context) => ManageDataBloc(box: Hive.box('datasets'))
          ..add(ManageDataInitRequested()),
        child: SafeArea(
          child: BlocConsumer<ManageDataBloc, ManageDataState>(
            listener: (context, state) {
              setState(() {
                _downloadingSymbol = state.inProgressSymbol;
                _downloaded
                  ..clear()
                  ..addAll(state.downloadedSymbols);
              });
              if (state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
              }
            },
            builder: (context, state) {
              return Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(child: _buildInstrumentList(context)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenMargin),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Available Datasets', style: AppTextStyles.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pick one or more instruments to download historical data.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenMargin),
      itemCount: _instruments.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final instrument = _instruments[index];
        final isDownloading = _downloadingSymbol == instrument.symbol;
        final isDownloaded = _downloaded.contains(instrument.symbol);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            onTap: isDownloaded
                ? null
                : () {
                    context
                        .read<ManageDataBloc>()
                        .add(ManageDataDownloadRequested(instrument.symbol));
                  },
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.borderLight,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: instrument.color.withValues(alpha: 0.15),
                    child: Text(
                      instrument.symbol.substring(0, 1),
                      style: TextStyle(color: instrument.color),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instrument.symbol,
                          style: AppTextStyles.titleMedium.copyWith(
                            color:
                                isDownloaded ? AppColors.textSecondary : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          instrument.displayName,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _buildDownloadButton(
                    instrument.symbol,
                    isDownloading,
                    isDownloaded,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadButton(
      String symbol, bool isDownloading, bool isDownloaded) {
    final bool isAnotherDownloading =
        _downloadingSymbol != null && _downloadingSymbol != symbol;
    if (isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    if (isDownloaded) {
      return const Icon(
        Icons.check_circle,
        color: AppColors.textTertiary,
      );
    }
    return IconButton(
      onPressed: isAnotherDownloading
          ? null
          : () {
              context
                  .read<ManageDataBloc>()
                  .add(ManageDataDownloadRequested(symbol));
            },
      icon: const Icon(Icons.download),
      color: AppColors.primary,
      tooltip: 'Download',
    );
  }
}

class _Instrument {
  final String symbol;
  final String displayName;
  final Color color;
  const _Instrument(
      {required this.symbol, required this.displayName, required this.color});
}
