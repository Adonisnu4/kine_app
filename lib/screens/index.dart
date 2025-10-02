import 'package:flutter/material.dart';
import 'package:kine_app/services/user_exercise_taken.dart'; // Importa tu servicio

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Animaciones para cada elemento
  late Animation<double> _imageAnimation;
  late Animation<double> _titleAnimation;
  late Animation<double> _descriptionAnimation;
  late Animation<double> _missionAnimation;
  late Animation<double> _featuresAnimation;
  late Animation<double>
  _exercisesAnimation; // Nueva animación para los ejercicios

  // Instancia del servicio
  final UserExerciseTaken _userExerciseTaken = UserExerciseTaken();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2500,
      ), // Aumentamos la duración total
    );

    // Definimos los intervalos para que cada elemento aparezca en un momento diferente
    _imageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
      ),
    );
    _descriptionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
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
    _exercisesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
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
      appBar: AppBar(
        title: const Text('Inicio'),
        backgroundColor: Colors.blueAccent,
      ),
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
                const SizedBox(height: 20),

                // --- SECCIONES EXISTENTES (ANIMADAS) ---
                FadeTransition(
                  opacity: _imageAnimation,
                  child: Image.asset(
                    'assets/kinesiology.png',
                    height: 250,
                  ), // Asegúrate de que esta sea la ruta correcta
                ),
                const SizedBox(height: 48),

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

                const SizedBox(height: 48),

                // --- NUEVA SECCIÓN: EJERCICIOS TOMADOS ---
                FadeTransition(
                  opacity: _exercisesAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Mis Ejercicios Tomados',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(52, 152, 219, 1),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _userExerciseTaken.getUserTakenExercises(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Error al cargar los ejercicios.'),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('No has tomado ningún ejercicio.'),
                            );
                          }

                          final exercises = snapshot.data!;

                          return ListView.builder(
                            shrinkWrap:
                                true, // Importante para usarlo dentro de SingleChildScrollView
                            physics:
                                const NeverScrollableScrollPhysics(), // Deshabilita el scroll interno
                            itemCount: exercises.length,
                            itemBuilder: (context, index) {
                              final exercise = exercises[index];
                              return _buildExerciseCard(
                                title: exercise['nombre'],
                                difficulty: exercise['dificultadNombre'],
                                category: exercise['categoriaNombre'],
                              );
                            },
                          );
                        },
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

  // Widget auxiliar para las características (sin cambios)
  static Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
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

  // Nuevo widget auxiliar para las tarjetas de ejercicios
  Widget _buildExerciseCard({
    required String title,
    required String difficulty,
    required String category,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: const Icon(
          Icons.fitness_center,
          color: Color.fromRGBO(52, 152, 219, 1),
          size: 40,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Dificultad: $difficulty'),
            Text('Categoría: $category'),
          ],
        ),
      ),
    );
  }
}
