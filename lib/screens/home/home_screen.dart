import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../core/services/api_client.dart';

/// Page d'accueil publique de la plateforme IAI Horizon.
/// Désormais dynamique : charge les dernières offres et annonces depuis le backend.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = ApiClient.instance;
  final _scrollController = ScrollController();
  final _heroKey = GlobalKey();
  final _annoncesKey = GlobalKey();
  List<dynamic> _recentOffres = [];
  bool _loading = true;
  int _totalJobs = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // On récupère les offres publiques
      final data = await _api.get('/offres', auth: false);
      if (mounted && data is List) {
        setState(() {
          _recentOffres = data.take(3).toList();
          _totalJobs = data.length;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement home publique: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 900;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(isWide: isWide),
                _NavBar(
                  isWide: isWide,
                  onAccueil: () => _scrollTo(_heroKey),
                  onOffres: () => _scrollTo(_annoncesKey),
                ),
                KeyedSubtree(key: _heroKey, child: _HeroSection(isWide: isWide)),
                _ExploreSection(isWide: isWide, totalJobs: _totalJobs),
                KeyedSubtree(
                  key: _annoncesKey,
                  child: _AnnouncementsSection(isWide: isWide, offres: _recentOffres, loading: _loading),
                ),
                _JoinSection(isWide: isWide),
                _Footer(isWide: isWide),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------------
// BARRE SUPERIEURE
// ------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  final bool isWide;
  const _TopBar({required this.isWide});
  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 520;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 12),
      child: isCompact
          ? const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_InstituteLogo(), _HorizonWordmark()],
                ),
                SizedBox(height: 12),
                _SearchBar(),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: isWide ? 3 : 2,
                  child: const Align(alignment: Alignment.centerLeft, child: _InstituteLogo()),
                ),
                Expanded(
                  flex: isWide ? 4 : 3,
                  child: const Center(child: _HorizonWordmark()),
                ),
                Expanded(
                  flex: isWide ? 3 : 2,
                  child: const _SearchBar(),
                ),
              ],
            ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardGrey),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Rechercher une filière...',
                hintStyle: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizonWordmark extends StatelessWidget {
  const _HorizonWordmark();
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.5),
            children: [
              TextSpan(text: 'IAI ', style: TextStyle(color: AppColors.darkGreen)),
              TextSpan(text: 'Horizon', style: TextStyle(color: AppColors.gold)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 3,
          width: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.darkGreen, AppColors.gold]),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _InstituteLogo extends StatelessWidget {
  const _InstituteLogo();
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(6)),
          alignment: Alignment.center,
          child: const Text('IAI', style: TextStyle(color: AppColors.gold, fontSize: 8, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        const Flexible(
          child: Text(
            "Institut Africain\nd'Informatique",
            maxLines: 2,
            style: TextStyle(fontSize: 8, color: AppColors.textMuted, height: 1.2),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------------
// MENU DE NAVIGATION
// ------------------------------------------------------------------------
class _NavBar extends StatelessWidget {
  final bool isWide;
  final VoidCallback onAccueil;
  final VoidCallback onOffres;
  const _NavBar({required this.isWide, required this.onAccueil, required this.onOffres});
  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem('Accueil', onAccueil),
      _NavItem('Offres & stages', onOffres),
    ];
    return Container(
      color: AppColors.darkGreen,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 8, vertical: 10),
      child: isWide
          ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...items,
          const SizedBox(width: 32),
          const _LanguageAction(),
          const SizedBox(width: 16),
          _AuthAction(label: 'Se connecter', filled: false, onTap: () => context.go('/auth/login')),
          const SizedBox(width: 12),
          _AuthAction(label: "S'inscrire", filled: true, onTap: () => context.go('/auth')),
        ],
      )
          // Sur mobile : un seul bouton d'action reste visible (S'inscrire, le CTA
          // principal). Accueil, Offres et Se connecter passent dans le menu
          // hamburger pour que rien ne soit jamais coupé ou caché par un scroll.
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.menu, color: AppColors.white),
            color: AppColors.white,
            onSelected: (callback) => callback(),
            itemBuilder: (context) => [
              PopupMenuItem(value: onAccueil, child: const Text('Accueil')),
              PopupMenuItem(value: onOffres, child: const Text('Offres & stages')),
              PopupMenuItem(value: () => context.go('/auth/login'), child: const Text('Se connecter')),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LanguageAction(),
              const SizedBox(width: 6),
              _AuthAction(label: "S'inscrire", filled: true, compact: true, onTap: () => context.go('/auth')),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sélecteur de langue (UI uniquement pour l'instant : l'app n'a pas encore
/// de système de traduction intl/ARB, donc "English" affiche une notice au
/// lieu de traduire silencieusement une partie seulement de l'app).
class _LanguageAction extends StatelessWidget {
  const _LanguageAction();
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.white,
      tooltip: 'Langue',
      onSelected: (lang) {
        if (lang == 'en') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('English version coming soon.')),
          );
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'fr', child: Text('Français')),
        PopupMenuItem(value: 'en', child: Text('English')),
      ],
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, color: AppColors.white, size: 18),
            SizedBox(width: 2),
            Text('FR', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavItem(this.label, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: onTap,
        child: Text(label, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _AuthAction extends StatelessWidget {
  final String label;
  final bool filled;
  final bool compact;
  final VoidCallback onTap;
  const _AuthAction({required this.label, required this.filled, required this.onTap, this.compact = false});
  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.darkGreen,
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: TextStyle(fontSize: compact ? 12 : 13, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      );
    }
    return TextButton(
      onPressed: onTap,
      style: compact ? TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6)) : null,
      child: Text(label, style: TextStyle(color: AppColors.gold, fontSize: compact ? 12 : 13, fontWeight: FontWeight.w600)),
    );
  }
}

