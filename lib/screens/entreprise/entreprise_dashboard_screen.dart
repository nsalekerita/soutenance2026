import 'package:flutter/material.dart';
import '../../widgets/dashboard_shell.dart';
import 'entreprise_offres_screen.dart';
import 'entreprise_publier_screen.dart';
import 'entreprise_etudiants_screen.dart';

/// Dashboard entreprise : publier une offre, consulter ses offres et les
/// candidatures reçues (accepter/refuser/contacter), et parcourir les
/// profils des étudiants.
class EntrepriseDashboardScreen extends StatefulWidget {
  const EntrepriseDashboardScreen({super.key});

  @override
  State<EntrepriseDashboardScreen> createState() => _EntrepriseDashboardScreenState();
}

class _EntrepriseDashboardScreenState extends State<EntrepriseDashboardScreen> {
  int _index = 0;

  static const _items = [
    NavEntry(Icons.list_alt_outlined, 'Mes offres'),
    NavEntry(Icons.add_circle_outline, 'Publier une offre'),
    NavEntry(Icons.people_outline, 'Étudiants'),
  ];

  final _pages = const [
    EntrepriseOffresScreen(),
    EntreprisePublierScreen(),
    EntrepriseEtudiantsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardShell(
      title: 'Espace entreprise',
      items: _items,
      selectedIndex: _index,
      onSelect: (i) => setState(() => _index = i),
      child: _pages[_index],
    );
  }
}