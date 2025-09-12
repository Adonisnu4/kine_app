import 'package:flutter/material.dart';

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Animaciones para cada elemento
  late Animation<double> _imageAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _descriptionAnimation;
  late Animation<double> _missionAnimation;
  late Animation<double> _featuresAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ), // Duración total de la animación
    );

    // Definimos los intervalos para que cada elemento aparezca en un momento diferente
    _imageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );
    _descriptionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );
    _missionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );
    _featuresAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // Iniciamos la animación
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(230, 245, 255, 1),
              Color.fromARGB(255, 255, 255, 255),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const SizedBox(height: 60),

                // Imagen animada
                FadeTransition(
                  opacity: _imageAnimation,
                  child: Image.asset('kinesiology.png', height: 250),
                ),
                const SizedBox(height: 48),

                // Título animado
                FadeTransition(
                  opacity: _titleAnimation,
                  child: const Text(
                    'Unkineamigo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Color.fromRGBO(52, 152, 219, 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Descripción animada
                FadeTransition(
                  opacity: _descriptionAnimation,
                  child: const Text(
                    'Tu guía esencial para el movimiento, la salud y la fisioterapia. Descubre una vida sin límites.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Sección: Nuestra Misión animada
                FadeTransition(
                  opacity: _missionAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Nuestra Misión',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(52, 152, 219, 1),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'En Unkineamigo, creemos que el movimiento es la clave para una vida plena. Te ofrecemos herramientas y conocimiento para prevenir lesiones, fortalecer tu cuerpo y recuperar tu movilidad, todo de manera accesible y segura.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Sección: ¿Qué encontrarás? - Con iconos animados
                FadeTransition(
                  opacity: _featuresAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '¿Qué te espera?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(52, 152, 219, 1),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _buildFeatureItem(
                        icon: Icons.fitness_center,
                        title: 'Guías de Ejercicios',
                        description:
                            'Rutinas detalladas para cada parte del cuerpo, diseñadas por expertos.',
                      ),
                      const SizedBox(height: 20),

                      _buildFeatureItem(
                        icon: Icons.shield,
                        title: 'Prevención y Cuidado',
                        description:
                            'Consejos prácticos para evitar lesiones y mantener tu cuerpo en óptimas condiciones.',
                      ),
                      const SizedBox(height: 20),

                      _buildFeatureItem(
                        icon: Icons.school,
                        title: 'Educación en Kinesiología',
                        description:
                            'Recursos didácticos sobre anatomía, biomecánica y salud integral.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    // Se cambia de Row a Column para que los elementos se apilen verticalmente y se centren
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 40, color: const Color.fromRGBO(52, 152, 219, 1)),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }
}
