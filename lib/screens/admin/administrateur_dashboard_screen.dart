import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../widgets/dashboard_shell.dart';

/// Dashboard administrateur : statistiques globales, gestion des offres et des comptes.
class AdministrateurDashboardScreen extends StatefulWidget {
  const AdministrateurDashboardScreen({super.key});

  @override
  State<AdministrateurDashboardScreen> createState() => _AdministrateurDashboardScreenState();
}

class _AdministrateurDashboardScreenState extends State<AdministrateurDashboardScreen> {
  int _index = 0;
  static const _items = [
    NavEntry(Icons.bar_chart_outlined, 'Statistiques'),
    NavEntry(Icons.list_alt_outlined, 'Offres à valider'),
    NavEntry(Icons.people_outline, 'Gestion des comptes'),
  ];

  // Couleurs additionnelles pour les statistiques (catégories qui n'ont pas
  // d'équivalent direct dans AppColors).
  static const Color _statTeal = Color(0xFF2D6E8E); // Étudiants
  static const Color _statPlum = Color(0xFF7C3F55); // Candidatures

  Map<String, dynamic>? _stats;
  List<dynamic> _offres = [];
  List<dynamic> _comptes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final stats = await ApiClient.instance.get('/admin/stats');

      // Load offres
      var responseOffres = await ApiClient.instance.get('/admin/offres?statut=en_attente');
      List<dynamic> fetchedOffres = _extractList(responseOffres);

      // Load comptes
      var responseComptes = await ApiClient.instance.get('/admin/comptes');
      List<dynamic> fetchedComptes = _extractList(responseComptes);

