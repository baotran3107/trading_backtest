part of 'manage_data_bloc.dart';

class ManageDataState extends Equatable {
  const ManageDataState({
    required this.downloadedSymbols,
    this.inProgressSymbol,
    this.errorMessage,
  });

  final Set<String> downloadedSymbols;
  final String? inProgressSymbol;
  final String? errorMessage;

  bool get isBusy => inProgressSymbol != null;

  ManageDataState copyWith({
    Set<String>? downloadedSymbols,
    String? inProgressSymbol,
    String? errorMessage,
  }) {
    return ManageDataState(
      downloadedSymbols: downloadedSymbols ?? this.downloadedSymbols,
      inProgressSymbol: inProgressSymbol,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [downloadedSymbols, inProgressSymbol, errorMessage];

  factory ManageDataState.initial() => const ManageDataState(
        downloadedSymbols: <String>{},
      );
}
