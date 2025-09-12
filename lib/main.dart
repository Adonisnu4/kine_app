// Tu código main.dart no cambia. Es exactamente como lo vimos antes.
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_page.dart';
import 'screens/home_screen.dart'; // Asegúrate de tener tu pantalla principal aquí

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
            return const HomeScreen(); // O la pantalla que tengas con el BottomNavigationBar
          } else {
            // Usuario no logeado
            return const LoginPage();
          }
        },
      ),
    );
  }
}

// Y aquí va el resto de tu código para MainScreen con el BottomNavigationBar.
// ...
