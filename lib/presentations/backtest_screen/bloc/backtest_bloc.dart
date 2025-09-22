import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../model/candle_model.dart';
import '../../../repository/trading_data_repository.dart';

part 'backtest_event.dart';
part 'backtest_state.dart';

class BacktestBloc extends Bloc<BacktestEvent, BacktestState> {
  final TradingDataRepository _repository;
  Timer? _timer;

  BacktestBloc(this._repository) : super(const BacktestState.initial()) {
    on<BacktestInitialized>(_onInitialized);
    on<BacktestPlayToggled>(_onPlayToggled);
    on<BacktestStepNext>(_onStepNext);
    on<BacktestStepBack>(_onStepBack);
    on<_BacktestTick>(_onTick);
  }

  Future<void> _onInitialized(
    BacktestInitialized event,
    Emitter<BacktestState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, errorMessage: null));
      final allData = await _repository.getAllXAUUSDData();

      // Start from middle like current screen does so scrolling room exists
      final total = allData.length;
      final centerIndex = total ~/ 2;
      final initialWindow = 10;
      final startIndex = (centerIndex - initialWindow).clamp(0, total);
      final endIndex = centerIndex.clamp(0, total);
      final visible = allData.sublist(startIndex, endIndex);

      emit(state.copyWith(
        isLoading: false,
        allData: allData,
        visibleCandles: visible,
        currentPointer: endIndex,
        startIndex: startIndex,
        endIndex: endIndex,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load data: $e',
      ));
    }
  }

  void _onPlayToggled(
    BacktestPlayToggled event,
    Emitter<BacktestState> emit,
  ) {
    final shouldPlay = !(state.isPlaying);
    emit(state.copyWith(isPlaying: shouldPlay));

    _timer?.cancel();
    if (shouldPlay) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        add(const _BacktestTick());
      });
    }
  }

  void _onTick(
    _BacktestTick event,
    Emitter<BacktestState> emit,
  ) {
    _advance(emit, 1);
  }

  void _onStepNext(
    BacktestStepNext event,
    Emitter<BacktestState> emit,
  ) {
    _advance(emit, 1);
  }

  void _onStepBack(
    BacktestStepBack event,
    Emitter<BacktestState> emit,
  ) {
    _advance(emit, -1);
  }

  void _advance(Emitter<BacktestState> emit, int delta) {
    final data = state.allData;
    if (data == null || data.isEmpty) return;

    int newPointer = state.currentPointer + delta;
    newPointer = newPointer.clamp(0, data.length);

    // If reached bounds, stop playing
    if (newPointer == state.currentPointer) return;
    if (newPointer == 0 || newPointer == data.length) {
      _timer?.cancel();
      emit(state.copyWith(isPlaying: false));
    }

    // Maintain a sliding window for visible candles
    int startIndex = state.startIndex;
    int endIndex = state.endIndex;

    if (delta > 0) {
      // move forward: add next candle by extending endIndex up to newPointer
      if (newPointer > endIndex) {
        endIndex = newPointer;
      }
      // keep window size around 1000
      if (endIndex - startIndex > 1000) {
        startIndex = endIndex - 1000;
      }
    } else if (delta < 0) {
      // move backward: remove current last candle by shrinking endIndex
      if (newPointer < endIndex) {
        endIndex = newPointer;
      }
      // if pointer goes before start, slide window left
      if (newPointer < startIndex) {
        startIndex = newPointer;
      }
      if (endIndex < startIndex) {
        endIndex = startIndex;
      }
    }

    final visible = data.sublist(startIndex, endIndex);
    emit(state.copyWith(
      visibleCandles: visible,
      currentPointer: newPointer,
      startIndex: startIndex,
      endIndex: endIndex,
    ));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
