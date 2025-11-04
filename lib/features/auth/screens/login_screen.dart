import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';
import '../../home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ===== Controladores / estado =====
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===== Navegación / mensajes =====
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ===== Login email/pass (con verificación) =====
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
        final reloaded = _auth.currentUser;
        if (reloaded != null && reloaded.emailVerified) {
          _showSnackBar('✅ ¡Inicio de sesión exitoso!');
          _navigateToHome();
        } else {
          await _auth.signOut();
          _showSnackBar('🔒 Cuenta no verificada. Revisa tu correo/spam.');
          await user.sendEmailVerification();
        }
      }
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => '❌ Correo o contraseña incorrectos.',
        'wrong-password' => '❌ Correo o contraseña incorrectos.',
        'invalid-email' => '❌ Formato de correo inválido.',
        _ => '❌ Error de inicio de sesión: ${e.message}',
      };
      _showSnackBar(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== Social =====
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Error con Google Sign-In: ${e.message}');
    } catch (_) {
      _showSnackBar('Ocurrió un error inesperado al iniciar con Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithFacebook() async {
    _showSnackBar('Facebook Login requiere configuración adicional.');
  }

  // ===== Reset password =====
  Future<void> _sendPasswordResetEmail(String email) async {
    if (email.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar('Enviamos un correo de recuperación a $email.');
    } on FirebaseAuthException catch (e) {
      final msg = switch (e.code) {
        'user-not-found' => 'No existe una cuenta con ese correo.',
        'invalid-email' => 'Formato de correo inválido.',
        _ => 'Error al enviar recuperación: ${e.message}',
      };
      _showSnackBar(msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final ctrl = TextEditingController();
    final key = GlobalKey<FormState>();
    return showDialog(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Recuperar Contraseña'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Ingresa tu correo electrónico',
              hintText: 'ejemplo@correo.com',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'El correo es obligatorio.';
              if (!v.contains('@') || !v.contains('.'))
                return 'Ingresa un correo válido.';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
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
                : const Text('Enviar Enlace'),
          ),
        ],
      ),
    );
  }

  // ===== Decoración tipo "píldora" =====
  InputDecoration _pillDecoration({required String hint, Widget? suffix}) {
    const borderColor = Color(0xFFD9D9D9);
    final base = OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: borderColor, width: 1),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9E9E9E),
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: base,
      focusedBorder: base.copyWith(
        borderSide: const BorderSide(color: Colors.black, width: 1.3),
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minHeight: 0, minWidth: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final height = size.height;
    final logoH = (width * 0.16).clamp(48, 72).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,

      // *** NUEVO: AppBar igual a RegisterScreen ***
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
          'Iniciar Sesión',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            24,
          ), // antes 16 arriba (bajé un poco)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // (antes había SizedBox(height: 40) por la píldora) -> lo reducimos
              const SizedBox(height: 12),

              // Logo centrado
              Center(
                child: Image.asset(
                  'assets/kinesiology.png',
                  height: logoH,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              // ===== Título centrado =====
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: height * 0.18),
                child: const Center(
                  child: Text(
                    'Ingresa tus datos\npara iniciar\nsesión.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ===== CAMPOS PÍLDORA =====
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
                    tooltip: _showPassword ? 'Ocultar' : 'Ver contraseña',
                  ),
                ),
              ),

              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _showResetPasswordDialog,
                  child: const Text(
                    '¿Olvidaste la contraseña?',
                    style: TextStyle(
                      color: Color(0xFF6D6D6D),
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
                    backgroundColor: Colors.black,
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
                      style: TextStyle(color: Color(0xFF6D6D6D)),
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
                    borderColor: const Color(0xFF1877F2),
                    child: const Icon(
                      Icons.facebook,
                      size: 24,
                      color: Color(0xFF1877F2),
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
                      style: const TextStyle(color: Color(0xFF6D6D6D)),
                      children: const [
                        TextSpan(
                          text: 'Regístrate aquí',
                          style: TextStyle(
                            color: Colors.black87,
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

// Botón social circular
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
