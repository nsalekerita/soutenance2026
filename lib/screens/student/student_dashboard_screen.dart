import 'package:flutter/material.dart';
import '../../widgets/dashboard_shell.dart';
import 'student_home_screen.dart';
import 'student_profile_screen.dart';
import 'student_test_screen.dart';
import 'student_chat_screen.dart';
import 'student_offres_screen.dart';
import 'student_candidatures_screen.dart';

/// Dashboard étudiant : Accueil, Gérer profil, Passer le test d'orientation,
/// Discuter avec l'assistant IA, Consulter/Postuler aux offres, Suivre sa
/// progression.
///
/// L'onglet "Accueil" sert de point d'entrée : il résume l'avancement du
/// profil et les candidatures, et propose des accès rapides vers les autres
/// fonctionnalités, pour éviter que l'étudiant n'ait à deviner où aller.
class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _index = 0;

  static const _items = [
    NavEntry(Icons.home_outlined, 'Accueil'),
    NavEntry(Icons.person_outline, 'Mon profil'),
    NavEntry(Icons.quiz_outlined, "Test d'orientation"),
    NavEntry(Icons.smart_toy_outlined, 'Assistant IA'),
    NavEntry(Icons.work_outline, 'Offres'),
    NavEntry(Icons.assignment_turned_in_outlined, 'Mes candidatures'),
  ];

  void _goTo(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentHomeScreen(onNavigate: _goTo),
      const StudentProfileScreen(),
      const StudentTestScreen(),
      const StudentChatScreen(),
      const StudentOffresScreen(),
      const StudentCandidaturesScreen(),
    ];

    return DashboardShell(
      title: 'Espace étudiant',
      items: _items,
      selectedIndex: _index,
      onSelect: _goTo,
      child: pages[_index],
    );
  }
}