// ------------------------------------------------------------------------
// SECTION 1 : HERO
// ------------------------------------------------------------------------
class _HeroSection extends StatelessWidget {
  final bool isWide;
  const _HeroSection({required this.isWide});
  @override
  Widget build(BuildContext context) {
    final textBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PLATEFORME INTELLIGENTE IAI-CAMEROUN',
          style: TextStyle(color: AppColors.gold, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        const Text(
          "Bienvenue sur la plateforme mobile intelligente basée sur l'intelligence artificielle",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.darkGreen, height: 1.3),
        ),
        const SizedBox(height: 14),
        const Text(
          "Conçue pour accompagner les étudiants de l'Institut Africain d'Informatique (IAI-Cameroun) "
              "dans leur orientation académique et leur insertion professionnelle. Grâce à des recommandations "
              "personnalisées, elle aide chaque étudiant à choisir sa filière selon son profil.",
          style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.6),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: () => context.go('/auth'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Commencer'),
            ),
            OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkGreen,
                side: const BorderSide(color: AppColors.darkGreen),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('En savoir plus'),
            ),
          ],
        ),
      ],
    );
    final imageBlock = Container(
      height: isWide ? 320 : 200,
      decoration: BoxDecoration(
        color: AppColors.sage,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkGreen.withOpacity(0.1)),
        image: const DecorationImage(
          image: AssetImage('assets/image/imgyde.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: isWide ? 48 : 28),
      child: isWide
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 6, child: textBlock),
          const SizedBox(width: 40),
          Expanded(flex: 5, child: imageBlock),
        ],
      )
          : Column(children: [textBlock, const SizedBox(height: 24), imageBlock]),
    );
  }
}

