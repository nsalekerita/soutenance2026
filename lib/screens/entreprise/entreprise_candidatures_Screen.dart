import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';
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
  State<EntrepriseCandidaturesScreen> createState() =>
      _EntrepriseCandidaturesScreenState();
}

class _EntrepriseCandidaturesScreenState
    extends State<EntrepriseCandidaturesScreen> {
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
      final data =
          await ApiClient.instance.get('/candidatures/offre/${widget.offreId}');
      if (!mounted) return;
      setState(() {
        _candidatures = data is List<dynamic> ? data : <dynamic>[];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyApiError(e))),
      );
    }
  }

  Future<void> _accepter(String candidatureId) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accepter la candidature ?'),
        content: const Text(
            'Cette action est définitive et l\'étudiant en sera informé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Accepter', style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _actionEnCours.add(candidatureId));
    try {
      await ApiClient.instance
          .patch('/candidatures/$candidatureId/accepter', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Candidature acceptée.')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
      }
    } finally {
      if (mounted) setState(() => _actionEnCours.remove(candidatureId));
    }
  }

  Future<void> _refuser(String candidatureId) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Refuser la candidature ?'),
        content: const Text(
            'Cette action est définitive et l\'étudiant en sera informé.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refuser', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirme != true) return;

    setState(() => _actionEnCours.add(candidatureId));
    try {
      await ApiClient.instance
          .patch('/candidatures/$candidatureId/refuser', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Candidature refusée.')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
      }
    } finally {
      if (mounted) setState(() => _actionEnCours.remove(candidatureId));
    }
  }

  void _contacter(dynamic candidature) {
    final etudiant = candidature['etudiants'] ?? candidature['etudiant'] ?? {};
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntrepriseChatScreen(
          etudiantId: (etudiant['id'] ?? candidature['etudiant_id']).toString(),
          etudiantNom: etudiant['nom_complet'] ??
                  '${etudiant['prenom'] ?? ''} ${etudiant['nom'] ?? ''}'
                          .trim() !=
                      ''
              ? '${etudiant['prenom'] ?? ''} ${etudiant['nom'] ?? ''}'.trim()
              : 'Étudiant',
        ),
      ),
    );
  }

  Color _statutColor(String? statut) {
    switch (statut) {
      case 'acceptee':
      case 'acceptée':
        return AppColors.success;
      case 'refusee':
      case 'refusée':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Color _statutBackground(String? statut) {
    switch (statut) {
      case 'acceptee':
      case 'acceptée':
        return AppColors.successBackground;
      case 'refusee':
      case 'refusée':
        return AppColors.errorBackground;
      default:
        return AppColors.warningBackground;
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
                      const Text('Aucune candidature reçue pour le moment.',
                          style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: _load, child: const Text('Rafraîchir')),
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
                      final etudiant = c['etudiants'] ?? c['etudiant'] ?? {};
                      final statut = c['statut']?.toString() ?? 'en_attente';
                      final enCours = _actionEnCours.contains(id);
                      final enAttente =
                          statut == 'en_attente' || statut == 'envoyee';

                      String nomCandidat = 'Candidat';
                      if (etudiant['nom'] != null ||
                          etudiant['prenom'] != null) {
                        nomCandidat =
                            '${etudiant['prenom'] ?? ''} ${etudiant['nom'] ?? ''}'
                                .trim();
                      } else if (etudiant['nom_complet'] != null) {
                        nomCandidat = etudiant['nom_complet'];
                      }
                      if (nomCandidat.isEmpty) nomCandidat = 'Candidat';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    nomCandidat,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark),
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
                            const SizedBox(height: 8),
                            if (c['filiere'] != null ||
                                etudiant['filiere'] != null)
                              Text(
                                  'Filière: ${c['filiere'] ?? etudiant['filiere']}',
                                  style: const TextStyle(fontSize: 13)),
                            if (c['niveau_etudes'] != null)
                              Text('Niveau: ${c['niveau_etudes']}',
                                  style: const TextStyle(fontSize: 13)),
                            if (c['universite'] != null)
                              Text('École: ${c['universite']}',
                                  style: const TextStyle(fontSize: 13)),
                            const Divider(height: 24),
                            const Text('Pièces jointes :',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                if (c['cv_url'] != null)
                                  _fileButton('CV', c['cv_url']),
                                if (c['lettre_motivation_url'] != null)
                                  _fileButton('LM', c['lettre_motivation_url']),
                                if (c['releve_notes_url'] != null)
                                  _fileButton('Notes', c['releve_notes_url']),
                                if (c['lettre_recommandation_url'] != null)
                                  _fileButton(
                                      'Rec.', c['lettre_recommandation_url']),
                                if (c['cni_url'] != null)
                                  _fileButton('CNI', c['cni_url']),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _showDetails(c),
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('Détails'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _contacter(c),
                                  icon: const Icon(Icons.chat_bubble_outline,
                                      size: 18),
                                  label: const Text('Discuter'),
                                ),
                                if (enAttente) ...[
                                  OutlinedButton.icon(
                                    onPressed:
                                        enCours ? null : () => _refuser(id),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.error),
                                    icon: const Icon(Icons.close, size: 18),
                                    label: const Text('Refuser'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed:
                                        enCours ? null : () => _accepter(id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.darkGreen,
                                      foregroundColor: AppColors.white,
                                    ),
                                    icon: enCours
                                        ? const SizedBox(
                                            height: 14,
                                            width: 14,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2),
                                          )
                                        : const Icon(Icons.check, size: 18),
                                    label: const Text('Accepter'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  void _showDetails(dynamic c) {
    final etudiant = c['etudiants'] ?? c['etudiant'] ?? {};
    final nomCandidat =
        '${c['prenom'] ?? etudiant['prenom'] ?? ''} ${c['nom'] ?? etudiant['nom'] ?? ''}'
                    .trim() !=
                ''
            ? '${c['prenom'] ?? etudiant['prenom'] ?? ''} ${c['nom'] ?? etudiant['nom'] ?? ''}'
                .trim()
            : 'Candidat';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Détails de la candidature - $nomCandidat'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width < 640
              ? MediaQuery.of(context).size.width * 0.85
              : 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailSection(
                    'Informations Personnelles',
                    'Genre: ${c['genre'] ?? 'Non précisé'}\n'
                        'Né(e) le: ${c['date_naissance'] ?? 'Non précisé'}\n'
                        'Nationalité: ${c['nationalite'] ?? 'Non précisée'}\n'
                        'Adresse: ${c['adresse_complete'] ?? 'Non précisée'}'),
                const SizedBox(height: 16),
                _detailSection(
                    'Informations Académiques',
                    'Université: ${c['universite'] ?? 'Non précisée'}\n'
                        'Filière: ${c['filiere'] ?? 'Non précisée'}\n'
                        'Niveau: ${c['niveau_etudes'] ?? 'Non précisé'} (${c['annee_etude'] ?? ''})'),
                const SizedBox(height: 16),
                _detailSection('Motivation / Message',
                    c['message'] ?? 'Aucun message fourni.'),
                const SizedBox(height: 16),
                _detailSection(
                    'Disponibilité',
                    'Début: ${c['date_disponibilite'] ?? 'Non précisée'}\n'
                        'Durée: ${c['duree_souhaitee'] ?? 'Non précisée'}'),
                const SizedBox(height: 16),
                _detailSection(
                    'Contact',
                    'Email: ${c['email'] ?? 'Non fourni'}\n'
                        'Tél: ${c['telephone_contact'] ?? 'Non fourni'}'),
                const SizedBox(height: 16),
                const Text('Documents joints',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (c['cv_url'] != null) _fileButton('CV', c['cv_url']),
                    if (c['lettre_motivation_url'] != null)
                      _fileButton(
                          'Lettre de motivation', c['lettre_motivation_url']),
                    if (c['releve_notes_url'] != null)
                      _fileButton('Relevé de notes', c['releve_notes_url']),
                    if (c['lettre_recommandation_url'] != null)
                      _fileButton('Lettre de recommandation',
                          c['lettre_recommandation_url']),
                    if (c['cni_url'] != null) _fileButton('CNI', c['cni_url']),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Widget _detailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
        const SizedBox(height: 4),
        Text(content, style: const TextStyle(height: 1.4)),
      ],
    );
  }

  Widget _fileButton(String label, String url) {
    return ActionChip(
      avatar: const Icon(Icons.picture_as_pdf, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impossible d\'ouvrir le fichier')),
            );
          }
        }
      },
    );
  }
}
