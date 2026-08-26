import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

/// Écran de choix du profil pour l'inscription ou la connexion.
/// L'utilisateur peut choisir entre Étudiant et Entreprise.
class AuthChoiceScreen extends StatelessWidget {
  final String? preselectedRole;

  const AuthChoiceScreen({
    super.key,
    this.preselectedRole,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700;

    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          'Rejoindre IAI Horizon',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xE60E3B2E),
              Color(0xD90E3B2E),
              Color(0xF20E3B2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),
                child: isWide
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.school_outlined,
                        title: 'Étudiant',
                        description:
                        'Trouve ta filière idéale et tes opportunités de stage.',
                        role: 'etudiant',
                        iconBackground: AppColors.sage,
                      ),
                    ),
                    const SizedBox(width: 24),
                    const _VerticalHorizon(),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _RoleCard(
                        icon: Icons.apartment_outlined,
                        title: 'Entreprise',
                        description:
                        'Publie tes offres et trouve les bons profils.',
                        role: 'entreprise',
                        iconBackground: AppColors.goldTint,
                      ),
                    ),
                  ],
                )
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _RoleCard(
                      icon: Icons.school_outlined,
                      title: 'Étudiant',
                      description:
                      'Trouve ta filière idéale et tes opportunités de stage.',
                      role: 'etudiant',
                      iconBackground: AppColors.sage,
                    ),
                    const SizedBox(height: 24),
                    const _HorizontalHorizon(),
                    const SizedBox(height: 24),
                    _RoleCard(
                      icon: Icons.apartment_outlined,
                      title: 'Entreprise',
                      description:
                      'Publie tes offres et trouve les bons profils.',
                      role: 'entreprise',
                      iconBackground: AppColors.goldTint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalHorizon extends StatelessWidget {
  const _VerticalHorizon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 220,
      child: Container(
        color: AppColors.gold,
      ),
    );
  }
}

class _HorizontalHorizon extends StatelessWidget {
  const _HorizontalHorizon();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.gold,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final String role;
  final Color iconBackground;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.role,
    required this.iconBackground,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.identity()
          ..scale(_hovered ? 1.02 : 1.0),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? AppColors.gold
                : AppColors.cardGrey,
            width: _hovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: _hovered ? 28 : 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: widget.iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                size: 32,
                color: AppColors.darkGreen,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.go(
                    '/auth/register?role=${widget.role}',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                context.go('/auth/login');
              },
              child: const Text(
                'Déjà un compte ? Se connecter',
                style: TextStyle(
                  color: AppColors.darkGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
