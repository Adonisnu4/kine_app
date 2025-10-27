import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart'; // 👈 IMPORTA ESTO

// TUS IMPORTS
import 'auth/auth_gate.dart'; // Asumo que tienes esto
import 'firebase_options.dart';
import 'package:kine_app/screens/login_screen.dart'; // Asumo que tienes esto
import 'package:kine_app/screens/home_screen.dart';
import 'package:kine_app/screens/splash_screen.dart'; // Asumo que tienes esto

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 👈 AÑADE ESTA LÍNEA
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
            // Asegúrate de que WelcomeScreen exista, si no, usa LoginScreen
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}

// Clase 'WelcomeScreen' que usas en tu main.dart
// (Si ya la tienes en otro archivo, ignora est
