import 'package:go_router/go_router.dart';

import '../services/auth_provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/auth/auth_choice_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/otp_verify_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/student/student_dashboard_screen.dart';
import '../../screens/entreprise/entreprise_dashboard_screen.dart';
import '../../screens/admin/administrateur_dashboard_screen.dart';
import '../../screens/notifications/notifications_screen.dart';

/// Construit le routeur de l'app. `authProvider` est passé pour permettre au
/// router de se rafraîchir automatiquement (refreshListenable) quand l'état
/// de connexion change (ex: après login/logout), sans redémarrer l'app.
GoRouter buildAppRouter(AuthProvider authProvider) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash';
      final atPublicHome = state.matchedLocation == '/';

      // Pendant le chargement initial (tryAutoLogin), on ne redirige pas encore.
      if (authProvider.loading) return null;

      final isAuthenticated = authProvider.isAuthenticated;

      // Si connecté mais sur une page publique/auth -> redirige vers son dashboard.
      if (isAuthenticated &&
          (loggingIn || atPublicHome) &&
          state.matchedLocation != '/splash') {
        switch (authProvider.user?.role) {
          case UserRole.etudiant:
            return '/etudiant';
          case UserRole.entreprise:
            return '/entreprise';
          case UserRole.administrateur:
            return '/administrateur';
          case null:
            return null;
        }
      }

      // Si non connecté et qu'on tente d'accéder à un dashboard protégé -> accueil.
      final protectedPrefixes = [
        '/etudiant',
        '/entreprise',
        '/administrateur',
        '/notifications'
      ];
      if (!isAuthenticated &&
          protectedPrefixes.any((p) => state.matchedLocation.startsWith(p))) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
          path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/auth',
        builder: (context, state) => AuthChoiceScreen(
            preselectedRole: state.uri.queryParameters['role']),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => RegisterScreen(
            role: state.uri.queryParameters['role'] ?? 'etudiant'),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) =>
            OtpVerifyScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: '/auth/mot-de-passe-oublie',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
          path: '/etudiant',
          builder: (context, state) => const StudentDashboardScreen()),
      GoRoute(
          path: '/entreprise',
          builder: (context, state) => const EntrepriseDashboardScreen()),
      GoRoute(
          path: '/administrateur',
          builder: (context, state) => const AdministrateurDashboardScreen()),
      GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen()),
    ],
  );
}
