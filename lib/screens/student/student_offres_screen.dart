import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// Cas d'utilisation "Consulter offre" + "Postuler à une offre".
class StudentOffresScreen extends StatefulWidget {
  const StudentOffresScreen({super.key});

  @override
  State<StudentOffresScreen> createState() => _StudentOffresScreenState();
}

class _StudentOffresScreenState extends State<StudentOffresScreen> {
  final _api = ApiClient.instance;
  List<dynamic> _offres = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/offres', auth: false);
      setState(() => _offres = data as List<dynamic>);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _postuler(String offreId) async {
    try {
      await _api.post('/candidatures', {'offreId': offreId});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidature envoyée !')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_offres.isEmpty) {
      return const Center(child: Text("Aucune offre n'a été trouvée pour le moment.", style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _offres.length,
      itemBuilder: (context, i) {
        final o = _offres[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(o['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Text('${o['entreprises']?['nom'] ?? ''} · ${o['localisation'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(o['type'] == 'stage' ? 'Stage' : 'Emploi', style: const TextStyle(fontSize: 11, color: AppColors.darkGreen, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _postuler(o['id']),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkGreen),
                child: const Text('Postuler'),
              ),
            ],
          ),
        );
      },
    );
  }
}
