import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// Cas d'utilisation "Publier une offre" (implicite dans le dashboard entreprise).
class EntreprisePublierScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const EntreprisePublierScreen({super.key, this.initialData});

  @override
  State<EntreprisePublierScreen> createState() => _EntreprisePublierScreenState();
}

class _EntreprisePublierScreenState extends State<EntreprisePublierScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titre;
  late final TextEditingController _description;
  late final TextEditingController _missions;
  late final TextEditingController _competences;
  late final TextEditingController _localisation;
  late final TextEditingController _conditions;

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

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _titre = TextEditingController(text: d?['titre']?.toString());
    _description = TextEditingController(text: d?['description']?.toString());
    _missions = TextEditingController(text: d?['missions']?.toString());
    _competences = TextEditingController(
      text: (d?['competences_requises'] as List?)?.join(', ') ?? '',
    );
    _localisation = TextEditingController(text: d?['localisation']?.toString());
    _conditions = TextEditingController(text: d?['conditions_candidature']?.toString());
    _type = d?['type']?.toString() ?? 'stage';
    _niveauEtude = d?['niveau_etude_requis']?.toString() ?? 'licence';
  }

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    _missions.dispose();
    _competences.dispose();
    _localisation.dispose();
    _conditions.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final body = {
        'titre': _titre.text.trim(),
        'description': _description.text.trim(),
        'missions': _missions.text.trim(),
        'competences_requises': _competences.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        'niveau_etude_requis': _niveauEtude,
        'conditions_candidature': _conditions.text.trim(),
        'type': _type,
        'localisation': _localisation.text.trim(),
        'statut': 'en_attente',
      };

      if (widget.initialData != null) {
        await ApiClient.instance.put('/offres/${widget.initialData!['id']}', body);
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
            const SnackBar(content: Text("Offre publiée, en attente de validation.")),
          );
          _titre.clear();
          _description.clear();
          _missions.clear();
          _competences.clear();
          _localisation.clear();
          _conditions.clear();
          setState(() {
            _type = 'stage';
            _niveauEtude = 'licence';
          });
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialData != null;
    return Scaffold(
      appBar: isEdit ? AppBar(title: const Text("Modifier l'offre")) : null,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Text(isEdit ? 'Modifier votre offre' : 'Publier une offre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titre,
                  decoration: const InputDecoration(labelText: 'Titre du poste'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _missions,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Missions principales'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _competences,
                  decoration: const InputDecoration(
                    labelText: 'Compétences recherchées',
                    hintText: 'ex: Flutter, Node.js, SQL',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _niveauEtude,
                  decoration: const InputDecoration(labelText: "Niveau d'étude requis"),
                  items: _niveaux,
                  onChanged: (v) => setState(() => _niveauEtude = v ?? 'licence'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _conditions,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Conditions de candidature'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _localisation,
                  decoration: const InputDecoration(labelText: 'Localisation'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: "Type d'offre"),
                  items: const [
                    DropdownMenuItem(value: 'stage', child: Text('Stage')),
                    DropdownMenuItem(value: 'emploi', child: Text('Emploi')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'stage'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isEdit ? "Enregistrer les modifications" : "Publier l'offre"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
