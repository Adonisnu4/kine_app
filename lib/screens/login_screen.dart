import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  // --- Métodos de Autenticación y Navegación ---

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

  Future<void> _login() async {
    setState(() => _isLoading = true);

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No se encontró un usuario con ese correo.';
      } else if (e.code == 'wrong-password') {
        message = 'La contraseña es incorrecta.';
      } else if (e.code == 'invalid-email') {
        message = 'El formato del correo es inválido.';
      } else {
        message = 'Error de inicio de sesión: ${e.message}';
      }
      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 🚀 Google Sign-In (Sin cambios) ---
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

  // --- 📘 Facebook Sign-In Placeholder (Sin cambios) ---
  Future<void> _loginWithFacebook() async {
    _showSnackBar(
      'Facebook Login: ¡Esta funcionalidad requiere configuración adicional!',
    );
  }

  // =========================================================
  // === 🔑 NUEVOS MÉTODOS PARA RECUPERACIÓN DE CONTRASEÑA ===
  // =========================================================

  // 1. Lógica central para el envío de correo de recuperación.
  Future<void> _sendPasswordResetEmail(String email) async {
    if (email.isEmpty) return; // Validación de seguridad

    // El indicador de carga se activa aquí
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
      // El indicador de carga se desactiva
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 2. Método para mostrar el Diálogo de Recuperación (la nueva interfaz).
  Future<void> _showResetPasswordDialog() async {
    // Usamos un nuevo controlador para que no interfiera con el campo de login
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
                // Validación básica de formato
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
                        // Cierra el diálogo antes de iniciar la operación
                        Navigator.of(dialogContext).pop();

                        // Llama a la lógica de envío
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

  // --- Widget Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesión'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Campos de Correo y Contraseña (Sin cambios)
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

            // 2. Botón de Recuperar Contraseña (CAMBIO AQUÍ)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                // ¡AQUÍ LLAMAMOS AL NUEVO DIÁLOGO!
                onPressed: _isLoading ? null : _showResetPasswordDialog,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Botón de Iniciar Sesión (Correo/Contraseña) (Sin cambios)
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

            // 4. Separador "o" (Sin cambios)
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

            // 5. Botones de Redes Sociales (Sin cambios)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Botón de Google Sign-In
                SizedBox(
                  width: 150,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    icon: const Icon(
                      Icons.g_mobiledata,
                    ), // Icono de Google simple
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

            // 6. Enlace a la Pantalla de Registro (Sin cambios)
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
                '¿No tienes una cuenta? Regístrate aquí',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
