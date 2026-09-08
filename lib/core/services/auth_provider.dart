import 'package:flutter/foundation.dart';
import 'api_client.dart';

enum UserRole { etudiant, entreprise, administrateur }

UserRole roleFromString(String value) {
  switch (value) {
    case 'entreprise':
      return UserRole.entreprise;
    case 'administrateur':
    case 'admin':
      return UserRole.administrateur;
    case 'etudiant':
    case 'étudiant':
      return UserRole.etudiant;
    default:
      return UserRole.etudiant;
  }
}

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final String? profileId;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    this.profileId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'],
    email: json['email'],
    role: roleFromString(json['role']),
    profileId: json['profileId'],
  );
}

/// État d'authentification global de l'app, partagé via Provider.
class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _loading = true;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;

  final _api = ApiClient.instance;

  Future<void> tryAutoLogin() async {
    _loading = true;
    notifyListeners();

    final token = await _api.token;

    if (token != null) {
      try {
        final data = await _api.get('/auth/me');
        _user = AppUser.fromJson(data);
      } catch (_) {
        await _api.clearToken();
        _user = null;
      }
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> registerEtudiant({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required String password,
  }) async {
    await _api.post(
      '/auth/register/etudiant',
      {
        'nom': nom,
        'prenom': prenom,
        'email': email,
        if (telephone != null && telephone.isNotEmpty)
          'telephone': telephone,
        'password': password,
      },
      auth: false,
    );
    // On ne connecte pas automatiquement l'utilisateur après l'inscription
  }

  Future<void> registerEntreprise({
    required String nom,
    required String email,
    String? telephone,
    String? secteur,
    required String password,
  }) async {
    await _api.post(
      '/auth/register/entreprise',
      {
        'nom': nom,
        'email': email,
        if (telephone != null && telephone.isNotEmpty)
          'telephone': telephone,
        if (secteur != null && secteur.isNotEmpty)
          'secteur': secteur,
        'password': password,
      },
      auth: false,
    );
    // On ne connecte pas automatiquement l'utilisateur après l'inscription
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post(
      '/auth/login',
      {
        'email': email,
        'password': password,
      },
      auth: false,
    );

    await _afterAuthSuccess(data);
  }

  Future<void> _afterAuthSuccess(dynamic data) async {
    await _api.saveToken(data['token']);

    _user = AppUser.fromJson(data['user']);

    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    notifyListeners();
  }
}