import 'package:flutter/material.dart';
// importa tus screens reales
import 'package:kine_app/features/auth/screens/login_screen.dart';
import 'package:kine_app/features/auth/screens/register_screen.dart';

void main() {
  runApp(const KineApp());
}

/// colores centralizados
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F6F6);

  static const blue = Color(0xFF47A5D6);    // primario (del logo)
  static const grey = Color(0xFF7A8285);    // gris del logo
  static const greyText = Color(0xFF8A9397);
  static const orange = Color(0xFFE28825);  // acento
  static const border = Color(0xFFE3E6E8);
}

class KineApp extends StatelessWidget {
  const KineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.white,
        primaryColor: AppColors.blue,
        useMaterial3: false,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        cardColor: AppColors.white,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
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
                  // logo
                  Center(
                    child: Image.asset(
                      'assets/unkineamigo.png',
                      height: logoH,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Spacer(),
                  // acento naranja
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
                  // textos
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
                  // botones
                  Row(
                    children: [
                      // PRIMARIO (azul)
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
                      // SECUNDARIO (outline gris-azul y texto azul)
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

                      // 👉 si quieres que este sea naranja, reemplaza el OutlinedButton de arriba por:
                      /*
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () { ... },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.orange,
                              width: 1.1,
                            ),
                            foregroundColor: AppColors.orange,
                            ...
                          ),
                          child: const Text('Iniciar sesión'),
                        ),
                      ),
                      */
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Al continuar aceptas nuestros términos.',
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontSize: 11.5,
                    ),
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
