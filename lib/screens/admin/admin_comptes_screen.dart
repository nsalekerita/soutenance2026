import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/detail_row.dart';

/// Onglet "Gestion des comptes" du dashboard administrateur.
class AdminComptesScreen extends StatefulWidget {
  const AdminComptesScreen({super.key});

  @override
  State<AdminComptesScreen> createState() => _AdminComptesScreenState();
}

class _AdminComptesScreenState extends State<AdminComptesScreen> {
  List<dynamic> _comptes = [];
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
      final response = await ApiClient.instance.get('/admin/comptes');
      if (mounted) setState(() => _comptes = _extractList(response));
    } catch (e) {
      if (mounted) setState(() => _error = friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map) {
      return res['comptes'] ??
          res['data'] ??
          res['items'] ??
          res['results'] ??
          [];
    }
    return [];
  }

  /// Bloque ou débloque un compte.
  ///
  /// Le blocage demande une confirmation (action sensible qui empêche
  /// l'utilisateur de se connecter), le déblocage est immédiat. Le statut
  /// affiché ("Actif" / "Bloqué") est mis à jour tout de suite à l'écran
  /// (mise à jour optimiste), sans attendre un rechargement complet ; en cas
  /// d'échec de la requête, le changement est annulé et l'admin en est informé.
  Future<void> _toggleEtatCompte(dynamic compte) async {
    final bool estActif = compte['actif'] ?? true;
    final String action = estActif ? 'bloquer' : 'debloquer';

    if (estActif) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Bloquer ce compte ?'),
          content: Text(
            "${compte['email'] ?? 'Ce compte'} ne pourra plus se connecter tant qu'il n'aura pas été débloqué. "
            "Vous pourrez le débloquer à tout moment depuis cette même liste.",
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bloquer', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // Mise à jour optimiste : le badge de statut passe immédiatement à
    // "Bloqué" (ou "Actif"), et l'icône se transforme en son opposée.
    setState(() => compte['actif'] = !estActif);

    try {
      await ApiClient.instance
          .patch('/admin/comptes/${compte['id']}/$action', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Compte ${estActif ? 'bloqué' : 'débloqué'} avec succès')),
        );
      }
    } catch (e) {
      // La requête a échoué côté serveur : on annule le changement visuel
      // pour ne pas afficher un statut qui n'a pas réellement été appliqué.
      if (mounted) {
        setState(() => compte['actif'] = estActif);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
      }
    }
  }

  Future<void> _supprimerCompte(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Êtes-vous sûr de vouloir supprimer ce compte définitivement ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Supprimer', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.instance.delete('/admin/comptes/$id');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Compte supprimé')));
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
    if (_comptes.isEmpty) {
      return _buildEmptyState('Aucun compte trouvé.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _comptes.length,
        itemBuilder: (context, i) {
          final c = _comptes[i];
          final bool estActif = c['actif'] ?? true;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.cardBorder)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: c['role'] == 'entreprise'
                    ? AppColors.gold.withOpacity(0.2)
                    : AppColors.darkGreen.withOpacity(0.2),
                child: Icon(
                    c['role'] == 'entreprise' ? Icons.business : Icons.person,
                    color: c['role'] == 'entreprise'
                        ? AppColors.gold
                        : AppColors.darkGreen),
              ),
              title: Text(c['email'] ?? 'Sans email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Rôle: ${c['role']} • ${estActif ? 'Actif' : 'Bloqué'}',
                  style: TextStyle(
                      color: estActif ? AppColors.success : AppColors.error,
                      fontSize: 12)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility_outlined),
                    onPressed: () => _showCompteDetails(c),
                    tooltip: 'Consulter',
                  ),
                  IconButton(
                    icon: Icon(
                        estActif ? Icons.block : Icons.check_circle_outline,
                        color: estActif ? AppColors.warning : AppColors.success),
                    onPressed: () => _toggleEtatCompte(c),
                    tooltip: estActif ? 'Bloquer' : 'Débloquer',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    onPressed: () => _supprimerCompte(c['id'].toString()),
                    tooltip: 'Supprimer',
                  ),
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

  void _showCompteDetails(dynamic c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du compte'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DetailRow(Icons.email_outlined, 'Email', c['email'] ?? ''),
            DetailRow(Icons.badge_outlined, 'Rôle', c['role'] ?? ''),
            DetailRow(Icons.info_outline, 'Statut',
                (c['actif'] ?? true) ? 'Actif' : 'Bloqué'),
            DetailRow(
                Icons.calendar_today,
                'Créé le',
                c['created_at'] != null
                    ? DateTime.parse(c['created_at'])
                        .toLocal()
                        .toString()
                        .split(' ')[0]
                    : 'Inconnue'),
            DetailRow(Icons.fingerprint, 'ID', c['id'] ?? ''),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }
}
