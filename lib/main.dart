import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/services/auth_provider.dart';
import 'core/services/push_notification_service.dart';
import 'theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    await PushNotificationService.instance.init();
  } catch (e) {
    debugPrint('Initialisation Firebase impossible: $e');
  }
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
          colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.darkGreen,
              primary: AppColors.darkGreen,
              secondary: AppColors.gold),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textDark,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: AppColors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          cardTheme: CardThemeData(
            color: AppColors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.cardGrey),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGreen,
              side: const BorderSide(color: AppColors.darkGreen),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: AppColors.darkGreen),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: AppColors.sage,
            labelStyle: const TextStyle(
                color: AppColors.darkGreen, fontWeight: FontWeight.w600),
            selectedColor: AppColors.darkGreen,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide.none,
          ),
          dividerTheme:
              const DividerThemeData(color: AppColors.cardGrey, thickness: 1),
          textTheme: const TextTheme(
            headlineSmall: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.bold),
            titleMedium: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(color: AppColors.textDark),
            bodyMedium: TextStyle(color: AppColors.textDark),
            bodySmall: TextStyle(color: AppColors.textMuted),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}
