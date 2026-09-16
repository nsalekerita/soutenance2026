import 'package:flutter/material.dart';
import '../../widgets/dashboard_shell.dart';
import 'admin_stats_screen.dart';
import 'admin_offres_screen.dart';
import 'admin_comptes_screen.dart';

/// Dashboard administrateur : statistiques globales, gestion des offres et des comptes.
class AdministrateurDashboardScreen extends StatefulWidget {
  const AdministrateurDashboardScreen({super.key});

  @override
  State<AdministrateurDashboardScreen> createState() =>
      _AdministrateurDashboardScreenState();
}

class _AdministrateurDashboardScreenState
    extends State<AdministrateurDashboardScreen> {
  int _index = 0;

  static const _items = [
    NavEntry(Icons.bar_chart_outlined, 'Statistiques'),
    NavEntry(Icons.list_alt_outlined, 'Offres à valider'),
    NavEntry(Icons.people_outline, 'Gestion des comptes'),
  ];

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      AdminStatsScreen(onNavigate: _goTo),
      const AdminOffresScreen(),
      const AdminComptesScreen(),
    ];

    return DashboardShell(
      title: 'Administrateur',
      items: _items,
      selectedIndex: _index,
      onSelect: _goTo,
      child: pages[_index],
    );
  }
}
