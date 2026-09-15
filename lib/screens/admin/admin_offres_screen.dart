import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/detail_row.dart';

/// Onglet "Offres à valider" du dashboard administrateur.
class AdminOffresScreen extends StatefulWidget {
  const AdminOffresScreen({super.key});

  @override
  State<AdminOffresScreen> createState() => _AdminOffresScreenState();
}

class _AdminOffresScreenState extends State<AdminOffresScreen> {
  List<dynamic> _offres = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response =
          await ApiClient.instance.get('/admin/offres?statut=en_attente');
      if (mounted) setState(() => _offres = _extractList(response));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map) {
      return res['offres'] ??
          res['data'] ??
          res['items'] ??
          res['results'] ??
          [];
    }
    return [];
  }

  Future<void> _validerOffre(String id, String statut) async {
    try {
      await ApiClient.instance
          .patch('/admin/offres/$id/statut', {'statut': statut});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statut == 'validee'
                ? 'Offre validée avec succès'
                : 'Offre rejetée'),
            backgroundColor: statut == 'validee' ? AppColors.success : AppColors.error,
          ),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 40),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }
    if (_offres.isEmpty) {
      return _buildEmptyState('Aucune offre en attente.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _offres.length,
        itemBuilder: (context, i) {
          final o = _offres[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorder)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(o['titre'] ?? 'Sans titre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o['entreprise']?['nom'] ??
                      o['entreprises']?['nom'] ??
                      'Entreprise inconnue'),
                  const SizedBox(height: 4),
                  Text('Statut: ${o['statut']}',
                      style:
                          const TextStyle(fontSize: 11, color: AppColors.warning)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined,
                        color: AppColors.darkGreen),
                    onPressed: () => _showOffreDetails(o),
                    tooltip: 'Voir',
                  ),
                  IconButton(
                      icon: const Icon(Icons.check_circle, color: AppColors.success),
                      tooltip: 'Valider',
                      onPressed: () =>
                          _validerOffre(o['id'].toString(), 'validee')),
                  IconButton(
                      icon: const Icon(Icons.cancel, color: AppColors.error),
                      tooltip: 'Rejeter',
                      onPressed: () =>
                          _validerOffre(o['id'].toString(), 'rejetee')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _load, child: const Text('Recharger')),
        ],
      ),
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
              DetailRow(
                  Icons.business,
                  'Entreprise',
                  o['entreprise']?['nom'] ??
                      o['entreprises']?['nom'] ??
                      'Inconnue'),
              DetailRow(Icons.location_on_outlined, 'Localisation',
                  o['localisation'] ?? 'Non spécifiée'),
              DetailRow(
                  Icons.work_outline, 'Type', o['type'] ?? 'Non spécifié'),
              DetailRow(
                  Icons.calendar_today,
                  'Date',
                  o['created_at'] != null
                      ? DateTime.parse(o['created_at'])
                          .toLocal()
                          .toString()
                          .split('.')[0]
                      : 'Inconnue'),
              const Divider(height: 24),
              const Text('Description :',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(o['description'] ?? 'Aucune description fournie.'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error, foregroundColor: AppColors.white),
            onPressed: () {
              Navigator.pop(context);
              _validerOffre(o['id'].toString(), 'rejetee');
            },
            child: const Text('Rejeter'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success, foregroundColor: AppColors.white),
            onPressed: () {
              Navigator.pop(context);
              _validerOffre(o['id'].toString(), 'validee');
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}
