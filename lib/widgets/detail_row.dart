import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Ligne "icône + libellé + valeur" utilisée dans les boîtes de dialogue de
/// détails (offres, comptes) des tableaux de bord admin/entreprise.
class DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const DetailRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text('$label : ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
