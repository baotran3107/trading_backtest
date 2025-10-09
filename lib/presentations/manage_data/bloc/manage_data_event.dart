part of 'manage_data_bloc.dart';

abstract class ManageDataEvent extends Equatable {
  const ManageDataEvent();

  @override
  List<Object?> get props => [];
}

class ManageDataInitRequested extends ManageDataEvent {}

class ManageDataDownloadRequested extends ManageDataEvent {
  const ManageDataDownloadRequested(this.symbol);

  final String symbol;

  @override
  List<Object?> get props => [symbol];
}
