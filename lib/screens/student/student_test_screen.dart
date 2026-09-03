import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// Cas d'utilisation "Effectuer test" (test d'orientation) : questions simples
/// enregistrées via /profils/moi/wizard/reponse, puis génération de la
/// recommandation via /ia/recommandations/generer.
class StudentTestScreen extends StatefulWidget {
  const StudentTestScreen({super.key});

  @override
  State<StudentTestScreen> createState() => _StudentTestScreenState();
}

// Questions d'exemple — à remplacer/étoffer selon le référentiel de filières réel.
const _questions = [
  {'id': 'q1', 'label': "Préfères-tu résoudre des problèmes logiques ou créer des interfaces visuelles ?", 'options': ['Logique', 'Visuel', 'Les deux']},
  {'id': 'q2', 'label': 'Es-tu plus attiré par la donnée (data) ou par le développement d\'applications ?', 'options': ['Donnée', 'Applications']},
  {'id': 'q3', 'label': "Aimerais-tu travailler sur des projets d'intelligence artificielle ?", 'options': ['Oui', 'Non', 'Peut-être']},
  {'id': 'q4', 'label': "Aimes-tu travailler sur le matériel (hardware) ou uniquement sur le logiciel (software) ?", 'options': ['Hardware', 'Software', 'Les deux']},
  {'id': 'q5', 'label': "Es-tu à l'aise avec la gestion d'équipe et la planification de projets ?", 'options': ['Gestion/Management', 'Technique pure', 'Mixte']},
  {'id': 'q6', 'label': "Quel domaine t'intéresse le plus ?", 'options': ['Cybersécurité', 'Cloud Computing', 'IoT (Objets connectés)', 'Développement Web']},
  {'id': 'q7', 'label': "Préfères-tu un environnement de travail structuré ou flexible ?", 'options': ['Grande Entreprise', 'Startup', 'Freelance']},
  {'id': 'q8', 'label': "Es-tu intéressé par le développement mobile ?", 'options': ['Oui, passionnément', 'Un peu', 'Pas du tout']},
  {'id': 'q9', 'label': "Comment abordes-tu un problème complexe ?", 'options': ['Analyse mathématique', 'Prototype rapide', 'Recherche documentaire']},
  {'id': 'q10', 'label': "L'expérience utilisateur (UX) est-elle pour toi une priorité ?", 'options': ['Essentielle', 'Secondaire', 'Pas mon domaine']},
];

class _StudentTestScreenState extends State<StudentTestScreen> {
  final _api = ApiClient.instance;
  int _etape = 0;
  bool _loading = false;
  Map<String, dynamic>? _resultat;

  Future<void> _repondre(String option) async {
    setState(() => _loading = true);
    try {
      await _api.post('/profils/moi/wizard/reponse', {
        'etape': _etape,
        'question_id': _questions[_etape]['id'],
        'reponse': {'valeur': option},
      });
      if (_etape < _questions.length - 1) {
        setState(() => _etape++);
      } else {
        await _api.post('/profils/moi/wizard/terminer', {});
        final data = await _api.post('/ia/recommandations/generer', {});
        setState(() => _resultat = data);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_resultat != null) {
      final scores = (_resultat!['scores'] as List?) ?? [];
      final justification = _resultat!['recommandation']?['justification_texte'] ?? '';
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Ta recommandation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGreen)),
          const SizedBox(height: 12),
          Text(justification, style: const TextStyle(color: AppColors.textDark, height: 1.6)),
          const SizedBox(height: 20),
          for (final s in scores)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s['filiere_nom'] ?? 'Filière', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${s['score']}%', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (s['score'] ?? 0) / 100,
                    minHeight: 8,
                    color: AppColors.gold,
                    backgroundColor: AppColors.cardGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    final q = _questions[_etape];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Question ${_etape + 1} / ${_questions.length}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 12),
              Text(q['label'] as String, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 24),
              if (_loading) const CircularProgressIndicator() else
                ...((q['options'] as List<String>).map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(onPressed: () => _repondre(opt), child: Text(opt)),
                  ),
                ))),
            ],
          ),
        ),
      ),
    );
  }
}
