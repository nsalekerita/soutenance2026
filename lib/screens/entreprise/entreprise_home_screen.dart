import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import 'entreprise_candidatures_Screen.dart';

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
    setState(() => _loading = true);
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
      debugPrint('Erreur chargement home entreprise: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

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
          Row(
            children: [
              Expanded(child: _statCard('Offres actives', '${_stats['offres_actives']}', Icons.work_outline, AppColors.darkGreen)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Candidats', '${_stats['total_candidatures']}', Icons.people_outline, AppColors.gold)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('À traiter', '${_stats['nouvelles_candidatures']}', Icons.notification_important_outlined, Colors.orange)),
            ],
          ),
          const SizedBox(height: 24),

          // Actions rapides
          const Text('Actions rapides', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen, fontSize: 15)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickAction(
                  Icons.add_circle_outline,
                  'Publier',
                  'Nouvelle offre',
                  () => widget.onNavigate(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickAction(
                  Icons.list_alt_outlined,
                  'Mes offres',
                  'Gérer le contenu',
                  () => widget.onNavigate(1),
                ),
              ),
            ],
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

  Widget _statCard(String label, String value, IconData icon, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    ),
  );

  Widget _quickAction(IconData icon, String title, String subtitle, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.sage, child: Icon(icon, color: AppColors.darkGreen, size: 20)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
              Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _candidatureTile(dynamic c) {
    final statut = c['statut'] ?? 'en_attente';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.gold.withOpacity(0.2),
          child: Text((c['nom'] ?? '?')[0].toUpperCase(), style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        ),
        title: Text('${c['nom']} ${c['prenom']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Poste: ${c['offres']?['titre'] ?? 'N/A'}', style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (statut == 'en_attente' ? Colors.orange : AppColors.darkGreen).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statut,
            style: TextStyle(
              fontSize: 10,
              color: statut == 'en_attente' ? Colors.orange : AppColors.darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
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
    );
  }
}