      if (mounted) {
        setState(() {
          _stats = stats;
          _offres = fetchedOffres;
          _comptes = fetchedComptes;
        });
      }
    } catch (e) {
      debugPrint('Administrateur Load Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _extractList(dynamic res) {
    if (res is List) return res;
    if (res is Map) {
      return res['offres'] ?? res['comptes'] ?? res['data'] ?? res['items'] ?? res['results'] ?? [];
    }
    return [];
  }

  Future<void> _validerOffre(String id, String statut) async {
    try {
      await ApiClient.instance.patch('/admin/offres/$id/statut', {'statut': statut});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statut == 'validee' ? 'Offre validée avec succès' : 'Offre rejetée'),
            backgroundColor: statut == 'validee' ? Colors.green : Colors.red,
          ),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur validation: $e')));
      }
    }
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
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Bloquer', style: TextStyle(color: Colors.red)),
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
      await ApiClient.instance.patch('/admin/comptes/${compte['id']}/$action', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Compte ${estActif ? 'bloqué' : 'débloqué'} avec succès')),
        );
      }
    } catch (e) {
      // La requête a échoué côté serveur : on annule le changement visuel
      // pour ne pas afficher un statut qui n'a pas réellement été appliqué.
      if (mounted) {
        setState(() => compte['actif'] = estActif);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _supprimerCompte(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce compte définitivement ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiClient.instance.delete('/admin/comptes/$id');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Compte supprimé')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_index) {
      case 0:
        content = _buildStats();
        break;
      case 1:
        content = _buildOffresAValider();
        break;
      case 2:
        content = _buildGestionComptes();
        break;
      default:
        content = const SizedBox();
    }

    return DashboardShell(
      title: 'Administrateur',
      items: _items,
      selectedIndex: _index,
      onSelect: (i) => setState(() => _index = i),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _load,
          tooltip: 'Actualiser',
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: content,
      ),
    );
  }

  /// Parse une valeur de stat qui peut arriver en int, double ou String depuis l'API.
  int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Widget _buildStats() {
    final s = _stats ?? {};

    final int nbEtudiants = _asInt(s['nbEtudiants']);
    final int nbEntreprises = _asInt(s['nbEntreprises']);
    final int nbOffres = _asInt(s['nbOffres']);
    final int nbCandidatures = _asInt(s['nbCandidatures']);
    final int maxVal = [nbEtudiants, nbEntreprises, nbOffres, nbCandidatures]
        .fold(1, (a, b) => b > a ? b : a); // évite division par zéro

    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _statCard(
          icon: Icons.school_outlined,
          label: 'Étudiants',
          value: nbEtudiants,
          color: _statTeal,
          maxVal: maxVal,
        ),
        _statCard(
          icon: Icons.apartment_outlined,
          label: 'Entreprises',
          value: nbEntreprises,
          color: AppColors.darkGreen,
          maxVal: maxVal,
        ),
        _statCard(
          icon: Icons.work_outline,
          label: 'Offres Total',
          value: nbOffres,
          color: AppColors.gold,
          maxVal: maxVal,
        ),
        _statCard(
          icon: Icons.forum_outlined,
          label: 'Candidatures',
          value: nbCandidatures,
          color: _statPlum,
          maxVal: maxVal,
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    required int maxVal,
  }) {
    final double ratio = maxVal == 0 ? 0 : (value / maxVal).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau de couleur en haut, propre à la catégorie
          Container(height: 4, color: color),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(height: 14),
                Text(
                  '$value',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                // Barre de proportion : représente la part de cette catégorie
                // par rapport à la plus grande valeur des 4 statistiques.
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffresAValider() {
    if (_offres.isEmpty) {
      return _buildEmptyState('Aucune offre en attente.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _offres.length,
      itemBuilder: (context, i) {
        final o = _offres[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(o['titre'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o['entreprise']?['nom'] ?? o['entreprises']?['nom'] ?? 'Entreprise inconnue'),
                const SizedBox(height: 4),
                Text('Statut: ${o['statut']}', style: const TextStyle(fontSize: 11, color: AppColors.gold)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, color: AppColors.darkGreen),
                  onPressed: () => _showOffreDetails(o),
                  tooltip: 'Voir',
                ),
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _validerOffre(o['id'].toString(), 'validee')),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _validerOffre(o['id'].toString(), 'rejetee')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGestionComptes() {
    if (_comptes.isEmpty) {
      return _buildEmptyState('Aucun compte trouvé.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _comptes.length,
      itemBuilder: (context, i) {
        final c = _comptes[i];
        final bool estActif = c['actif'] ?? true;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: c['role'] == 'entreprise' ? AppColors.gold.withOpacity(0.2) : AppColors.darkGreen.withOpacity(0.2),
              child: Icon(c['role'] == 'entreprise' ? Icons.business : Icons.person,
                  color: c['role'] == 'entreprise' ? AppColors.gold : AppColors.darkGreen),
            ),
            title: Text(c['email'] ?? 'Sans email', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Rôle: ${c['role']} • ${estActif ? 'Actif' : 'Bloqué'}',
                style: TextStyle(color: estActif ? Colors.green : Colors.red, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  onPressed: () => _showCompteDetails(c),
                  tooltip: 'Consulter',
                ),
                IconButton(
                  icon: Icon(estActif ? Icons.block : Icons.check_circle_outline, color: estActif ? Colors.orange : Colors.green),
                  onPressed: () => _toggleEtatCompte(c),
                  tooltip: estActif ? 'Bloquer' : 'Débloquer',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _supprimerCompte(c['id'].toString()),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
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
              _detailRow(Icons.business, 'Entreprise', o['entreprise']?['nom'] ?? o['entreprises']?['nom'] ?? 'Inconnue'),
              _detailRow(Icons.location_on_outlined, 'Localisation', o['localisation'] ?? 'Non spécifiée'),
              _detailRow(Icons.work_outline, 'Type', o['type'] ?? 'Non spécifié'),
              _detailRow(Icons.calendar_today, 'Date', o['created_at'] != null ? DateTime.parse(o['created_at']).toLocal().toString().split('.')[0] : 'Inconnue'),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _validerOffre(o['id'].toString(), 'rejetee');
            },
            child: const Text('Rejeter'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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

  void _showCompteDetails(dynamic c) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du compte'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow(Icons.email_outlined, 'Email', c['email'] ?? ''),
            _detailRow(Icons.badge_outlined, 'Rôle', c['role'] ?? ''),
            _detailRow(Icons.info_outline, 'Statut', (c['actif'] ?? true) ? 'Actif' : 'Bloqué'),
            _detailRow(Icons.calendar_today, 'Créé le', c['created_at'] != null ? DateTime.parse(c['created_at']).toLocal().toString().split(' ')[0] : 'Inconnue'),
            _detailRow(Icons.fingerprint, 'ID', c['id'] ?? ''),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
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