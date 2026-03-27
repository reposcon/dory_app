import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/cyberpunk_scaffold.dart';
import '../../core/theme/glassmorphism.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/colors.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePass = true;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, llena ambos campos.')));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await SupabaseService.signIn(email, password);
      } else {
        await SupabaseService.signUp(email, password);
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error de Auth: ${e.message}'),
          backgroundColor: DoryColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: DoryColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, ingresa tu email para recuperar la contraseña.')));
      return;
    }

    try {
      await SupabaseService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Correo de recuperación enviado. Revisa tu bandeja de entrada.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al enviar correo: $e'),
          backgroundColor: DoryColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return CyberpunkScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: DoryColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: DoryColors.accent, blurRadius: 10, spreadRadius: 2)
                        ]
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Dory',
                    style: theme.textTheme.displayLarge?.copyWith(
                      letterSpacing: -1.0,
                      color: DoryColors.primary,
                      fontSize: 48,
                    ),
                  ),
                  Text(
                    '.',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: DoryColors.accent,
                      fontSize: 48,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Se me olvidó el slogan,\npero no cuánto gastaste en café ☕',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  letterSpacing: 0.5,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              GlassCard(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passCtrl,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      isObscure: _obscurePass,
                      isPasswordField: true,
                    ),
                    if (_isLogin)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resetPassword,
                          child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 12, color: DoryColors.primary)),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator(color: DoryColors.primary))
                    else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DoryColors.primary,
                            foregroundColor: DoryColors.bg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: DoryColors.primary.withOpacity(0.5),
                          ),
                          onPressed: _submit,
                          child: Text(_isLogin ? 'Ingresar' : 'Registrarse', style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? '¿No tienes cuenta? Crea una' : '¿Ya tienes cuenta? Ingresa',
                          style: TextStyle(color: DoryColors.textMuted),
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isObscure = false,
    bool isPasswordField = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DoryColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DoryColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        style: const TextStyle(color: DoryColors.text, fontSize: 14),
        decoration: InputDecoration(
          icon: Icon(icon, color: DoryColors.textMuted, size: 20),
          suffixIcon: isPasswordField 
              ? IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: DoryColors.textMuted, size: 20),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                )
              : null,
          border: InputBorder.none,
          hintText: label,
          hintStyle: TextStyle(color: DoryColors.textMuted),
        ),
      ),
    );
  }
}
