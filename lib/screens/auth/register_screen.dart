import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_client.dart';
import '../../core/services/auth_provider.dart';
import '../../theme/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  final String role; // 'etudiant' | 'entreprise'
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _secteur = TextEditingController();
  final _password = TextEditingController();
  bool _acceptConditions = false;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  bool get isEtudiant => widget.role == 'etudiant';

  @override
  void dispose() {
    _nom.dispose();
    _prenom.dispose();
    _email.dispose();
    _telephone.dispose();
    _secteur.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptConditions) {
      setState(() => _error = "Merci d'accepter les conditions générales.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      if (isEtudiant) {
        await auth.registerEtudiant(
          nom: _nom.text.trim(),
          prenom: _prenom.text.trim(),
          email: _email.text.trim(),
          telephone: _telephone.text.trim(),
          password: _password.text,
        );
      } else {
        await auth.registerEntreprise(
          nom: _nom.text.trim(),
          email: _email.text.trim(),
          telephone: _telephone.text.trim(),
          secteur: _secteur.text.trim(),
          password: _password.text,
        );
      }
      if (!mounted) return;
      context.go(isEtudiant ? '/etudiant' : '/entreprise');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = "Une erreur est survenue. Vérifie ta connexion et réessaie.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _glassField({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text(isEtudiant ? 'Créer un compte étudiant' : 'Créer un compte entreprise', 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
              const SizedBox(height: 20),
              if (isEtudiant) ...[
                TextFormField(controller: _prenom, decoration: _glassField(hint: 'Prénom')),
                const SizedBox(height: 12),
              ],
              TextFormField(controller: _nom, decoration: _glassField(hint: isEtudiant ? 'Nom' : "Nom de l'entreprise")),
              const SizedBox(height: 12),
              TextFormField(controller: _email, decoration: _glassField(hint: 'Email')),
              const SizedBox(height: 12),
              TextFormField(controller: _password, obscureText: _obscure, 
                decoration: _glassField(hint: 'Mot de passe', 
                  suffix: IconButton(icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off), 
                  onPressed: () => setState(() => _obscure = !_obscure)))),
              const SizedBox(height: 20),
              CheckboxListTile(
                value: _acceptConditions,
                onChanged: (v) => setState(() => _acceptConditions = v ?? false),
                title: const Text("J'accepte les conditions générales", style: TextStyle(fontSize: 12)),
              ),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: AppColors.darkGreen),
                child: _loading ? const CircularProgressIndicator() : const Text('S\'inscrire'),
              ),
              TextButton(onPressed: () => context.go('/auth/login'), child: const Text("Déjà un compte ? Connexion")),
            ],
          ),
        ),
      ),
    );
  }
}
