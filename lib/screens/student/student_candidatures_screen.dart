import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import 'student_postuler_screen.dart';

/// "Suivre sa progression" : liste des candidatures et leur statut.
class StudentCandidaturesScreen extends StatefulWidget {
  const StudentCandidaturesScreen({super.key});

  @override
  State<StudentCandidaturesScreen> createState() => _StudentCandidaturesScreenState();
}

class _StudentCandidaturesScreenState extends State<StudentCandidaturesScreen> {
  final _api = ApiClient.instance;
  List<dynamic> _candidatures = [];
  List<dynamic> _offresRecommandees = [];
  final _recommendationsKey = GlobalKey();
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
      final data = await _api.get('/candidatures/moi');
      if (!mounted) return;
      setState(() => _candidatures = data as List<dynamic>);
      try {
        final offres = await _api.get('/offres', auth: false);
        if (mounted && offres is List) {
          setState(() => _offresRecommandees = offres.take(3).toList());
        }
      } catch (_) {
        // Les recommandations ne bloquent pas le suivi des candidatures.
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
              ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    if (_candidatures.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sage),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: AppColors.sage,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.rocket_launch_outlined,
                        size: 30, color: AppColors.darkGreen),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ton parcours commence ici',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tu n’as pas encore envoyé de candidature. Découvre les opportunités qui correspondent à ton profil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, height: 1.45),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: () => _scrollToRecommendations(context),
                    icon: const Icon(Icons.search),
                    label: const Text('Voir les offres recommandées'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            KeyedSubtree(
              key: _recommendationsKey,
              child: const Text(
                'Opportunités pour toi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkGreen),
              ),
            ),
            const SizedBox(height: 12),
            if (_offresRecommandees.isEmpty)
              const Text('Aucune offre disponible pour le moment.', style: TextStyle(color: AppColors.textMuted))
            else
              ..._offresRecommandees.map((offre) => _recommendationCard(context, offre)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _candidatures.length,
      itemBuilder: (context, i) {
        final c = _candidatures[i];
        final offre = c['offres'];
        final statut = c['statut'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offre?['titre'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      Text(offre?['entreprises']?['nom'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
      },
    );
  }

  void _scrollToRecommendations(BuildContext context) {
    final target = _recommendationsKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Widget _recommendationCard(BuildContext context, dynamic offre) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(offre['titre'] ?? 'Opportunité',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 5),
          Text(
            '${offre['entreprises']?['nom'] ?? 'Entreprise'} · ${offre['localisation'] ?? 'Localisation non précisée'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(offre['type'] == 'stage' ? 'Stage' : 'Emploi',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentPostulerScreen(offre: offre)),
                ),
                child: const Text('Postuler'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
