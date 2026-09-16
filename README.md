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
   Pour Google Sign-In, ajoute aussi
   `--dart-define=GOOGLE_CLIENT_ID=<client-id-oauth>`.
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
3. Choix du rôle → formulaire d'inscription ou connexion, y compris avec Google. Une inscription
   classique passe une seule fois par la validation OTP ; une connexion ultérieure ne la redemande pas.
   Le backend crée ensuite le compte et renvoie un token, et l'app
   redirige automatiquement vers **le bon dashboard selon le rôle** (étudiant / entreprise / admin
   — l'admin n'a pas d'auto-inscription, un compte doit être créé manuellement en base).

## Configuration externe nécessaire

- Configure les identifiants OAuth Google pour chaque plateforme Flutter et
  renseigne le même client ID dans `GOOGLE_CLIENT_ID` côté backend.
- Configure Firebase pour les plateformes ciblées afin d'activer les notifications.
- Crée les buckets Supabase documentés dans le README du backend.
