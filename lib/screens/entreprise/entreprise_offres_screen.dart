import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
import 'entreprise_candidatures_screen.dart';
import 'entreprise_publier_screen.dart';

/// Liste des offres de l'entreprise + accès aux candidatures reçues + gestion (edit/delete).
class EntrepriseOffresScreen extends StatefulWidget {
  const EntrepriseOffresScreen({super.key});

  @override
  State<EntrepriseOffresScreen> createState() => _EntrepriseOffresScreenState();
}

class _EntrepriseOffresScreenState extends State<EntrepriseOffresScreen> {
  List<dynamic> _offres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ApiClient.instance.get('/offres/entreprise/mes-offres');
      if (!mounted) return;
      setState(() => _offres = data is List<dynamic> ? data : <dynamic>[]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _supprimerOffre(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'offre"),
        content: const Text("Es-tu sûr de vouloir supprimer cette offre ? Cette action est irréversible."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Annuler")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    try {
      await ApiClient.instance.delete('/offres/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Offre supprimée")));
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
    }
  }

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'validee':
      case 'validée':
        return AppColors.success;
      case 'refusee':
      case 'refusée':
        return AppColors.error;
      case 'en_attente':
      default:
        return AppColors.warning;
    }
  }

  Color _statutBackground(String? statut) {
    switch (statut) {
      case 'validee':
      case 'validée':
        return AppColors.successBackground;
      case 'refusee':
      case 'refusée':
        return AppColors.errorBackground;
      case 'en_attente':
      default:
        return AppColors.warningBackground;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_offres.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Tu n'as pas encore publié d'offre.", style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Rafraîchir')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _offres.length,
        itemBuilder: (context, i) {
          final o = _offres[i];
          final nbCandidatures = o['nb_candidatures'] ?? o['nombreCandidatures'];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(o['titre'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: '${o['statut']}',
                      color: _statutColor(o['statut']),
                      background: _statutBackground(o['statut']),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (o['localisation'] != null)
                  Text(o['localisation'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EntreprisePublierScreen(initialData: o),
                          ),
                        );
                        if (result == true) _load();
                      },
                      icon: const Icon(Icons.edit_outlined, color: AppColors.info, size: 20),
                      tooltip: "Modifier",
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _supprimerOffre(o['id'].toString()),
                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                      tooltip: "Supprimer",
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EntrepriseCandidaturesScreen(
                              offreId: o['id'].toString(),
                              offreTitre: o['titre'] ?? '',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.people_alt_outlined, size: 18),
                      label: Text(nbCandidatures != null ? 'Candidats ($nbCandidatures)' : 'Candidats'),
                    ),
                  ],
                ),
              ],
            ),
            ),
          );
        },
      ),
    );
  }
}
