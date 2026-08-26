import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/services/auth_provider.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const IaiHorizonApp());
}

class IaiHorizonApp extends StatefulWidget {
  const IaiHorizonApp({super.key});

  @override
  State<IaiHorizonApp> createState() => _IaiHorizonAppState();
}

class _IaiHorizonAppState extends State<IaiHorizonApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();
    _router = buildAppRouter(_authProvider);
    // Tente de restaurer la session (token stocké de façon sécurisée) au démarrage.
    _authProvider.tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: _authProvider,
      child: MaterialApp.router(
        title: 'IAI Horizon',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.darkGreen, primary: AppColors.darkGreen, secondary: AppColors.gold),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(centerTitle: false),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}
