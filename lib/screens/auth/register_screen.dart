import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_client.dart';
import '../../core/services/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

class RegisterScreen extends StatefulWidget {
  final String role; // 'etudiant' | 'entreprise'
  const RegisterScreen({super.key, required this.role});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
      // Après inscription, l'utilisateur doit vérifier son e-mail via un code OTP
      // avant de pouvoir se connecter.
      context.go('/auth/otp?email=${Uri.encodeComponent(_email.text.trim())}');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
          () => _error = "Une erreur est survenue. Vérifiez votre connexion.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Vert
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                        color: AppColors.darkGreen,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: AppColors.gold.withOpacity(0.5)),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isEtudiant
                                    ? 'ESPACE ÉTUDIANT'
                                    : 'ESPACE ENTREPRISE',
                                style: const TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isEtudiant
                                  ? 'Créer un compte étudiant'
                                  : 'Créer un compte entreprise',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isEtudiant
                                  ? 'Plateforme d\'orientation académique et d\'insertion professionnelle.'
                                  : 'Publiez vos offres et trouvez les meilleurs profils.',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Formulaire
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isEtudiant) ...[
                              _buildLabel('Prénom'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _prenom,
                                decoration: _inputDecoration(hint: 'Ex. Jean'),
                                validator: (v) => v!.isEmpty ? 'Requis' : null,
                              ),
                              const SizedBox(height: 20),
                            ],

                            _buildLabel(
                                isEtudiant ? 'Nom' : 'Nom de l\'entreprise'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nom,
                              decoration: _inputDecoration(
                                  hint: isEtudiant
                                      ? 'Ex. DUPONT'
                                      : 'Ex. KERITA sarl'),
                              validator: (v) => v!.isEmpty ? 'Requis' : null,
                            ),
                            const SizedBox(height: 20),

                            _buildLabel('Adresse email'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _email,
                              decoration:
                                  _inputDecoration(hint: 'exemple@gmail.com'),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requis';
                                if (!_emailRegex.hasMatch(v.trim()))
                                  return 'Adresse email invalide';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            _buildLabel('Téléphone'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _telephone,
                              keyboardType: TextInputType.phone,
                              decoration: _inputDecoration(hint: '671 681 076'),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requis';
                                final digits =
                                    v.replaceAll(RegExp(r'[^0-9]'), '');
                                if (digits.length < 8)
                                  return 'Numéro de téléphone invalide';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            if (!isEtudiant) ...[
                              _buildLabel('Secteur d\'activité'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _secteur,
                                decoration: _inputDecoration(
                                    hint: 'Sélectionnez un secteur'),
                                validator: (v) => v!.isEmpty ? 'Requis' : null,
                              ),
                              const SizedBox(height: 20),
                            ],

                            _buildLabel('Mot de passe'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              decoration: _inputDecoration(
                                hint: '••••••••',
                                suffix: TextButton(
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  child: Text(
                                    _obscure ? 'Afficher' : 'Masquer',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12),
                                  ),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? '6 caractères min.'
                                  : null,
                            ),

                            const SizedBox(height: 24),
                            // Case à cocher Conditions
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.sage,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _acceptConditions,
                                      onChanged: (v) => setState(
                                          () => _acceptConditions = v!),
                                      activeColor: AppColors.darkGreen,
                                      side:
                                          const BorderSide(color: Colors.grey),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "J'accepte les conditions générales et la politique de confidentialité.",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.darkGreen),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              InlineErrorText(_error!),
                            ],

                            const SizedBox(height: 32),
                            ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gold,
                                foregroundColor: AppColors.textDark,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: AppColors.textDark,
                                          strokeWidth: 2))
                                  : const Text('Créer votre compte',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                            ),

                            const SizedBox(height: 24),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  const Text('Déjà un compte ? ',
                                      style: TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 14)),
                                  GestureDetector(
                                    onTap: () => context.go('/auth/login'),
                                    child: const Text(
                                      "Connexion",
                                      style: TextStyle(
                                          color: AppColors.textDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return appInputDecoration(hint: hint, suffixIcon: suffix);
  }
}
