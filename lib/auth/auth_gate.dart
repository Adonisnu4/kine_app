// lib/auth/auth_gate.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kine_app/features/chat/screens/contacts_screen.dart'; // Asegúrate de tener una pantalla de login para el caso de no estar autenticado
import '../features/auth/screens/login_screen.dart'; // <--- CAMBIA ESTO A TU RUTA REAL DE LOGIN

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha el estado de autenticación. Es la forma más segura de esperar al UID.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Esperando: Muestra una pantalla de carga mientras Firebase inicializa.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Logueado: El UID está disponible. Carga la pantalla de contactos.
        if (snapshot.hasData) {
          return const ContactsScreen();
        }
        // 3. No Logueado: Carga la pantalla de inicio de sesión.
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
