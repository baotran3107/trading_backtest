import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentations/main_navigation/main_navigation.dart';
import 'repository/trading_data_repository.dart';
import 'presentations/backtest_screen/bloc/backtest_bloc.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<TradingDataRepository>(
          create: (_) => TradingDataRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BacktestBloc>(
            create: (context) => BacktestBloc(
              context.read<TradingDataRepository>(),
            )..add(const BacktestInitialized()),
          ),
        ],
        child: MaterialApp(
          title: 'Trading Game',
          theme: AppTheme.darkTheme,
          home: const MainNavigation(),
        ),
      ),
    );
  }
}
