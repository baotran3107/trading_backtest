// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:trade_lab/presentations/user_data/bloc/user_data_bloc.dart'
    as _i965;
import 'package:trade_lab/services/api/api_client.dart' as _i342;
import 'package:trade_lab/services/api/api_module.dart' as _i571;
import 'package:trade_lab/services/auth_service.dart' as _i138;
import 'package:trade_lab/services/user_service.dart' as _i446;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final apiModule = _$ApiModule();
    gh.lazySingleton<_i138.AuthService>(() => _i138.AuthService());
    gh.lazySingleton<_i342.ApiClient>(() => apiModule.apiClient());
    gh.lazySingleton<_i446.UserService>(() => _i446.UserService());
    gh.lazySingleton<_i965.UserDataBloc>(() => _i965.UserDataBloc(
          gh<_i138.AuthService>(),
          gh<_i446.UserService>(),
        ));
    return this;
  }
}

class _$ApiModule extends _i571.ApiModule {}
