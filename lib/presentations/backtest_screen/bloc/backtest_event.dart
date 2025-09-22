part of 'backtest_bloc.dart';

abstract class BacktestEvent extends Equatable {
  const BacktestEvent();
  @override
  List<Object?> get props => [];
}

class BacktestInitialized extends BacktestEvent {
  const BacktestInitialized();
}

class BacktestPlayToggled extends BacktestEvent {
  const BacktestPlayToggled();
}

class BacktestStepNext extends BacktestEvent {
  const BacktestStepNext();
}

class BacktestStepBack extends BacktestEvent {
  const BacktestStepBack();
}

class _BacktestTick extends BacktestEvent {
  const _BacktestTick();
}
