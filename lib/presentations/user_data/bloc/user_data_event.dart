part of 'user_data_bloc.dart';

abstract class UserDataEvent extends Equatable {
  const UserDataEvent();

  @override
  List<Object?> get props => [];
}

class UserDataStarted extends UserDataEvent {}

class UserDataCleared extends UserDataEvent {}

class UserPreferencesUpdated extends UserDataEvent {
  final Map<String, dynamic> preferences;

  const UserPreferencesUpdated(this.preferences);

  @override
  List<Object?> get props => [preferences];
}
