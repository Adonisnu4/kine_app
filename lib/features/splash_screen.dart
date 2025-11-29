import 'package:flutter/material.dart';
// Importación de pantallas reales
import 'package:kine_app/features/auth/screens/login_screen.dart';
import 'package:kine_app/features/auth/screens/register_screen.dart';

/// =======================================================================
/// Punto de entrada de la aplicación.
/// =======================================================================
void main() {
  runApp(const KineApp());
}

/// =======================================================================
/// Paleta de colores centralizada.
/// Se reutiliza en todas las pantallas principales.
/// =======================================================================
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F6F6);

  static const blue = Color(0xFF47A5D6); // color primario (logo)
  static const grey = Color(0xFF7A8285); // gris del logo
  static const greyText = Color(0xFF8A9397);
  static const orange = Color(0xFFE28825); // acento general
  static const border = Color(0xFFE3E6E8); // borde sutil
}

/// =======================================================================
/// Widget raíz de la aplicación.
/// Configura el tema global y define la pantalla inicial.
/// =======================================================================
class KineApp extends StatelessWidget {
  const KineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Tema principal para toda la app
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.white,
        primaryColor: AppColors.blue,
        useMaterial3: false,

        // Estilo base para AppBar en toda la app
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),

        cardColor: AppColors.white,
      ),

      // Pantalla que se mostrará al abrir la app
      home: const WelcomeScreen(),
    );
  }
}

/// =======================================================================
/// Pantalla inicial de bienvenida.
/// Contiene:
///  - Logo principal
///  - Título + texto descriptivo
///  - Botón "Únete" (registro)
///  - Botón "Iniciar sesión"
/// =======================================================================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            // Cálculo responsivo del tamaño del logo
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

                  /// -----------------------------------------------------------
                  /// LOGO PRINCIPAL
                  /// -----------------------------------------------------------
                  Center(
                    child: Image.asset(
                      'assets/unkineamigo.png',
                      height: logoH,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const Spacer(),

                  /// -----------------------------------------------------------
                  /// Barra de acento naranja (recurso visual)
                  /// -----------------------------------------------------------
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  /// -----------------------------------------------------------
                  /// TÍTULO + DESCRIPCIÓN DEL PROYECTO
                  /// -----------------------------------------------------------
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Un Kine Amigo',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Un Kine, una comunidad. Encuentra el apoyo que necesitas para tu bienestar físico y emocional.',
                          style: TextStyle(
                            color: AppColors.greyText,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// -----------------------------------------------------------
                  /// BOTONES: REGISTRO Y LOGIN
                  /// -----------------------------------------------------------
                  Row(
                    children: [
                      /// BOTÓN PRIMARIO (azul)
                      /// Navega a la pantalla de registro
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            foregroundColor: Colors.white,
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

                      /// BOTÓN SECUNDARIO (outline)
                      /// Navega a login
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1.1,
                            ),
                            foregroundColor: AppColors.blue,
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

                  const SizedBox(height: 8),

                  /// -----------------------------------------------------------
                  /// TEXTO LEGAL / INFORMATICO
                  /// -----------------------------------------------------------
                  const Text(
                    'Al continuar aceptas nuestros términos.',
                    style: TextStyle(color: AppColors.greyText, fontSize: 11.5),
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
