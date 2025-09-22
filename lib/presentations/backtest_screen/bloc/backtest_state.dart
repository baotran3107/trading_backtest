part of 'backtest_bloc.dart';

class BacktestState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<CandleStick>? allData;
  final List<CandleStick> visibleCandles;
  final int
      currentPointer; // index within allData representing next candle boundary
  final bool isPlaying;
  final int startIndex; // window start in allData
  final int endIndex; // window end in allData (exclusive)

  const BacktestState({
    required this.isLoading,
    required this.errorMessage,
    required this.allData,
    required this.visibleCandles,
    required this.currentPointer,
    required this.isPlaying,
    required this.startIndex,
    required this.endIndex,
  });

  const BacktestState.initial()
      : isLoading = false,
        errorMessage = null,
        allData = null,
        visibleCandles = const [],
        currentPointer = 0,
        isPlaying = false,
        startIndex = 0,
        endIndex = 0;

  BacktestState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CandleStick>? allData,
    List<CandleStick>? visibleCandles,
    int? currentPointer,
    bool? isPlaying,
    int? startIndex,
    int? endIndex,
  }) {
    return BacktestState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      allData: allData ?? this.allData,
      visibleCandles: visibleCandles ?? this.visibleCandles,
      currentPointer: currentPointer ?? this.currentPointer,
      isPlaying: isPlaying ?? this.isPlaying,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        allData,
        visibleCandles,
        currentPointer,
        isPlaying,
        startIndex,
        endIndex,
      ];
}
