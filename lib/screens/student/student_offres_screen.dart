import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import 'student_postuler_screen.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _postuler(String offreId) async {
    try {
      await _api.post('/candidatures', {'offreId': offreId});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Candidature envoyée !')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
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
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(o['titre'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textDark)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${o['entreprises']?['nom'] ?? ''} · ${o['localisation'] ?? ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(o['type'] == 'stage' ? 'Stage' : 'Emploi',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.darkGreen, fontWeight: FontWeight.w600)),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _showOffreDetails(o),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkGreen,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Consultez'),
            ),
          ),
        );
      },
    );
  }

  void _showOffreDetails(dynamic o) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(o['titre'] ?? 'Détails de l\'offre'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.business, 'Entreprise', o['entreprises']?['nom'] ?? 'Inconnue'),
              _detailRow(Icons.location_on_outlined, 'Localisation', o['localisation'] ?? 'Non spécifiée'),
              _detailRow(Icons.work_outline, 'Type', o['type'] ?? 'Non spécifié'),
              const Divider(height: 24),
              const Text('Description :', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(o['description'] ?? 'Aucune description fournie.'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkGreen),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StudentPostulerScreen(offre: o)),
              );
            },
            child: const Text('Postuler'),
          ),
        ],
      ),
    );
  }

  void _showPostulerForm(dynamic o) {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ma candidature'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Votre CV actuel sera joint à cette candidature.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ajoutez un message pour l\'entreprise (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white),
            onPressed: () {
              final msg = messageController.text;
              Navigator.pop(context);
              _finaliserCandidature(o['id'].toString(), msg);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Future<void> _finaliserCandidature(String offreId, String message) async {
    try {
      await _api.post('/candidatures', {
        'offreId': offreId,
        'message': message,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Candidature envoyée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyApiError(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
