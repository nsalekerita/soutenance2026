import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Carte de contenu standard de l'app : même fond, bordure, arrondi et
/// padding partout, pour que toutes les "cartes" (stats, sections de
/// formulaire, éléments de liste) aient un rendu identique d'un écran à
/// l'autre au lieu que chaque écran invente sa propre combinaison.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? background;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.background,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background ?? AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Badge de statut standard (fond clair + texte de la couleur sémantique
/// correspondante), pour remplacer les `Container` de badge ad hoc qui
/// utilisaient des couleurs brutes (Colors.green/red/orange) différentes
/// d'un écran à l'autre pour le même statut.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color background;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

/// Décoration de champ de saisie standard (bordure, arrondi, focus, erreur),
/// pour remplacer les recettes `InputDecoration` divergentes (rayon, couleur
/// de bordure au focus, absence de style d'erreur) d'un formulaire à l'autre.
InputDecoration appInputDecoration({
  String? label,
  String? hint,
  Widget? suffixIcon,
  Widget? prefixIcon,
  String? counterText,
}) {
  const radius = 10.0;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    counterText: counterText,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.darkGreen, width: 1.6),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
  );
}

/// Message d'erreur standard (icône + texte), pour remplacer les `Text`
/// d'erreur bruts (parfois sans couleur, parfois en Colors.red) par un
/// rendu unique partout dans l'app.
class InlineErrorText extends StatelessWidget {
  final String message;
  const InlineErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: AppColors.error, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
