import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// --- 👇 IMPORTANTE 👇 ---
import 'package:intl/date_symbol_data_local.dart';
import 'auth/auth_gate.dart';
import 'firebase_options.dart';
import 'package:kine_app/screens/auth/screens/login_screen.dart';
import 'package:kine_app/screens/home_screen.dart';
import 'package:kine_app/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- 👇 ESTA LÍNEA ES CORRECTA 👇 ---
  // Carga los datos de formato para el idioma "Español"
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
