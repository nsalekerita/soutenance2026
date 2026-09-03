import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// Écran "Accueil" du dashboard étudiant.
/// Regroupe : message de bienvenue, avancement du profil, statistiques de
/// candidatures et accès rapides vers les autres fonctionnalités
/// (Test d'orientation, Assistant IA, Offres, Mes candidatures).
class StudentHomeScreen extends StatefulWidget {
  /// Permet de changer l'onglet actif du [StudentDashboardScreen] parent.
  final void Function(int index) onNavigate;

  const StudentHomeScreen({super.key, required this.onNavigate});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _api = ApiClient.instance;

  Map<String, dynamic>? _profil;
  List<dynamic> _candidatures = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.get('/profils/moi'),
        _api.get('/candidatures/moi'),
      ]);
      setState(() {
        _profil = results[0] as Map<String, dynamic>;
        _candidatures = results[1] as List<dynamic>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Calcule un pourcentage d'avancement du profil à partir des informations
  /// disponibles. À enrichir si d'autres champs (photo, filière, CV...) sont
  /// exposés par l'API.
  double _completionProfil() {
    final etudiant = _profil?['etudiant'] as Map<String, dynamic>?;
    final competences = (_profil?['competences'] as List?) ?? [];
    final interets = (_profil?['interets'] as List?) ?? [];

    final criteres = <bool>[
      (etudiant?['niveau'] as String?)?.isNotEmpty ?? false,
      (etudiant?['prenom'] as String?)?.isNotEmpty ?? false,
      competences.isNotEmpty,
      interets.isNotEmpty,
    ];
    final remplis = criteres.where((c) => c).length;
    return remplis / criteres.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Erreur: $_error', style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    final etudiant = _profil?['etudiant'];
    final prenom = etudiant?['prenom'] ?? '';
    final completion = _completionProfil();

    final total = _candidatures.length;
    final enAttente = _candidatures.where((c) => (c['statut'] ?? 'en_attente') == 'en_attente').length;
    final acceptees = _candidatures.where((c) => c['statut'] == 'acceptee').length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // --- En-tête de bienvenue ---
          Text(
            'Bonjour${prenom.toString().isNotEmpty ? ', $prenom' : ''} ',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            'Voici un aperçu de ton espace orientation.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // --- Avancement du profil ---
          _card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Complétude du profil',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 15)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: completion,
                          minHeight: 8,
                          color: AppColors.gold,
                          backgroundColor: AppColors.cardGrey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('${(completion * 100).round()}% complété',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => widget.onNavigate(1),
                  child: const Text('Compléter'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- Statistiques de candidatures ---
          Row(
            children: [
              Expanded(child: _statCard('Candidatures', '$total', Icons.assignment_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('En attente', '$enAttente', Icons.hourglass_empty)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Acceptées', '$acceptees', Icons.check_circle_outline)),
            ],
          ),
          const SizedBox(height: 24),

          // --- Accès rapides ---
          const Text('Accès rapides',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen, fontSize: 15)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _quickAction(Icons.quiz_outlined, "Test d'orientation",
                  "Découvre les filières qui te correspondent", () => widget.onNavigate(2)),
              _quickAction(Icons.smart_toy_outlined, 'Assistant IA',
                  'Pose tes questions sur ton orientation', () => widget.onNavigate(3)),
              _quickAction(Icons.work_outline, 'Offres',
                  'Consulte les stages et emplois disponibles', () => widget.onNavigate(4)),
              _quickAction(Icons.assignment_turned_in_outlined, 'Mes candidatures',
                  'Suis l\'état de tes candidatures', () => widget.onNavigate(5)),
            ],
          ),
          const SizedBox(height: 24),

          // --- Candidatures récentes ---
          if (_candidatures.isNotEmpty) ...[
            const Text('Candidatures récentes',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen, fontSize: 15)),
            const SizedBox(height: 12),
            for (final c in _candidatures.take(3)) _candidatureTile(c),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );

  Widget _statCard(String label, String value, IconData icon) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.darkGreen, size: 20),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    ),
  );

  Widget _quickAction(IconData icon, String title, String subtitle, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.gold, size: 22),
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
          Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    ),
  );

  Color _statutColor(String statut) {
    switch (statut) {
      case 'acceptee':
        return AppColors.darkGreen;
      case 'refusee':
        return Colors.red;
      case 'vue':
        return AppColors.gold;
      default:
        return AppColors.textMuted;
    }
  }

  Widget _candidatureTile(dynamic c) {
    final offre = c['offres'];
    final statut = c['statut'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offre?['titre'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                Text(offre?['entreprises']?['nom'] ?? '',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Chip(
            label: Text(statut, style: TextStyle(color: _statutColor(statut), fontSize: 11, fontWeight: FontWeight.w600)),
            backgroundColor: _statutColor(statut).withOpacity(0.12),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
