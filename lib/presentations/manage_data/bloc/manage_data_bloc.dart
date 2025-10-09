import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../services/local/dataset_cache_service.dart';
import '../../../repository/xauusd_repository.dart';
import '../../../di/di.dart';
part 'manage_data_event.dart';
part 'manage_data_state.dart';

class ManageDataBloc extends Bloc<ManageDataEvent, ManageDataState> {
  ManageDataBloc({required Box box, XauusdRepository? xauusdRepository})
      : _cache = DatasetCacheService(box),
        _xauusdRepository = xauusdRepository ?? getIt<XauusdRepository>(),
        super(ManageDataState.initial()) {
    on<ManageDataInitRequested>(_onInitRequested);
    on<ManageDataDownloadRequested>(_onDownloadRequested);
  }

  final DatasetCacheService _cache;
  final XauusdRepository _xauusdRepository;

  static const List<String> supportedSymbols = <String>[
    'EURUSD',
    'XAUUSD',
    'BTCUSD',
    'ETHUSD',
    'USDJPY',
    'GBPUSD',
  ];

  Future<void> _onInitRequested(
    ManageDataInitRequested event,
    Emitter<ManageDataState> emit,
  ) async {
    final Set<String> downloaded = <String>{};
    for (final symbol in supportedSymbols) {
      if (await _cache.isDownloaded(symbol)) {
        downloaded.add(symbol);
      }
    }
    emit(state.copyWith(downloadedSymbols: downloaded));
  }

  Future<void> _onDownloadRequested(
    ManageDataDownloadRequested event,
    Emitter<ManageDataState> emit,
  ) async {
    final String symbol = event.symbol;

    if (await _cache.isDownloaded(symbol)) {
      emit(state.copyWith(
        downloadedSymbols: {...state.downloadedSymbols, symbol},
        inProgressSymbol: null,
        errorMessage: null,
      ));
      return;
    }

    emit(state.copyWith(inProgressSymbol: symbol, errorMessage: null));

    try {
      final Map<String, dynamic> datasetJson = await _fetchDatasetJson(symbol);

      await _cache.cacheDatasetJson(symbol, datasetJson);
      await _cache.markDownloaded(symbol);

      final Set<String> updated = {...state.downloadedSymbols, symbol};
      emit(state.copyWith(downloadedSymbols: updated, inProgressSymbol: null));
    } catch (e) {
      emit(state.copyWith(inProgressSymbol: null, errorMessage: e.toString()));
    }
  }

  // This should call proper repository per symbol. For now, XAUUSD uses existing endpoint.
  Future<Map<String, dynamic>> _fetchDatasetJson(String symbol) async {
    if (symbol == 'XAUUSD') {
      final candles = await _xauusdRepository.fetchAllM1();
      final Map<String, dynamic> jsonMap = <String, dynamic>{
        'symbol': 'XAUUSD',
        'period': 'M1',
        'time': candles.map((c) => c.time.toIso8601String()).toList(),
        'open': candles.map((c) => c.open).toList(),
        'high': candles.map((c) => c.high).toList(),
        'low': candles.map((c) => c.low).toList(),
        'close': candles.map((c) => c.close).toList(),
        'volume': candles.map((c) => c.volume).toList(),
      };
      return jsonMap;
    }
    // Other symbols not implemented yet
    throw UnimplementedError('Download not supported for $symbol yet');
  }
}
