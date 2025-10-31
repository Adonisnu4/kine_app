import 'package:flutter/material.dart';

import 'package:kine_app/screens/auth/screens/login_screen.dart';
import 'package:kine_app/screens/auth/screens/register_screen.dart';

void main() {
  runApp(const KineApp());
}

class KineApp extends StatelessWidget {
  const KineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ← fondo claro
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final logoH = (w * 0.22).clamp(90, 140).toDouble();

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 30.0,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Logo centrado
                  Center(
                    child: Image.asset(
                      'assets/kinesiology.png',
                      height: logoH,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(),

                  // Títulos alineados a la izquierda
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Un Kine Amigo',
                            style: TextStyle(
                              color: Colors.black, // ← negro en claro
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.0,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Un Kine, una comunidad. Encuentra el apoyo que necesitas para tu bienestar físico y emocional.',
                            style: TextStyle(
                              color: Color(0xFF6D6D6D), // ← gris suave en claro
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botones invertidos para tema claro
                  Row(
                    children: [
                      // Primario sólido (negro)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black, // ← negro sólido
                            foregroundColor: Colors.white, // texto blanco
                            minimumSize: const Size.fromHeight(50),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Únete',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Secundario contorneado (negro)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.black, // ← borde negro
                              width: 1.2,
                            ),
                            foregroundColor: Colors.black, // ← texto negro
                            minimumSize: const Size.fromHeight(50),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
