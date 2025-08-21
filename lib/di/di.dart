import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:trading_game/di/di.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
