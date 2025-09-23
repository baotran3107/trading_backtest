import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentations/backtest_screen/backtest_screen.dart';
import 'presentations/data_import_example/data_import_example.dart';
import 'repository/trading_data_repository.dart';
import 'presentations/backtest_screen/bloc/backtest_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('app startedd');

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
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const MainMenu(),
        ),
      ),
    );
  }
}

class MainMenu extends StatelessWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Trading Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.trending_up,
              size: 100,
              color: Colors.amber,
            ),
            const SizedBox(height: 32),
            const Text(
              'Trading Game',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose an option to get started',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BackTestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.show_chart),
                label: const Text('Back Test'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 250,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DataImportExample(),
                    ),
                  );
                },
                icon: const Icon(Icons.data_usage),
                label: const Text('XAUUSD Data Import'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
