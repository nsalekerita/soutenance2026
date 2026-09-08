import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/services/api_client.dart';
import '../../core/services/auth_provider.dart';
import '../../theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  bool _rememberMe = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = context.read<AuthProvider>();
      await auth.login(
        email: _email.text.trim().toLowerCase(), 
        password: _password.text.trim()
      );
      
      if (!mounted) return;

      final role = auth.user?.role;
      if (role == null) {
        setState(() => _error = 'Connexion impossible. Réessayez.');
        return;
      }
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
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Connexion impossible. Vérifiez vos identifiants.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              children: [
                Expanded(child: _buildLeftSide()),
                Expanded(child: _buildRightSide()),
              ],
            );
          } else {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: _buildRightSide(isMobile: true),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildLeftSide() {
    return Container(
      color: const Color(0xFF0B3D2E), // Vert sombre spécifique
      padding: const EdgeInsets.all(60),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                painter: TrianglePatternPainter(),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF2F6F2),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset('assets/image/logoIAI.jpg',
                      errorBuilder: (_, __, ___) => const Icon(Icons.school, color: Color(0xFF0B3D2E), size: 28)),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Institut Africain d'Informatique",
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'IAI Horizon',
                style: TextStyle(
                  color: Colors.white, 
                  fontSize: 52, 
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2
                ),
              ),
              const SizedBox(height: 12),
              Container(width: 60, height: 2, color: AppColors.gold),
              const SizedBox(height: 32),
              const SizedBox(
                width: 420,
                child: Text(
                  "Un seul compte pour accéder à votre orientation académique, votre insertion professionnelle et tous les services numériques de l'institut.",
                  style: TextStyle(color: Colors.white70, fontSize: 17, height: 1.6),
                ),
              ),
              const Spacer(),
              const Text(
                "Institut Africain d'Informatique — Espace de connexion ",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightSide({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 100),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2A)),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Entrez vos identifiants pour accéder à votre espace.',
                  style: TextStyle(color: Color(0xFF6B6B67), fontSize: 15),
                ),
                const SizedBox(height: 48),
                
                const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C2C2A))),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _email,
                  decoration: _inputDecoration(hint: 'votre@email.com', icon: Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Veuillez entrer votre email';
                    if (!_emailRegex.hasMatch(v.trim())) return 'Adresse email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                
                const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF2C2C2A))),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: Color(0xFF6B6B67)),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Veuillez entrer votre mot de passe' : null,
                ),
                
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v!),
                        activeColor: const Color(0xFF0B3D2E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('Se souvenir de moi', style: TextStyle(fontSize: 14, color: Color(0xFF6B6B67))),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 14, color: Color(0xFF2C2C2A))),
                    ),
                  ],
                ),
                
                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 14)),
                ],
                
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF082D22), // Vert ultra sombre
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _loading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(height: 32),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text('Pas encore de compte ? ', style: TextStyle(color: Color(0xFF6B6B67), fontSize: 14)),
                      TextButton(
                        onPressed: () => context.go('/auth'),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                        child: const Text("S'inscrire", style: TextStyle(color: Color(0xFF2C2C2A), fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
      prefixIcon: Icon(icon, size: 22, color: Colors.grey.shade600),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF2F2EB), // Beige très clair
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0B3D2E), width: 1.5),
      ),
    );
  }
}

class TrianglePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    double step = 80.0;

    for (double x = -step; x < size.width + step; x += step) {
      for (double y = -step; y < size.height + step; y += step) {
        path.moveTo(x, y);
        path.lineTo(x + step, y + step);
        path.moveTo(x + step, y);
        path.lineTo(x, y + step);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
