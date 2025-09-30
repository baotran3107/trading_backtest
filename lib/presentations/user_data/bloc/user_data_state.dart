part of 'user_data_bloc.dart';

abstract class UserDataState extends Equatable {
  const UserDataState();

  @override
  List<Object?> get props => [];
}

class UserDataInitial extends UserDataState {}

class UserDataLoading extends UserDataState {}

class UserDataLoaded extends UserDataState {
  final UserModel user;

  const UserDataLoaded({required this.user});

  @override
  List<Object?> get props => [user];
}

class UserDataEmpty extends UserDataState {}

class UserDataError extends UserDataState {
  final String message;

  const UserDataError(this.message);

  @override
  List<Object?> get props => [message];
}
