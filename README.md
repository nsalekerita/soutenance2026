# IAI Horizon — Frontend (Flutter, Android Studio)

## Démarrage

1. Ouvre `frontend/` dans Android Studio comme projet Flutter existant.
2. `flutter pub get`
3. Lance le backend (`cd ../backend && npm run dev`) avant de lancer l'app.
4. Configure l'URL du backend si besoin (par défaut prévu pour l'émulateur Android
   `http://10.0.2.2:4000/api`), via `--dart-define`:
   ```bash
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000/api
   ```
    - Appareil physique : remplace par l'IP locale de ton PC (`http://192.168.x.x:4000/api`).
    - iOS simulator / web : `http://localhost:4000/api`.

## Structure

```
lib/
|-- main.dart                     -> point d'entrée, MaterialApp.router + Provider
|-- theme/app_colors.dart         -> palette officielle IAI Horizon
|-- core/
|   |-- router/app_router.dart    -> go_router : routes + redirections selon rôle/auth
|   `-- services/
|       |-- api_client.dart       -> client HTTP vers le backend (JWT via flutter_secure_storage)
|       `-- auth_provider.dart    -> état d'authentification global (Provider)
|-- screens/
|   |-- splash/                   -> logo animé au lancement
|   |-- home/                     -> page d'accueil publique (ta maquette d'origine)
|   |-- auth/                     -> choix étudiant/entreprise, inscription, connexion
|   |-- student/                  -> dashboard étudiant (profil, test, chat IA, offres, candidatures)
|   |-- entreprise/                -> dashboard entreprise (publier, mes offres)
|   `-- admin/                     -> dashboard admin (stats, validation offres)
`-- widgets/dashboard_shell.dart  -> sidebar/nav commune aux 3 dashboards, avec hover
```

## Parcours implémenté (correspond à ton scénario)

1. **Splash** : logo qui tourne sur fond dégradé vert institutionnel (~2.4s) → page d'accueil.
2. **Accueil** : bouton "S'inscrire"/"Se connecter" → écran de choix Étudiant / Entreprise.
3. Choix du rôle → formulaire d'inscription (ou connexion) avec bouton Google (à finaliser,
   voir ci-dessous) → à la validation, le backend crée le compte et renvoie un token, l'app
   redirige automatiquement vers **le bon dashboard selon le rôle** (étudiant / entreprise / admin
   — l'admin n'a pas d'auto-inscription, un compte doit être créé manuellement en base).

## Ce qui reste à brancher pour une version 100% finalisée

- **Google Sign-In réel** : le package `google_sign_in` est dans `pubspec.yaml` mais l'appel
  n'est pas câblé (boutons "Continuer avec Google" affichent un message temporaire). Il faut :
    1. Configurer un `Client ID` OAuth (Google Cloud Console) pour Android/iOS/Web.
    2. Dans `register_screen.dart`/`login_screen.dart`, remplacer le `onPressed` du bouton Google
       par un appel `GoogleSignIn().signIn()`, récupérer le `idToken`, puis
       `POST /api/auth/google { idToken, role }`.
- **Upload de CV réel** : `file_picker` est dans `pubspec.yaml`. Dans `student_profile_screen.dart`,
  remplacer le `TODO` par : choix du fichier → `POST /profils/moi/cv/upload-url` → `PUT` du fichier
  vers l'URL signée renvoyée par Supabase Storage.
- **Image du logo/hero** : remplace le `Container` placeholder de la section Hero
  (`home_screen.dart`) par `DecorationImage(image: AssetImage('assets/image/imgyde.png'))`
  une fois l'image ajoutée dans `assets/image/`.
- Écrans encore volontairement simples (à styliser davantage si besoin) :
  détail d'une offre, gestion des comptes utilisateurs admin, contact entreprise↔étudiant.