// ------------------------------------------------------------------------
// SECTION 2 : GRID EXPLORE
// ------------------------------------------------------------------------
class _ExploreSection extends StatelessWidget {
  final bool isWide;
  final int totalJobs;
  const _ExploreSection({required this.isWide, required this.totalJobs});
  @override
  Widget build(BuildContext context) {
    final cards = [
      _ExploreCard(
        icon: Icons.location_city,
        title: 'Emplois disponibles',
        subtitle: '$totalJobs opportunités professionnelles sont actuellement listées sur la plateforme.',
      ),
      const _ExploreCard(
        icon: Icons.work_outline,
        title: 'Lieux & stages',
        subtitle: "Trouvez les entreprises partenaires qui accueillent des stagiaires dans votre domaine.",
      ),
      const _ExploreCard(
        icon: Icons.explore_outlined,
        title: 'Conseil & orientation',
        subtitle: "L'IA analyse votre profil pour vous proposer la filière qui vous correspond le mieux.",
      ),
    ];
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: isWide ? 40 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Explorez la plateforme',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
          const SizedBox(height: 20),
          isWide
              ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList(),
          )
              : Column(children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 16), child: c)).toList()),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ExploreCard({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardGrey.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.sage, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.darkGreen, size: 30),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// SECTION 3 : ANNONCES (DYNAMIQUE)
// ------------------------------------------------------------------------
class _AnnouncementsSection extends StatelessWidget {
  final bool isWide;
  final List<dynamic> offres;
  final bool loading;
  const _AnnouncementsSection({required this.isWide, required this.offres, required this.loading});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: isWide ? 40 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Annonces récentes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
          const SizedBox(height: 4),
          const Text("Stages et offres d'emploi mis à jour en temps réel",
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 20),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (offres.isEmpty)
            const Center(child: Text("Aucune annonce récente."))
          else
            isWide
                ? Row(children: offres.map((a) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: _Announcement(offre: a)))).toList())
                : Column(children: offres.map((a) => Padding(padding: const EdgeInsets.only(bottom: 16), child: _Announcement(offre: a))).toList()),
        ],
      ),
    );
  }
}

class _Announcement extends StatelessWidget {
  final dynamic offre;
  const _Announcement({required this.offre});
  @override
  Widget build(BuildContext context) {
    final bool isStage = offre['type'] == 'stage';
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardGrey.withOpacity(0.6))),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 100, color: AppColors.sage, child: const Icon(Icons.work, color: AppColors.darkGreen, size: 30)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isStage ? AppColors.badgeStage : AppColors.badgeEmploi,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isStage ? 'Stage' : 'Emploi',
                    style: TextStyle(fontSize: 10, color: isStage ? AppColors.darkGreen : AppColors.badgeEmploiText, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Text(offre['titre'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(offre['localisation'] ?? 'Cameroun',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// SECTION 4 : APPEL A L'INSCRIPTION
// ------------------------------------------------------------------------
class _JoinSection extends StatelessWidget {
  final bool isWide;
  const _JoinSection({required this.isWide});
  @override
  Widget build(BuildContext context) {
    final joinCards = [
      _JoinCard(icon: Icons.school_outlined, text: "Inscris-toi si tu es étudiant(e)", onTap: () => context.go('/auth?role=etudiant')),
      _JoinCard(icon: Icons.apartment_outlined, text: 'Inscris-toi si tu es une entreprise', onTap: () => context.go('/auth?role=entreprise'))
    ];
    return Container(
      color: AppColors.darkGreen,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: isWide ? 44 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rejoins la communauté IAI Horizon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white)),
          const SizedBox(height: 4),
          const Text('Quel que soit ton profil, la plateforme a été pensée pour toi', style: TextStyle(fontSize: 13, color: AppColors.mutedOnDark)),
          const SizedBox(height: 20),
          isWide
              ? Row(children: joinCards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: c))).toList())
              : Column(children: joinCards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList()),
        ],
      ),
    );
  }
}

class _JoinCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _JoinCard({required this.icon, required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.gold, size: 30),
          const SizedBox(height: 10),
          Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.white, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gold,
              side: const BorderSide(color: AppColors.gold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("S'inscrire", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------------
// FOOTER
// ------------------------------------------------------------------------
class _Footer extends StatelessWidget {
  final bool isWide;
  const _Footer({required this.isWide});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.footerBackground,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IAI Horizon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gold)),
          const SizedBox(height: 10),
          const Text(
            "Plateforme intelligente d'orientation et d'insertion professionnelle pour l'IAI-Cameroun.",
            style: TextStyle(fontSize: 12, color: AppColors.footerText, height: 1.6),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.footerDivider),
          const SizedBox(height: 12),
          const Text(
            "© 2026 IAI Horizon — Institut Africain d'Informatique, Cameroun. Tous droits réservés.",
            style: TextStyle(fontSize: 11, color: AppColors.footerTextMuted),
          ),
        ],
      ),
    );
  }
}
