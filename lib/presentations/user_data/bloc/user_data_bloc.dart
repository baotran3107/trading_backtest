import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../model/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';

part 'user_data_event.dart';
part 'user_data_state.dart';

class _UserDataStreamUpdated extends UserDataEvent {
  final UserModel? user;

  const _UserDataStreamUpdated(this.user);
}

@lazySingleton
class UserDataBloc extends Bloc<UserDataEvent, UserDataState> {
  final AuthService _authService;
  final UserService _userService;
  StreamSubscription<UserModel?>? _userStreamSub;
  StreamSubscription? _authSub;

  UserDataBloc(this._authService, this._userService)
      : super(UserDataInitial()) {
    on<UserDataStarted>(_onStarted);
    on<_UserDataStreamUpdated>(_onUserStreamUpdated);
    on<UserPreferencesUpdated>(_onPreferencesUpdated);
    on<UserDataCleared>(_onCleared);
  }

  Future<void> _onStarted(
    UserDataStarted event,
    Emitter<UserDataState> emit,
  ) async {
    emit(UserDataLoading());

    // Listen to auth changes and (re)wire the user stream accordingly
    _authSub?.cancel();
    _authSub = _authService.authStateChanges.listen((firebaseUser) async {
      await _userStreamSub?.cancel();
      if (firebaseUser == null) {
        add(UserDataCleared());
        return;
      }

      // Prime with the latest snapshot
      try {
        final model = await _userService.getUser(firebaseUser.uid) ??
            UserModel.fromFirebaseUser(firebaseUser);
        add(_UserDataStreamUpdated(model));
      } catch (e) {
        emit(UserDataError('Failed to load user: $e'));
      }

      // Subscribe for realtime updates
      _userStreamSub = _userService
          .getUserStream(firebaseUser.uid)
          .listen((user) => add(_UserDataStreamUpdated(user)));
    });
  }

  void _onUserStreamUpdated(
    _UserDataStreamUpdated event,
    Emitter<UserDataState> emit,
  ) {
    final user = event.user;
    if (user == null) {
      emit(UserDataEmpty());
    } else {
      emit(UserDataLoaded(user: user));
    }
  }

  Future<void> _onPreferencesUpdated(
    UserPreferencesUpdated event,
    Emitter<UserDataState> emit,
  ) async {
    final current = state;
    if (current is! UserDataLoaded) return;

    final updated = current.user.copyWith(preferences: event.preferences);
    try {
      await _userService.updateUser(updated);
      emit(UserDataLoaded(user: updated));
    } catch (e) {
      emit(UserDataError('Failed to update preferences: $e'));
      // restore previous state to avoid leaving error state permanently
      emit(current);
    }
  }

  Future<void> _onCleared(
    UserDataCleared event,
    Emitter<UserDataState> emit,
  ) async {
    await _userStreamSub?.cancel();
    emit(UserDataEmpty());
  }

  @override
  Future<void> close() async {
    await _userStreamSub?.cancel();
    await _authSub?.cancel();
    return super.close();
  }
}
