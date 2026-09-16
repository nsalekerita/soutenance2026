import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import 'entreprise_candidatures_screen.dart';

/// Écran d'accueil de l'espace Entreprise.
/// Résumé des activités : offres actives, candidatures reçues, et accès rapides.
class EntrepriseHomeScreen extends StatefulWidget {
  final void Function(int index) onNavigate;

  const EntrepriseHomeScreen({super.key, required this.onNavigate});

  @override
  State<EntrepriseHomeScreen> createState() => _EntrepriseHomeScreenState();
}

class _EntrepriseHomeScreenState extends State<EntrepriseHomeScreen> {
  final _api = ApiClient.instance;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _stats = {
    'offres_actives': 0,
    'total_candidatures': 0,
    'nouvelles_candidatures': 0,
  };
  List<dynamic> _recentCandidatures = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Dans un vrai projet, on ferait un endpoint /entreprises/stats
      // Ici on simule ou on déduit des offres
      final offres = await _api.get('/offres/entreprise/mes-offres');
      final allCandidatures = [];
      int nouvelles = 0;

      if (offres is List) {
        for (var o in offres) {
          final cands = await _api.get('/candidatures/offre/${o['id']}');
          if (cands is List) {
            allCandidatures.addAll(cands);
            nouvelles += cands.where((c) => c['statut'] == 'en_attente').length;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _stats = {
          'offres_actives': (offres as List).length,
          'total_candidatures': allCandidatures.length,
          'nouvelles_candidatures': nouvelles,
        };
        // Trier par date décroissante et prendre les 5 dernières
        allCandidatures.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
        _recentCandidatures = allCandidatures.take(5).toList();
      });
    } catch (e) {
      setState(() => _error = friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadData, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Tableau de bord Entreprise ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Suivez vos recrutements et gérez vos offres en un coup d\'œil.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Cartes statistiques
          LayoutBuilder(
            builder: (context, constraints) {
              final cards = [
                _statCard('Offres actives', '${_stats['offres_actives']}', Icons.work_outline, AppColors.darkGreen),
                _statCard('Candidats', '${_stats['total_candidatures']}', Icons.people_outline, AppColors.gold),
                _statCard('À traiter', '${_stats['nouvelles_candidatures']}', Icons.notification_important_outlined, AppColors.warning),
              ];
              final columns = constraints.maxWidth < 520 ? 1 : 3;
              return GridView.count(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: columns == 1 ? 3.5 : 1.05,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: cards,
              );
            },
          ),
          const SizedBox(height: 24),

          // Actions rapides
          const Text('Actions rapides', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen, fontSize: 15)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              crossAxisCount: constraints.maxWidth < 420 ? 1 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: constraints.maxWidth < 420 ? 4.2 : 2.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _quickAction(Icons.add_circle_outline, 'Publier', 'Nouvelle offre', () => widget.onNavigate(2)),
                _quickAction(Icons.list_alt_outlined, 'Mes offres', 'Gérer le contenu', () => widget.onNavigate(1)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Candidatures récentes
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Candidatures récentes', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen, fontSize: 15)),
              TextButton(onPressed: () => widget.onNavigate(1), child: const Text('Voir tout')),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentCandidatures.isEmpty)
            const Center(child: Text('Aucune candidature pour le moment.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)))
          else
            ..._recentCandidatures.map((c) => _candidatureTile(c)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    ),
  );

  Widget _quickAction(IconData icon, String title, String subtitle, VoidCallback onTap) => AppCard(
    padding: const EdgeInsets.all(14),
    onTap: onTap,
    child: Row(
      children: [
        CircleAvatar(backgroundColor: AppColors.sage, child: Icon(icon, color: AppColors.darkGreen, size: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
              Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _candidatureTile(dynamic c) {
    final statut = c['statut'] ?? 'en_attente';
    final isEnAttente = statut == 'en_attente';
    final statutColor = isEnAttente ? AppColors.warning : AppColors.success;
    final statutBackground = isEnAttente ? AppColors.warningBackground : AppColors.successBackground;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.gold.withOpacity(0.2),
          child: Text((c['nom'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        ),
        title: Text('${c['nom']} ${c['prenom']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Poste: ${c['offres']?['titre'] ?? 'N/A'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
        trailing: StatusBadge(label: statut, color: statutColor, background: statutBackground),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EntrepriseCandidaturesScreen(
                offreId: c['offre_id'].toString(),
                offreTitre: c['offres']?['titre'] ?? '',
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}
