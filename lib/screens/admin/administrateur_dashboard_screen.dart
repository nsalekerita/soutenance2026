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
  ];

  Map<String, dynamic>? _stats;
  List<dynamic> _offres = [];
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
      // On restaure /admin/ car le serveur ne connaît pas /administrateur/
      final stats = await ApiClient.instance.get('/admin/stats');
      
      var response = await ApiClient.instance.get('/admin/offres?statut=en_attente');
      List<dynamic> fetchedOffres = _extractList(response);

      if (fetchedOffres.isEmpty) {
        debugPrint('Administrateur: Liste "en_attente" vide, tentative sans filtre...');
        final allRes = await ApiClient.instance.get('/admin/offres');
        final allList = _extractList(allRes);
        fetchedOffres = allList.where((o) => 
          o['statut'] == 'en_attente' || 
          o['statut'] == 'PENDING' || 
          o['statut'] == null ||
          o['statut'] == ''
        ).toList();
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _offres = fetchedOffres;
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
      return res['offres'] ?? res['data'] ?? res['items'] ?? res['results'] ?? [];
    }
    return [];
  }

  Future<void> _valider(String id, String statut) async {
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

  @override
  Widget build(BuildContext context) {
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
              child: _index == 0 ? _buildStats() : _buildOffresAValider(),
            ),
    );
  }

  Widget _buildStats() {
    final s = _stats ?? {};
    return GridView.count(
      padding: const EdgeInsets.all(24),
      crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _statCard('Étudiants', s['nbEtudiants']),
        _statCard('Entreprises', s['nbEntreprises']),
        _statCard('Offres Total', s['nbOffres']),
        _statCard('Candidatures', s['nbCandidatures']),
      ],
    );
  }

  Widget _statCard(String label, dynamic value) => Container(
    decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    alignment: Alignment.center,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${value ?? 0}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.darkGreen)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    ),
  );

  Widget _buildOffresAValider() {
    if (_offres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text('Aucune offre en attente.', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
            if (_stats != null) ...[
              const SizedBox(height: 8),
              Text('Total en base : ${_stats!['nbOffres'] ?? 0}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _load, child: const Text('Recharger')),
          ],
        ),
      );
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
                Text('Statut actuel: ${o['statut']}', style: const TextStyle(fontSize: 11, color: AppColors.gold)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, color: AppColors.darkGreen),
                  onPressed: () => _showDetails(o),
                  tooltip: 'Voir les détails',
                ),
                IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), 
                  onPressed: () => _valider(o['id'].toString(), 'validee')),
                IconButton(icon: const Icon(Icons.cancel, color: Colors.red), 
                  onPressed: () => _valider(o['id'].toString(), 'rejetee')),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetails(dynamic o) {
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _valider(o['id'].toString(), 'rejetee');
            },
            child: const Text('Rejeter'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              _valider(o['id'].toString(), 'validee');
            },
            child: const Text('Valider'),
          ),
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
