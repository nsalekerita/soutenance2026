import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

/// Onglet "Accueil" du dashboard administrateur : statistiques globales de
/// la plateforme et accès rapides vers les autres onglets.
class AdminStatsScreen extends StatefulWidget {
  final void Function(int index) onNavigate;

  const AdminStatsScreen({super.key, required this.onNavigate});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  Map<String, dynamic>? _stats;
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
      final stats = await ApiClient.instance.get('/admin/stats');
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Parse une valeur de stat qui peut arriver en int, double ou String depuis l'API.
  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final s = _stats ?? {};
    final int nbEtudiants = _asInt(s['nbEtudiants']);
    final int nbEntreprises = _asInt(s['nbEntreprises']);
    final int nbOffres = _asInt(s['nbOffres']);
    final int nbCandidatures = _asInt(s['nbCandidatures']);
    final int maxVal = [nbEtudiants, nbEntreprises, nbOffres, nbCandidatures]
        .fold(1, (a, b) => b > a ? b : a); // évite division par zéro

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            "Vue d'ensemble",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          const Text(
            "Suivez l'activité de la plateforme et gérez les offres et les comptes.",
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.92,
            children: [
              _statCard(
                  icon: Icons.school_outlined,
                  label: 'Étudiants',
                  value: nbEtudiants,
                  color: AppColors.statTeal,
                  maxVal: maxVal),
              _statCard(
                  icon: Icons.apartment_outlined,
                  label: 'Entreprises',
                  value: nbEntreprises,
                  color: AppColors.darkGreen,
                  maxVal: maxVal),
              _statCard(
                  icon: Icons.work_outline,
                  label: 'Offres Total',
                  value: nbOffres,
                  color: AppColors.gold,
                  maxVal: maxVal),
              _statCard(
                  icon: Icons.forum_outlined,
                  label: 'Candidatures',
                  value: nbCandidatures,
                  color: AppColors.statPlum,
                  maxVal: maxVal),
            ],
          ),
          const SizedBox(height: 28),
          const Text('Actions rapides',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGreen,
                  fontSize: 15)),
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
                _quickAction(Icons.list_alt_outlined, 'Offres à valider', 'Approuver ou rejeter', () => widget.onNavigate(1)),
                _quickAction(Icons.people_outline, 'Comptes', 'Gérer les utilisateurs', () => widget.onNavigate(2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
          IconData icon, String title, String subtitle, VoidCallback onTap) =>
      AppCard(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
                backgroundColor: AppColors.sage,
                child: Icon(icon, color: AppColors.darkGreen, size: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.textDark)),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _statCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required int maxVal,
  }) {
    final double ratio = maxVal == 0 ? 0 : (value / maxVal).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau de couleur en haut, propre à la catégorie
          Container(height: 4, color: color),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '$value',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 10),
                // Barre de proportion : représente la part de cette catégorie
                // par rapport à la plus grande valeur des 4 statistiques.
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
