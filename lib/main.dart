// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/auth_gate.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importación necesaria

//SCREENS
import 'package:kine_app/screens/login_screen.dart';
import 'package:kine_app/screens/home_screen.dart';
import 'package:kine_app/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // ✅ LÍNEA AÑADIDA QUE CORRIGE EL ERROR
  // Esta línea carga los formatos de fecha para el idioma español.
  await initializeDateFormatting('es_ES', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // Usuario logeado
            return const HomeScreen();
          } else {
            // Usuario no logeado
            return const WelcomeScreen(); // Asegúrate de que esta pantalla exista
          }
        },
      ),
    );
  }
}

// Clase de ejemplo para WelcomeScreen
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScreen(); // O la pantalla de bienvenida que corresponda
  }
}