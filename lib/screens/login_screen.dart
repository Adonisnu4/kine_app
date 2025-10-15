import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Asegúrate de que los archivos 'register_screen.dart' y 'home_screen.dart' existan
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ===================================
  // 1. CONTROLADORES Y ESTADO
  // ===================================
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===================================
  // 2. MÉTODOS DE UTILIDAD Y NAVEGACIÓN
  // ===================================

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ===================================
  // 3. LÓGICA DE LOGIN (CORREO/CONTRASEÑA)
  // OBLIGANDO LA VERIFICACIÓN DEL EMAIL
  // ===================================

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      // 3.1. Intentar iniciar sesión con correo y contraseña
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        // 3.2. OBLIGAR LA RECARGA DE DATOS: Necesario para obtener el estado actual de 'emailVerified'.
        await user.reload();

        // Obtener el estado actualizado del usuario después de la recarga
        final User? reloadedUser = _auth.currentUser;

        // 3.3. VERIFICACIÓN DEL EMAIL
        if (reloadedUser != null && reloadedUser.emailVerified) {
          // Si está verificado, permite el acceso
          _showSnackBar('✅ ¡Inicio de sesión exitoso!');
          _navigateToHome();
        } else {
          // Si NO está verificado:

          // Cerrar sesión para que no quede logueado
          await _auth.signOut();

          // Mostrar mensaje y ofrecer reenvío de enlace
          _showSnackBar(
            '🔒 Cuenta no verificada. Revisa tu bandeja de entrada o spam para el enlace de verificación.',
          );

          // Opcional: Reenviar correo
          if (user.email != null) {
            await user.sendEmailVerification();
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      // 3.4. Manejo de errores de autenticación
      if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = '❌ Error: Correo o contraseña incorrectos.';
      } else if (e.code == 'invalid-email') {
        message = '❌ Error: El formato del correo es inválido.';
      } else {
        message = '❌ Error de inicio de sesión: ${e.message}';
      }
      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // -----------------------------------------------------------

  // ===================================
  // 4. LÓGICA DE LOGIN (SOCIAL)
  // ===================================

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // Usuario canceló
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Error con Google Sign-In: ${e.message}');
    } catch (e) {
      _showSnackBar('Ocurrió un error inesperado al iniciar con Google.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithFacebook() async {
    _showSnackBar(
      'Facebook Login: Esta funcionalidad requiere configuración adicional!',
    );
  }

  // -----------------------------------------------------------

  // =========================================================
  // 5. MÉTODOS PARA RECUPERACIÓN DE CONTRASEÑA
  // =========================================================

  Future<void> _sendPasswordResetEmail(String email) async {
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar(
        'Se ha enviado un correo de recuperación a $email. Revisa tu bandeja de entrada.',
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No existe una cuenta con ese correo.';
      } else if (e.code == 'invalid-email') {
        message = 'El formato del correo es inválido.';
      } else {
        message = 'Error al enviar el correo de recuperación: ${e.message}';
      }
      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showResetPasswordDialog() async {
    final resetEmailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Recuperar Contraseña'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: 'Ingresa tu correo electrónico',
                hintText: 'ejemplo@correo.com',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El correo es obligatorio.';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Ingresa un correo válido.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (formKey.currentState!.validate()) {
                        Navigator.of(dialogContext).pop();

                        await _sendPasswordResetEmail(
                          resetEmailController.text.trim(),
                        );
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
        );
      },
    );
  }

  // -----------------------------------------------------------

  // ===================================
  // 6. WIDGET BUILD (Interfaz de Usuario)
  // ===================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Campos de Correo y Contraseña
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electrónico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),

            const SizedBox(height: 12),

            // 2. Botón de Recuperar Contraseña
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _showResetPasswordDialog,
                child: const Text('Olvidaste tu contraseña?'),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Botón de Iniciar Sesión
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ),

            const SizedBox(height: 30),

            // 4. Separador "o"
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'O inicia sesión con',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 30),

            // 5. Botones de Redes Sociales
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón de Google Sign-In
                SizedBox(
                  width: 150,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text('Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Botón de Facebook Sign-In
                SizedBox(
                  width: 150,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithFacebook,
                    icon: const Icon(Icons.facebook, color: Colors.blue),
                    label: const Text('Facebook'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // 6. Enlace a la Pantalla de Registro
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text(
                'No tienes una cuenta? Regístrate aquí',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
