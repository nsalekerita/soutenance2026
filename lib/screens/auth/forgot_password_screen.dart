import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_client.dart';
import '../../core/services/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Écran "Mot de passe oublié" en deux étapes : demande de code par e-mail,
/// puis saisie du code + nouveau mot de passe.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyReset = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _codeDemande = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _demanderCode() async {
    if (!_formKeyEmail.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.demanderReinitialisationMotDePasse(_email.text.trim());
      if (!mounted) return;
      setState(() {
        _codeDemande = true;
        _info =
            'Si un compte existe pour cet e-mail, un code de réinitialisation a été envoyé.';
      });
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
          () => _error = 'Une erreur est survenue. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reinitialiser() async {
    if (!_formKeyReset.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.reinitialiserMotDePasse(
        email: _email.text.trim(),
        code: _code.text.trim(),
        nouveauMotDePasse: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Mot de passe réinitialisé. Connectez-vous.')),
      );
      context.go('/auth/login');
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
          () => _error = 'Une erreur est survenue. Vérifiez votre connexion.');
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
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _codeDemande ? _buildResetForm() : _buildEmailForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_reset_outlined,
              color: AppColors.darkGreen, size: 40),
          const SizedBox(height: 16),
          const Text(
            'Mot de passe oublié',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          const Text(
            'Entrez votre adresse e-mail : nous vous enverrons un code pour réinitialiser votre mot de passe.',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _email,
            decoration: _inputDecoration(hint: 'votre@email.com'),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Requis';
              if (!_emailRegex.hasMatch(v.trim()))
                return 'Adresse email invalide';
              return null;
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            InlineErrorText(_error!),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _demanderCode,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.textDark,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.textDark, strokeWidth: 2))
                : const Text('Envoyer le code',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => context.go('/auth/login'),
              child: const Text('Retour à la connexion',
                  style: TextStyle(
                      color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    return Form(
      key: _formKeyReset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_outlined,
              color: AppColors.darkGreen, size: 40),
          const SizedBox(height: 16),
          const Text(
            'Réinitialiser le mot de passe',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 10),
          Text(
            "Entrez le code reçu par e-mail à ${_email.text.trim()} ainsi que votre nouveau mot de passe.",
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _code,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
            decoration:
                _inputDecoration(hint: '000000').copyWith(counterText: ''),
            validator: (v) => (v == null || v.trim().length != 6)
                ? 'Code à 6 chiffres requis'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            decoration: _inputDecoration(
              hint: 'Nouveau mot de passe',
              suffix: IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? '6 caractères min.' : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            InlineErrorText(_error!),
          ],
          if (_info != null) ...[
            const SizedBox(height: 16),
            Text(_info!,
                style:
                    const TextStyle(color: AppColors.darkGreen, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _reinitialiser,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.textDark,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.textDark, strokeWidth: 2))
                : const Text('Réinitialiser',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: _loading ? null : _demanderCode,
              child: const Text('Renvoyer le code',
                  style: TextStyle(
                      color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return appInputDecoration(hint: hint, suffixIcon: suffix);
  }
}
