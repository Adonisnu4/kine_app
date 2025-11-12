// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/features/auth/services/auth_service.dart';
import 'register_screen.dart';
import '../../home_screen.dart';
import 'package:kine_app/shared/widgets/app_dialog.dart';

class AppColors {
  static const blue = Color(0xFF47A5D6);   // del logo
  static const orange = Color(0xFFE28825); // del logo
  static const greyText = Color(0xFF8A9397);
  static const fieldBorder = Color(0xFFD9D9D9);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = cred.user;
      if (user != null) {
        await user.reload();
        if (!mounted) return;
        final reloaded = _auth.currentUser;

        if (reloaded != null && reloaded.emailVerified) {
          _navigateToHome();
        } else {
          await _auth.signOut();
          if (!mounted) return;
          setState(() => _isLoading = false);
          await showAppWarningDialog(
            context: context,
            icon: Icons.lock_outline_rounded,
            title: 'Cuenta no verificada',
            content: 'Revisa tu correo (y spam) para activar la cuenta.',
          );
          await user.sendEmailVerification();
        }
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'Correo o contraseña incorrectos.',
        'wrong-password' => 'Correo o contraseña incorrectos.',
        'invalid-email' => 'Formato de correo inválido.',
        _ => 'Error de inicio de sesión: ${e.message}',
      };
      if (mounted) setState(() => _isLoading = false);
      await showAppErrorDialog(
        context: context,
        icon: Icons.error_outline_rounded,
        title: 'Error de inicio de sesión',
        content: msg,
      );
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      _navigateToHome();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      await showAppErrorDialog(
        context: context,
        icon: Icons.g_mobiledata_rounded,
        title: 'Error con Google',
        content: e.toString(),
      );
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithFacebook();
      if (!mounted) return;
      _navigateToHome();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      await showAppErrorDialog(
        context: context,
        icon: Icons.facebook_rounded,
        title: 'Error con Facebook',
        content: e.toString(),
      );
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    if (email.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      setState(() => _isLoading = false);
      await showAppInfoDialog(
        context: context,
        icon: Icons.mark_email_read_rounded,
        title: 'Correo enviado',
        content: 'Enviamos un correo de recuperación a $email.',
      );
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No existe una cuenta con ese correo.',
        'invalid-email' => 'Formato de correo inválido.',
        _ => 'Error al enviar recuperación: ${e.message}',
      };
      if (mounted) setState(() => _isLoading = false);
      await showAppErrorDialog(
        context: context,
        icon: Icons.alternate_email_rounded,
        title: 'Error de recuperación',
        content: msg,
      );
    } finally {
      if (mounted && _isLoading) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final ctrl = TextEditingController();
    final key = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            icon: const Icon(
              Icons.lock_reset_rounded,
              color: AppColors.blue,
              size: 48,
            ),
            title: const Text(
              'Recuperar contraseña',
              textAlign: TextAlign.center,
            ),
            content: Form(
              key: key,
              child: TextFormField(
                controller: ctrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'ejemplo@correo.com',
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'El correo es obligatorio.';
                  }
                  if (!v.contains('@') || !v.contains('.')) {
                    return 'Ingresa un correo válido.';
                  }
                  return null;
                },
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(d).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (key.currentState!.validate()) {
                          Navigator.of(d).pop();
                          await _sendPasswordResetEmail(ctrl.text.trim());
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enviar enlace'),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _pillDecoration({required String hint, Widget? suffix}) {
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: AppColors.fieldBorder, width: 1),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: AppColors.greyText,
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: base,
      focusedBorder: base.copyWith(
        borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // 🔸 logo más grande
    final logoH = (width * 0.26).clamp(70, 220).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          'Iniciar sesión',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Center(
                child: Image.asset(
                  'assets/kine-naranjo.png',
                  height: logoH,
                  fit: BoxFit.contain,
                ),
              ),
              // 🔸 más aire entre logo y título
              const SizedBox(height: 100),
              const Center(
                child: Text(
                  'Ingresa tus datos\npara iniciar sesión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // 🔸 bajamos todo lo demás
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _pillDecoration(hint: 'Correo electrónico*'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: _pillDecoration(
                  hint: 'Contraseña*',
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _showPassword = !_showPassword),
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black54,
                      size: 22,
                    ),
                    splashRadius: 20,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _showResetPasswordDialog,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                  ),
                  child: const Text(
                    '¿Olvidaste la contraseña?',
                    style: TextStyle(
                      color: AppColors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Ingresar', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(
                    child: Divider(color: Color(0xFFE6E6E6), thickness: 1),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'O inicia sesión con',
                      style: TextStyle(color: AppColors.greyText),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Color(0xFFE6E6E6), thickness: 1),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _SocialCircle(
                    onTap: _isLoading ? null : _loginWithGoogle,
                    borderColor: const Color(0xFFDB4437),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  _SocialCircle(
                    onTap: _isLoading ? null : _loginWithFacebook,
                    borderColor: AppColors.blue,
                    child: const Icon(
                      Icons.facebook,
                      size: 24,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                  child: Text.rich(
                    TextSpan(
                      text: '¿No tienes una cuenta? ',
                      style: const TextStyle(color: AppColors.greyText),
                      children: const [
                        TextSpan(
                          text: 'Regístrate aquí',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialCircle extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color borderColor;
  const _SocialCircle({
    required this.child,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.6),
          color: Colors.white,
        ),
        child: child,
      ),
    );
  }
}
