import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// Cas d'utilisation "Publier une offre" (implicite dans le dashboard entreprise).
class EntreprisePublierScreen extends StatefulWidget {
  const EntreprisePublierScreen({super.key});

  @override
  State<EntreprisePublierScreen> createState() => _EntreprisePublierScreenState();
}

class _EntreprisePublierScreenState extends State<EntreprisePublierScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titre = TextEditingController();
  final _description = TextEditingController();
  final _missions = TextEditingController();
  final _competences = TextEditingController();
  final _localisation = TextEditingController();
  final _conditions = TextEditingController();

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
  void dispose() {
    _titre.dispose();
    _description.dispose();
    _missions.dispose();
    _competences.dispose();
    _localisation.dispose();
    _conditions.dispose();
    super.dispose();
  }

  Future<void> _publier() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      // Adapter les clés ci-dessous au contrat exact de ton API.
      await ApiClient.instance.post('/offres', {
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
        'statut': 'en_attente', // Ajout explicite du statut
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Offre publiée, en attente de validation par l'administrateur.")),
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
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              const Text('Publier une offre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
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
                onPressed: _loading ? null : _publier,
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
                    : const Text("Publier l'offre"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}