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
  List<dynamic> _recentOffres = [];
  bool _loading = true;
  int _totalJobs = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // On récupère les offres publiques
      final data = await _api.get('/offres', auth: false);
      if (data is List) {
        setState(() {
          _recentOffres = data.take(3).toList();
          _totalJobs = data.length;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement home publique: $e');
    } finally {
      setState(() => _loading = false);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(isWide: isWide),
                _NavBar(isWide: isWide),
                _HeroSection(isWide: isWide),
                _ExploreSection(isWide: isWide, totalJobs: _totalJobs),
                _AnnouncementsSection(isWide: isWide, offres: _recentOffres, loading: _loading),
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
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 12),
      child: Row(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Expanded(child: _SearchBar()),
                const SizedBox(width: 12),
                if (isWide) const _LanguageSwitcher(),
              ],
            ),
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

class _LanguageSwitcher extends StatelessWidget {
  const _LanguageSwitcher();
  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: 'FR',
        icon: const Icon(Icons.keyboard_arrow_down, size: 16),
        style: const TextStyle(fontSize: 12, color: AppColors.darkGreen, fontWeight: FontWeight.w600),
        items: const [
          DropdownMenuItem(value: 'FR', child: Text('Français')),
          DropdownMenuItem(value: 'EN', child: Text('English')),
        ],
        onChanged: (_) {},
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
  const _NavBar({required this.isWide});
  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      const _NavItem('Accueil'),
      const _NavItem('À propos'),
      const _NavItem('Offres & stages'),
      const _NavItem('Orientation métiers'),
    ];
    return Container(
      color: AppColors.darkGreen,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 12, vertical: 10),
      child: isWide
          ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...items,
          const SizedBox(width: 32),
          _AuthAction(label: 'Se connecter', filled: false, onTap: () => context.go('/auth/login')),
          const SizedBox(width: 12),
          _AuthAction(label: "S'inscrire", filled: true, onTap: () => context.go('/auth')),
        ],
      )
          : SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...items,
            const SizedBox(width: 16),
            _AuthAction(label: 'Se connecter', filled: false, onTap: () => context.go('/auth/login')),
            const SizedBox(width: 8),
            _AuthAction(label: "S'inscrire", filled: true, onTap: () => context.go('/auth')),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  const _NavItem(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: InkWell(
        onTap: () {},
        child: Text(label, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _AuthAction extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _AuthAction({required this.label, required this.filled, required this.onTap});
  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.darkGreen,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      );
    }
    return TextButton(
      onPressed: onTap,
      child: Text(label, style: const TextStyle(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w600)),
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
        Row(
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
            const SizedBox(width: 12),
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
                    color: isStage ? const Color(0xFFEAF3DE) : const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isStage ? 'Stage' : 'Emploi',
                    style: TextStyle(fontSize: 10, color: isStage ? AppColors.darkGreen : const Color(0xFF04342C), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 8),
                Text(offre['titre'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(offre['localisation'] ?? 'Cameroun', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
          const Text('Quel que soit ton profil, la plateforme a été pensée pour toi', style: TextStyle(fontSize: 13, color: Color(0xFFD7E9DE))),
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
      color: const Color(0xFF2C2C2A),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('IAI Horizon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.gold)),
          const SizedBox(height: 10),
          const Text(
            "Plateforme intelligente d'orientation et d'insertion professionnelle pour l'IAI-Cameroun.",
            style: TextStyle(fontSize: 12, color: Color(0xFFB4B2A9), height: 1.6),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFF444441)),
          const SizedBox(height: 12),
          const Text(
            "© 2026 IAI Horizon — Institut Africain d'Informatique, Cameroun. Tous droits réservés.",
            style: TextStyle(fontSize: 11, color: Color(0xFF888780)),
          ),
        ],
      ),
    );
  }
}
