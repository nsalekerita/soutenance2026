import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_client.dart';
import '../../core/services/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_card.dart';

/// Écran de saisie du code OTP à 6 chiffres envoyé par e-mail, utilisé pour
/// vérifier l'adresse e-mail après l'inscription (et lors d'une tentative de
/// connexion sur un compte pas encore vérifié).
class OtpVerifyScreen extends StatefulWidget {
  final String email;
  const OtpVerifyScreen({super.key, required this.email});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  bool _resending = false;
  String? _error;
  String? _info;
  Timer? _cooldownTimer;
  int _cooldown = 0;

  @override
  void dispose() {
    _code.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _verifier() async {
    if (_code.text.trim().length != 6) {
      setState(() => _error = 'Le code doit contenir 6 chiffres.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.verifierCodeInscription(
          email: widget.email, code: _code.text.trim());
      if (!mounted) return;
      final role = auth.user?.role;
      switch (role) {
        case UserRole.etudiant:
          context.go('/etudiant');
          break;
        case UserRole.entreprise:
          context.go('/entreprise');
          break;
        case UserRole.administrateur:
          context.go('/administrateur');
          break;
        case null:
          context.go('/auth/login');
          break;
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
          () => _error = 'Une erreur est survenue. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _renvoyer() async {
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.renvoyerCodeInscription(widget.email);
      if (!mounted) return;
      setState(
          () => _info = 'Un nouveau code a été envoyé à votre adresse e-mail.');
      _startCooldown();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(
          () => _error = 'Une erreur est survenue. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _resending = false);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mark_email_read_outlined,
                        color: AppColors.darkGreen, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'Vérifiez votre adresse e-mail',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Un code à 6 chiffres a été envoyé à ${widget.email}. Saisissez-le ci-dessous pour activer votre compte.",
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _code,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '000000',
                        filled: true,
                        fillColor: AppColors.paper,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      InlineErrorText(_error!),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 16),
                      Text(_info!,
                          style: const TextStyle(
                              color: AppColors.darkGreen, fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _verifier,
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
                          : const Text('Vérifier',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed:
                            (_resending || _cooldown > 0) ? null : _renvoyer,
                        child: Text(
                          _cooldown > 0
                              ? 'Renvoyer le code (${_cooldown}s)'
                              : 'Renvoyer le code',
                          style: const TextStyle(
                              color: AppColors.darkGreen,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
