//El AuthGate es un widget que decide automáticamente si el usuario debe ver la pantalla de home o la pantalla de login.
// Importaciones necesarias
import 'package:firebase_auth/firebase_auth.dart'; // Manejo de autenticación con Firebase
import 'package:flutter/material.dart'; // Widgets básicos de Flutter
import '../features/home_screen.dart'; // Pantalla principal del chat
import '../features/auth/screens/login_screen.dart'; // Pantalla de inicio de sesión

// Widget que decide qué pantalla mostrar según si el usuario está logueado
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // StreamBuilder escucha el estado de autenticación en tiempo real
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance
          .authStateChanges(), // Cambios cuando el usuario inicia/cierra sesión
      builder: (context, snapshot) {
        // Mientras Firebase verifica el estado del usuario, muestra un loader
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si existe un usuario autenticado → ir a homescreem(principal)
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // Si NO hay usuario autenticado → mostrar pantalla de login
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
