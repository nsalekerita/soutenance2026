import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

/// Cas d'utilisation "Publier une offre" (implicite dans le dashboard entreprise).
class EntreprisePublierScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const EntreprisePublierScreen({super.key, this.initialData});

  @override
  State<EntreprisePublierScreen> createState() =>
      _EntreprisePublierScreenState();
}

class _EntreprisePublierScreenState extends State<EntreprisePublierScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titre;
  late final TextEditingController _description;
  late final TextEditingController _missions;
  late final TextEditingController _localisation;
  late final TextEditingController _conditions;
  late final TextEditingController _competenceInput;

  final List<String> _competences = [];

  String _type = 'stage';
  String _niveauEtude = 'licence';
  bool _loading = false;

  static const _niveaux = [
    DropdownMenuItem(value: 'bac', child: Text('Bac')),
    DropdownMenuItem(value: 'bac+2', child: Text('Bac +2')),
    DropdownMenuItem(value: 'licence', child: Text('Licence')),
    DropdownMenuItem(value: 'master', child: Text('Master')),
    DropdownMenuItem(value: 'doctorat', child: Text('Doctorat')),
  ];

  static const _types = [
    DropdownMenuItem(value: 'stage', child: Text('Stage')),
    DropdownMenuItem(value: 'emploi', child: Text('Emploi')),
  ];

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _titre = TextEditingController(text: d?['titre']?.toString());
    _description = TextEditingController(text: d?['description']?.toString());
    _missions = TextEditingController(text: d?['missions']?.toString());
    _localisation = TextEditingController(text: d?['localisation']?.toString());
    _conditions =
        TextEditingController(text: d?['conditions_candidature']?.toString());
    _competenceInput = TextEditingController();

    final initCompetences = d?['competences_requises'];
    if (initCompetences is List) {
      _competences.addAll(initCompetences.map((e) => e.toString()));
    }

    _type = d?['type']?.toString() ?? 'stage';
    _niveauEtude = d?['niveau_etude_requis']?.toString() ?? 'licence';
  }

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    _missions.dispose();
    _localisation.dispose();
    _conditions.dispose();
    _competenceInput.dispose();
    super.dispose();
  }

  void _addCompetence(String value) {
    final v = value.trim();
    if (v.isEmpty) return;
    if (_competences.contains(v)) {
      _competenceInput.clear();
      return;
    }
    setState(() {
      _competences.add(v);
      _competenceInput.clear();
    });
  }

  void _removeCompetence(String value) {
    setState(() => _competences.remove(value));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final body = {
        'titre': _titre.text.trim(),
        'description': _description.text.trim(),
        'missions': _missions.text.trim(),
        'competences_requises': _competences,
        'niveau_etude_requis': _niveauEtude,
        'conditions_candidature': _conditions.text.trim(),
        'type': _type,
        'localisation': _localisation.text.trim(),
        'statut': 'en_attente',
      };

      if (widget.initialData != null) {
        await ApiClient.instance
            .put('/offres/${widget.initialData!['id']}', body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Offre modifiée avec succès.")),
          );
          Navigator.pop(context, true);
        }
      } else {
        await ApiClient.instance.post('/offres', body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Offre publiée, en attente de validation.")),
          );
          _titre.clear();
          _description.clear();
          _missions.clear();
          _localisation.clear();
          _conditions.clear();
          setState(() {
            _competences.clear();
            _type = 'stage';
            _niveauEtude = 'licence';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;

    return Scaffold(
      // Ivoire chaud, cohérent avec l'identité visuelle de la plateforme.
      backgroundColor: AppColors.paper,
      appBar: isEdit
          ? AppBar(
              title: const Text("Modifier l'offre"),
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
              elevation: 0,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  Text(
                    isEdit ? 'Modifier votre offre' : 'Publier une offre',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEdit
                        ? 'Ajustez les détails ci-dessous.'
                        : 'Renseignez les détails du poste à publier.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    icon: Icons.work_outline_rounded,
                    title: 'Le poste',
                    children: [
                      _buildTextField(
                        controller: _titre,
                        label: 'Titre du poste',
                        hint: 'Ex. Développeur mobile Flutter — stagiaire',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Champ requis'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              label: "Type d'offre",
                              value: _type,
                              items: _types,
                              onChanged: (v) =>
                                  setState(() => _type = v ?? 'stage'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Niveau requis',
                              value: _niveauEtude,
                              items: _niveaux,
                              onChanged: (v) =>
                                  setState(() => _niveauEtude = v ?? 'licence'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _localisation,
                        label: 'Localisation',
                        hint: 'Ex. Yaoundé, Cameroun — présentiel',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.description_outlined,
                    title: 'Description',
                    children: [
                      _buildTextField(
                        controller: _description,
                        label: 'Description du poste',
                        hint: "Contexte, équipe, quotidien de l'étudiant",
                        maxLines: 4,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Champ requis'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _missions,
                        label: 'Missions principales',
                        hint: 'Une mission par ligne',
                        maxLines: 3,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    icon: Icons.psychology_outlined,
                    title: 'Profil recherché',
                    children: [
                      Text(
                        'Compétences recherchées',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCompetencesInput(),
                      const SizedBox(height: 14),
                      _buildTextField(
                        controller: _conditions,
                        label: 'Conditions de candidature',
                        hint:
                            'Ex. CV et lettre de motivation avant le 30 octobre',
                        maxLines: 2,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isEdit
                                  ? 'Enregistrer les modifications'
                                  : "Publier l'offre",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: appInputDecoration(label: label, hint: hint),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: appInputDecoration(label: label),
    );
  }

  /// Zone de saisie des compétences sous forme de puces ("chips"),
  /// plus lisible qu'une liste séparée par des virgules.
  Widget _buildCompetencesInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ..._competences.map(
            (c) => Chip(
              label: Text(c,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
              backgroundColor: AppColors.sage,
              labelStyle: TextStyle(color: AppColors.darkGreen),
              deleteIcon: const Icon(Icons.close, size: 15),
              onDeleted: () => _removeCompetence(c),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide.none,
            ),
          ),
          SizedBox(
            width: 140,
            child: TextField(
              controller: _competenceInput,
              decoration: const InputDecoration(
                hintText: 'Ajouter…',
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: _addCompetence,
              textInputAction: TextInputAction.done,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte de section réutilisable pour regrouper des champs liés
/// ("Le poste", "Description", "Profil recherché").
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.darkGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
