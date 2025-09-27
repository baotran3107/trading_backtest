import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'presentations/main_navigation/main_navigation.dart';
import 'repository/trading_data_repository.dart';
import 'presentations/backtest_screen/bloc/backtest_bloc.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

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
        child: ChangeNotifierProvider(
          create: (context) => ThemeProvider()..initializeTheme(),
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                title: 'Trading Game',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,
                home: const MainNavigation(),
              );
            },
          ),
        ),
      ),
    );
  }
}
