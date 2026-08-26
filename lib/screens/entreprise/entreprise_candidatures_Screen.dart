import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import 'entreprise_chat_screen.dart';

/// Candidatures reçues pour une offre donnée : l'entreprise peut examiner
/// chaque candidature, l'accepter ou la refuser, et contacter (discuter
/// avec) l'étudiant.
class EntrepriseCandidaturesScreen extends StatefulWidget {
  final String offreId;
  final String offreTitre;

  const EntrepriseCandidaturesScreen({
    super.key,
    required this.offreId,
    required this.offreTitre,
  });

  @override
  State<EntrepriseCandidaturesScreen> createState() => _EntrepriseCandidaturesScreenState();
}

class _EntrepriseCandidaturesScreenState extends State<EntrepriseCandidaturesScreen> {
  List<dynamic> _candidatures = [];
  bool _loading = true;
  final Set<String> _actionEnCours = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // Adapter la route à ton API : liste des candidatures pour une offre.
      final data = await ApiClient.instance.get('/offres/${widget.offreId}/candidatures');
      if (!mounted) return;
      setState(() => _candidatures = data is List<dynamic> ? data : <dynamic>[]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accepter(String candidatureId) async {
    setState(() => _actionEnCours.add(candidatureId));
    try {
      await ApiClient.instance.post('/candidatures/$candidatureId/accepter', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidature acceptée.')));
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _actionEnCours.remove(candidatureId));
    }
  }

  Future<void> _refuser(String candidatureId) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la candidature ?'),
        content: const Text('Cette action est définitive et l\'étudiant en sera informé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refuser', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _actionEnCours.add(candidatureId));
    try {
      await ApiClient.instance.post('/candidatures/$candidatureId/refuser', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidature refusée.')));
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _actionEnCours.remove(candidatureId));
    }
  }

  void _contacter(dynamic candidature) {
    final etudiant = candidature['etudiant'] ?? {};
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntrepriseChatScreen(
          etudiantId: (etudiant['id'] ?? candidature['etudiant_id']).toString(),
          etudiantNom: etudiant['nom_complet'] ?? etudiant['nom'] ?? 'Étudiant',
        ),
      ),
    );
  }

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'acceptee':
      case 'acceptée':
        return Colors.green;
      case 'refusee':
      case 'refusée':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Candidatures — ${widget.offreTitre}'),
        backgroundColor: AppColors.darkGreen,
        foregroundColor: AppColors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _candidatures.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Aucune candidature reçue pour le moment.', style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      TextButton(onPressed: _load, child: const Text('Rafraîchir')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _candidatures.length,
                    itemBuilder: (context, i) {
                      final c = _candidatures[i];
                      final id = c['id'].toString();
                      final etudiant = c['etudiant'] ?? {};
                      final statut = c['statut']?.toString() ?? 'en_attente';
                      final enCours = _actionEnCours.contains(id);
                      final enAttente = statut == 'en_attente';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    etudiant['nom_complet'] ?? etudiant['nom'] ?? 'Candidat',
                                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statutColor(statut).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    statut,
                                    style: TextStyle(fontSize: 12, color: _statutColor(statut), fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            if (etudiant['formation'] != null) ...[
                              const SizedBox(height: 4),
                              Text(etudiant['formation'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _contacter(c),
                                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                  label: const Text('Discuter'),
                                ),
                                if (enAttente) ...[
                                  OutlinedButton.icon(
                                    onPressed: enCours ? null : () => _refuser(id),
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Refuser'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: enCours ? null : () => _accepter(id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkGreen,
                                      foregroundColor: AppColors.white,
                                    ),
                                    icon: enCours
                                        ? const SizedBox(
                                            height: 14,
                                            width: 14,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Icon(Icons.check, size: 18),
                                    label: const Text('Accepter'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}