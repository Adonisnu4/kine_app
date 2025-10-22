import 'package:flutter/material.dart';

import 'package:kine_app/screens/login_screen.dart';
import 'package:kine_app/screens/register_screen.dart';

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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            // Logo proporcional al ancho para clavar la proporción del mock
            final logoH = (w * 0.22).clamp(90, 140).toDouble();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
              child: Column(
                children: [
                  const SizedBox(height: 48), // un poco menos que 60 para parecerse al mock

                  // Logo superior centrado
                  Center(
                    child: Image.asset(
                      'assets/kinesiology.png',
                      height: logoH,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(), // empuja todo hacia abajo

                  // Texto alineado a la izquierda y más abajo (encima de botones)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18.0), // separación del texto respecto a los botones
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Un Kine Amigo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,            // tamaño del mock
                              fontWeight: FontWeight.w600, // un pelín más fuerte
                              letterSpacing: 0.0,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'lorem ipsum',
                            style: TextStyle(
                              // gris suave como en el mock
                              color: Color(0xFF9E9E9E),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botones iguales al final
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Acción del botón "Únete"
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const RegisterScreen())
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size.fromHeight(50), // igual alto
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28), // pill
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Únete',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14), // separación como la maqueta
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            // Transición suave hacia LoginScreen
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.white, // borde bien visible
                              width: 1.2,
                            ),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(50), // igual alto
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28), // pill
                            ),
                          ),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(fontSize: 16),
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


