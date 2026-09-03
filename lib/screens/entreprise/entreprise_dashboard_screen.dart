import 'package:flutter/material.dart';
import '../../widgets/dashboard_shell.dart';
import 'entreprise_home_screen.dart';
import 'entreprise_offres_screen.dart';
import 'entreprise_publier_screen.dart';
import 'entreprise_etudiants_screen.dart';

/// Dashboard entreprise : Vue d'ensemble, publier une offre, consulter ses
/// offres et les candidatures reçues, et parcourir les profils des étudiants.
class EntrepriseDashboardScreen extends StatefulWidget {
  const EntrepriseDashboardScreen({super.key});

  @override
  State<EntrepriseDashboardScreen> createState() => _EntrepriseDashboardScreenState();
}

class _EntrepriseDashboardScreenState extends State<EntrepriseDashboardScreen> {
  int _index = 0;

  static const _items = [
    NavEntry(Icons.home_outlined, 'Accueil'),
    NavEntry(Icons.list_alt_outlined, 'Mes offres'),
    NavEntry(Icons.add_circle_outline, 'Publier une offre'),
    NavEntry(Icons.people_outline, 'Étudiants'),
  ];

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      EntrepriseHomeScreen(onNavigate: _goTo),
      const EntrepriseOffresScreen(),
      const EntreprisePublierScreen(),
      const EntrepriseEtudiantsScreen(),
    ];

    return DashboardShell(
      title: 'Espace entreprise',
      items: _items,
      selectedIndex: _index,
      onSelect: _goTo,
      child: pages[_index],
    );
  }
}
