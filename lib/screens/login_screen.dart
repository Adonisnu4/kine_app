import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
// ERROR CORREGIDO: Las importaciones deben apuntar a la ubicaci贸n correcta.
// Si RegisterScreen y HomeScreen est谩n en la misma carpeta que LoginScreen:
import 'register_screen.dart'; // Importaci贸n de RegisterScreen
import 'home_screen.dart'; // Importaci贸n de HomeScreen

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

  // --- M茅todos de Autenticaci贸n y Navegaci贸n ---

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        // CORRECCI脫N 1: HomeScreen no es Home_screen.
        // CORRECCI脫N 2: No se usa 'const' en el constructor del widget porque se crea dentro de una funci贸n de construcci贸n ('builder').
        MaterialPageRoute(builder: (context) => HomeScreen()),
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
        message = 'No se encontr贸 un usuario con ese correo.';
      } else if (e.code == 'wrong-password') {
        message = 'La contrase帽a es incorrecta.';
      } else if (e.code == 'invalid-email') {
        message = 'El formato del correo es inv谩lido.';
      } else {
        message = 'Error de inicio de sesi贸n: ${e.message}';
      }
      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 馃殌 Google Sign-In (Sin cambios) ---
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return; // Usuario cancel贸
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
      _showSnackBar('Ocurri贸 un error inesperado al iniciar con Google.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 馃摌 Facebook Sign-In Placeholder (Sin cambios) ---
  Future<void> _loginWithFacebook() async {
    _showSnackBar(
      'Facebook Login: 隆Esta funcionalidad requiere configuraci贸n adicional!',
    );
  }

  // =========================================================
  // === 馃攽 M脡TODOS PARA RECUPERACI脫N DE CONTRASE脩A ===
  // =========================================================

  Future<void> _sendPasswordResetEmail(String email) async {
    if (email.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar(
        'Se ha enviado un correo de recuperaci贸n a $email. Revisa tu bandeja de entrada.',
      );
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'user-not-found') {
        message = 'No existe una cuenta con ese correo.';
      } else if (e.code == 'invalid-email') {
        message = 'El formato del correo es inv谩lido.';
      } else {
        message = 'Error al enviar el correo de recuperaci贸n: ${e.message}';
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
          title: const Text('Recuperar Contrase帽a'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: resetEmailController,
              decoration: const InputDecoration(
                labelText: 'Ingresa tu correo electr贸nico',
                hintText: 'ejemplo@correo.com',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El correo es obligatorio.';
                }
                if (!value.contains('@') || !value.contains('.')) {
                  return 'Ingresa un correo v谩lido.';
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

  // --- Widget Build ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inicio de Sesi贸n'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Campos de Correo y Contrase帽a
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Correo Electr贸nico',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Contrase帽a',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),

            const SizedBox(height: 12),

            // 2. Bot贸n de Recuperar Contrase帽a
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                // Se corrigi贸 el uso de 'const' en la llamada a la funci贸n (no aplica).
                onPressed: _isLoading ? null : _showResetPasswordDialog,
                child: const Text('驴Olvidaste tu contrase帽a?'),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Bot贸n de Iniciar Sesi贸n (Correo/Contrase帽a)
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
                        'Iniciar Sesi贸n',
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
                    'O inicia sesi贸n con',
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
                // Bot贸n de Google Sign-In
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

                // Bot贸n de Facebook Sign-In
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
                    // CORRECCI脫N 3: No se usa 'const' en el constructor del widget.
                    builder: (context) => RegisterScreen(),
                  ),
                );
              },
              child: const Text(
                '驴No tienes una cuenta? Reg铆strate aqu铆',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
