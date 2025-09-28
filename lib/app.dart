import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentations/welcome_screen/welcome_screen.dart';
import 'presentations/auth/auth_screen.dart';
import 'presentations/auth/bloc/auth_bloc.dart';
import 'presentations/main_navigation/main_navigation.dart';
import 'repository/trading_data_repository.dart';
import 'presentations/backtest_screen/bloc/backtest_bloc.dart';
import 'services/auth_service.dart';
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
        RepositoryProvider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<BacktestBloc>(
            create: (context) => BacktestBloc(
              context.read<TradingDataRepository>(),
            )..add(const BacktestInitialized()),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authService: context.read<AuthService>(),
            )..add(AuthCheckRequested()),
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
                home: const AppInitializer(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _welcomeCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkWelcomeStatus();
  }

  Future<void> _checkWelcomeStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final welcomeCompleted = prefs.getBool('welcome_completed') ?? false;

      if (mounted) {
        setState(() {
          _welcomeCompleted = welcomeCompleted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _welcomeCompleted = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If welcome not completed, show welcome screen
    if (!_welcomeCompleted) {
      return const WelcomeScreen();
    }

    // If welcome completed, check authentication
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (state is AuthAuthenticated) {
          return const MainNavigation();
        }

        if (state is AuthUnauthenticated) {
          return const AuthScreen();
        }

        if (state is AuthError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Authentication Error',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthCheckRequested());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return const AuthScreen();
      },
    );
  }
}
