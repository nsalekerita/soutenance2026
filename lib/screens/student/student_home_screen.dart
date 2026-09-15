import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

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
      if (!mounted) return;
      setState(() {
        _profil = results[0] as Map<String, dynamic>;
        _candidatures = results[1] as List<dynamic>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _statCard('Candidatures', '$total', Icons.assignment_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('En attente', '$enAttente', Icons.hourglass_empty)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Acceptées', '$acceptees', Icons.check_circle_outline)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- Accès rapides ---
          const Text('Accès rapides',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen, fontSize: 15)),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _quickAction(Icons.quiz_outlined, "Test d'orientation",
                    "Découvre les filières qui te correspondent", () => widget.onNavigate(2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(Icons.work_outline, 'Offres',
                    'Consulte les stages et emplois disponibles', () => widget.onNavigate(4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _quickAction(Icons.assignment_turned_in_outlined, 'Mes candidatures',
            'Suis l\'état de tes candidatures', () => widget.onNavigate(5)),
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

  Widget _card({required Widget child}) => AppCard(child: child);

  Widget _statCard(String label, String value, IconData icon) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.darkGreen, size: 20),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
        ),
        const SizedBox(height: 2),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    ),
  );

  Widget _quickAction(IconData icon, String title, String subtitle, VoidCallback onTap) => AppCard(
    padding: const EdgeInsets.all(14),
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20),
        ),
        const SizedBox(height: 10),
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
        const SizedBox(height: 4),
        Flexible(
          child: Text(subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ),
      ],
    ),
  );

  Color _statutColor(String statut) {
    switch (statut) {
      case 'acceptee':
        return AppColors.success;
      case 'refusee':
        return AppColors.error;
      case 'vue':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  Color _statutBackground(String statut) {
    switch (statut) {
      case 'acceptee':
        return AppColors.successBackground;
      case 'refusee':
        return AppColors.errorBackground;
      case 'vue':
        return AppColors.warningBackground;
      default:
        return AppColors.background;
    }
  }

  Widget _candidatureTile(dynamic c) {
    final offre = c['offres'];
    final statut = c['statut'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(offre?['titre'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark)),
                  Text(offre?['entreprises']?['nom'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(
              label: statut,
              color: _statutColor(statut),
              background: _statutBackground(statut),
            ),
          ],
        ),
      ),
    );
  }
}
