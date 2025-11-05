import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'auth/auth_gate.dart';
import 'firebase_options.dart';
import 'package:kine_app/features/auth/screens/login_screen.dart';
import 'package:kine_app/features/home_screen.dart';
import 'package:kine_app/features/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Carga los datos de formato para el idioma "Español"
  await initializeDateFormatting('es_ES', null);

  //Conexion con subapase
  await sb.Supabase.initialize(
    url: 'https://gwnbsjunvxiexmqpthkv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3bmJzanVudnhpZXhtcXB0aGt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxOTE3NTEsImV4cCI6MjA3NDc2Nzc1MX0.ZpQIlCgkRYr7SwDY7mtWHqTsgiOzsDqciXSvqugBk8U',
  );
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
