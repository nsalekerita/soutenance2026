import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import 'entreprise_chat_screen.dart';

/// Affiche la liste de tous les étudiants ayant postulé aux offres de l'entreprise.
class EntrepriseEtudiantsScreen extends StatefulWidget {
  const EntrepriseEtudiantsScreen({super.key});

  @override
  State<EntrepriseEtudiantsScreen> createState() => _EntrepriseEtudiantsScreenState();
}

class _EntrepriseEtudiantsScreenState extends State<EntrepriseEtudiantsScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _candidatures = [];
  List<dynamic> _filtres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filtrer);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_filtrer);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      // On récupère toutes les candidatures liées à cette entreprise
      final data = await ApiClient.instance.get('/candidatures/tous');
      if (!mounted) return;
      setState(() {
        _candidatures = data is List<dynamic> ? data : <dynamic>[];
        _filtres = _candidatures;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filtrer() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtres = _candidatures;
        return;
      }
      _filtres = _candidatures.where((c) {
        final etudiant = c['etudiants'] ?? {};
        final offre = c['offres'] ?? {};
        final nom = '${etudiant['prenom'] ?? ''} ${etudiant['nom'] ?? ''}'.toLowerCase();
        final titreOffre = (offre['titre'] ?? '').toString().toLowerCase();
        return nom.contains(q) || titreOffre.contains(q);
      }).toList();
    });
  }

  void _voirProfil(dynamic candidature) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfilCandidatSheet(candidature: candidature),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher un candidat ou une offre...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtres.isEmpty
                  ? const Center(child: Text('Aucun candidat trouvé.', style: TextStyle(color: AppColors.textMuted)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: _filtres.length,
                        itemBuilder: (context, i) {
                          final c = _filtres[i];
                          final e = c['etudiants'] ?? {};
                          final o = c['offres'] ?? {};
                          final nom = '${e['prenom'] ?? ''} ${e['nom'] ?? ''}'.trim();
                          final statut = c['statut'] ?? 'en_attente';

                          return InkWell(
                            onTap: () => _voirProfil(c),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppColors.darkGreen.withOpacity(0.1),
                                    child: Text(
                                      nom.isNotEmpty ? nom.substring(0, 1).toUpperCase() : '?',
                                      style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nom.isNotEmpty ? nom : 'Étudiant',
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                                        ),
                                        Text(
                                          'A postulé pour : ${o['titre'] ?? 'Offre inconnue'}',
                                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _statutColor(statut).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            statut.toUpperCase(),
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _statutColor(statut)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'acceptee': return Colors.green;
      case 'refusee': return Colors.red;
      case 'envoyee': return Colors.blue;
      default: return Colors.orange;
    }
  }
}

class _ProfilCandidatSheet extends StatelessWidget {
  final dynamic candidature;
  const _ProfilCandidatSheet({required this.candidature});

  @override
  Widget build(BuildContext context) {
    final e = candidature['etudiants'] ?? {};
    final o = candidature['offres'] ?? {};
    final nom = '${e['prenom'] ?? ''} ${e['nom'] ?? ''}'.trim();

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF5F7F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text(nom.isNotEmpty ? nom : 'Étudiant', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text(e['filiere'] ?? 'Filière non précisée', style: const TextStyle(color: AppColors.textMuted)),
              const Divider(height: 32),
              _item('Offre concernée', o['titre'] ?? 'Inconnue'),
              _item('Statut actuel', candidature['statut'] ?? 'En attente'),
              if (candidature['message'] != null && candidature['message'].toString().isNotEmpty)
                _item('Message d\'accompagnement', candidature['message']),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Gestion robuste : Supabase peut renvoyer un objet ou une liste pour la jointure
                        final etudiantRaw = candidature['etudiants'];
                        final etudiant = (etudiantRaw is List && etudiantRaw.isNotEmpty) 
                            ? etudiantRaw.first 
                            : (etudiantRaw is Map ? etudiantRaw : {});
                        
                        final userId = etudiant['user_id'];
                        
                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Erreur : Identifiant utilisateur introuvable pour ce candidat.'))
                          );
                          return;
                        }

                        Navigator.pop(context);
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => EntrepriseChatScreen(
                            etudiantId: userId.toString(),
                            etudiantNom: nom,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Contacter'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white),
                      child: const Text('Fermer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
