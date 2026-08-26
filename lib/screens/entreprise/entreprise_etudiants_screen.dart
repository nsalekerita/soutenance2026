import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// Permet à l'entreprise de consulter les profils des étudiants
/// (compétences, formation, centres d'intérêt, expériences) afin
/// d'identifier les candidats correspondant à ses besoins.
class EntrepriseEtudiantsScreen extends StatefulWidget {
  const EntrepriseEtudiantsScreen({super.key});

  @override
  State<EntrepriseEtudiantsScreen> createState() => _EntrepriseEtudiantsScreenState();
}

class _EntrepriseEtudiantsScreenState extends State<EntrepriseEtudiantsScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _etudiants = [];
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
      // Adapter la route à ton API : liste des profils étudiants visibles.
      final data = await ApiClient.instance.get('/etudiants/profils');
      if (!mounted) return;
      setState(() {
        _etudiants = data is List<dynamic> ? data : <dynamic>[];
        _filtres = _etudiants;
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
        _filtres = _etudiants;
        return;
      }
      _filtres = _etudiants.where((e) {
        final nom = (e['nom_complet'] ?? e['nom'] ?? '').toString().toLowerCase();
        final formation = (e['formation'] ?? '').toString().toLowerCase();
        final competences = ((e['competences'] as List<dynamic>?) ?? [])
            .map((c) => c.toString().toLowerCase())
            .join(' ');
        return nom.contains(q) || formation.contains(q) || competences.contains(q);
      }).toList();
    });
  }

  void _voirProfil(dynamic etudiant) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfilEtudiantSheet(etudiant: etudiant),
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
              hintText: 'Rechercher par nom, formation, compétence...',
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
                  ? const Center(child: Text('Aucun étudiant trouvé.', style: TextStyle(color: AppColors.textMuted)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        itemCount: _filtres.length,
                        itemBuilder: (context, i) {
                          final e = _filtres[i];
                          final competences = (e['competences'] as List<dynamic>?) ?? [];
                          return InkWell(
                            onTap: () => _voirProfil(e),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.darkGreen.withOpacity(0.1),
                                    child: Text(
                                      (e['nom_complet'] ?? e['nom'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          e['nom_complet'] ?? e['nom'] ?? 'Étudiant',
                                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
                                        ),
                                        if (e['formation'] != null)
                                          Text(e['formation'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                        if (competences.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 6,
                                            children: competences.take(3).map((c) {
                                              return Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: AppColors.darkGreen.withOpacity(0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(c.toString(), style: const TextStyle(fontSize: 11, color: AppColors.darkGreen)),
                                              );
                                            }).toList(),
                                          ),
                                        ],
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
}

/// Détail complet du profil d'un étudiant, affiché en bottom sheet.
class _ProfilEtudiantSheet extends StatelessWidget {
  final dynamic etudiant;
  const _ProfilEtudiantSheet({required this.etudiant});

  Widget _section(String titre, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGreen, fontSize: 14)),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final competences = (etudiant['competences'] as List<dynamic>?) ?? [];
    final centresInteret = (etudiant['centres_interet'] as List<dynamic>?) ?? [];
    final experiences = (etudiant['experiences'] as List<dynamic>?) ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                etudiant['nom_complet'] ?? etudiant['nom'] ?? 'Étudiant',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              if (etudiant['formation'] != null) ...[
                const SizedBox(height: 4),
                Text(etudiant['formation'], style: const TextStyle(color: AppColors.textMuted)),
              ],
              const SizedBox(height: 20),
              if (etudiant['bio'] != null) _section('À propos', Text(etudiant['bio'], style: const TextStyle(color: AppColors.textDark))),
              if (competences.isNotEmpty)
                _section(
                  'Compétences',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: competences.map((c) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.darkGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(c.toString(), style: const TextStyle(color: AppColors.darkGreen, fontSize: 12)),
                      );
                    }).toList(),
                  ),
                ),
              if (centresInteret.isNotEmpty)
                _section(
                  'Centres d\'intérêt',
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: centresInteret.map((c) => Chip(label: Text(c.toString()))).toList(),
                  ),
                ),
              if (experiences.isNotEmpty)
                _section(
                  'Expériences',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: experiences.map<Widget>((exp) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exp['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            if (exp['entreprise'] != null)
                              Text(exp['entreprise'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            if (exp['periode'] != null)
                              Text(exp['periode'], style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.close),
                  label: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}