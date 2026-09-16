import 'package:flutter/material.dart';

/// Palette officielle de la plateforme IAI Horizon.
class AppColors {
  static const Color darkGreen = Color(0xFF0B5D3B);
  static const Color darkGreenLight = Color(0xFF0E7A4C);
  // Variante la plus sombre : fonds/boutons a forte emphase (ex. bouton de connexion).
  static const Color darkGreenDeep = Color(0xFF082D22);
  static const Color gold = Color(0xFFD4A72C);
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F6F5);
  static const Color textDark = Color(0xFF2C2C2A);
  static const Color textMuted = Color(0xFF6B6B67);
  static const Color cardGrey = Color(0xFFD9D9D6);
  // Texte clair (atténué) sur fond vert foncé (splash, bandeau hero).
  static const Color mutedOnDark = Color(0xFFD7E9DE);
  // Fond beige/ivoire clair des cartes et ecrans (register, publier une offre).
  static const Color paper = Color(0xFFF4F4EE);

  // Fonds des cercles d'icônes sur l'écran de choix de rôle
  static const Color sage = Color(0xFFE3EEE7); // teinte claire de darkGreen, cercle "Étudiant"
  static const Color goldTint = Color(0xFFF9EFD6); // teinte claire de gold, cercle "Entreprise"

  // Couleurs d'accent pour les cartes de statistiques (dashboard admin, reutilisables ailleurs).
  static const Color statTeal = Color(0xFF2D6E8E);
  static const Color statPlum = Color(0xFF7C3F55);

  // Badges "type d'offre" (page d'accueil).
  static const Color badgeStage = Color(0xFFEAF3DE);
  static const Color badgeEmploi = Color(0xFFE1F5EE);
  static const Color badgeEmploiText = Color(0xFF04342C);

  // Footer sombre de la page d'accueil (fond = textDark, textes attenues dessus).
  static const Color footerBackground = textDark;
  static const Color footerText = Color(0xFFB4B2A9);
  static const Color footerDivider = Color(0xFF444441);
  static const Color footerTextMuted = Color(0xFF888780);

  // Couleurs sémantiques (statuts, messages) : à utiliser partout au lieu de
  // Colors.red/green/orange bruts, pour garantir un rendu identique d'un
  // écran à l'autre pour un même statut ("acceptée", "en attente", etc.).
  static const Color success = darkGreen;
  static const Color successBackground = Color(0xFFE3EEE7);
  static const Color error = Color(0xFFC0392B);
  static const Color errorBackground = Color(0xFFFBEAE8);
  static const Color warning = Color(0xFFB8791C);
  static const Color warningBackground = Color(0xFFFAF0DD);
  static const Color info = statTeal;
  static const Color infoBackground = Color(0xFFE4EDF2);

  // Recette de carte de contenu unique (fond + bordure), réutilisée par
  // toutes les cartes "conteneur" de l'app pour éviter que chaque écran
  // invente sa propre combinaison fond/bordure/ombre.
  static const Color cardBorder = cardGrey;
}