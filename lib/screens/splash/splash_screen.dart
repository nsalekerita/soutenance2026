import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

/// Écran affiché au lancement de l'app : logo qui tourne sur un fond
/// "professionnel" (dégradé vert institutionnel + touche or), avant de
/// rediriger automatiquement vers la page d'accueil (HomeScreen).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();

    // Après l'animation d'ouverture, on part vers la page d'accueil publique.
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) context.go('/');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.darkGreen, AppColors.darkGreenLight],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RotationTransition(
                turns: _controller,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16), // évite que le logo touche les bords
                  child: Image.asset(
                    'assets/image/logoIAI.jpg',
                    fit: BoxFit.contain,
                    // Si le logo n'est pas encore présent dans assets/image/,
                    // on retombe sur le texte "IAI" pour ne pas planter l'app.
                    errorBuilder: (_, __, ___) => const Text(
                      'IAI',
                      style: TextStyle(color: AppColors.gold, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                  children: [
                    TextSpan(text: 'IAI ', style: TextStyle(color: AppColors.white)),
                    TextSpan(text: 'Horizon', style: TextStyle(color: AppColors.gold)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Institut Africain d'Informatique — Cameroun",
                style: TextStyle(color: Color(0xFFD7E9DE), fontSize: 12),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}