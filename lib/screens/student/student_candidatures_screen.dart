import 'package:flutter/material.dart';
import '../../core/services/api_client.dart';
import '../../theme/app_colors.dart';

/// "Suivre sa progression" : liste des candidatures et leur statut.
class StudentCandidaturesScreen extends StatefulWidget {
  const StudentCandidaturesScreen({super.key});

  @override
  State<StudentCandidaturesScreen> createState() => _StudentCandidaturesScreenState();
}

class _StudentCandidaturesScreenState extends State<StudentCandidaturesScreen> {
  final _api = ApiClient.instance;
  List<dynamic> _candidatures = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/candidatures/moi');
      setState(() => _candidatures = data as List<dynamic>);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyApiError(e))));
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'acceptee':
        return AppColors.darkGreen;
      case 'refusee':
        return Colors.red;
      case 'vue':
        return AppColors.gold;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_candidatures.isEmpty) {
      return const Center(child: Text("Tu n'as pas encore postulé à une offre.", style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _candidatures.length,
      itemBuilder: (context, i) {
        final c = _candidatures[i];
        final offre = c['offres'];
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
                    Text(offre?['titre'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text(offre?['entreprises']?['nom'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Chip(label: Text(c['statut'] ?? ''), backgroundColor: _statutColor(c['statut'] ?? '').withOpacity(0.12), labelStyle: TextStyle(color: _statutColor(c['statut'] ?? ''), fontWeight: FontWeight.w600)),
            ],
          ),
        );
      },
    );
  }
}
