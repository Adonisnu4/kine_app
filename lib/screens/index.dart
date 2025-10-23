import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/services/user_exercise_taken.dart'; // Importa tu servicio

/// ----------------- TOKENS DE DISEÑO (paleta + tipografías) -----------------
class AppColors {
  static const primary  = Color(0xFF3498DB); // azul mock (sigue para acentos)
  static const teal     = Color(0xFF26C6DA); // teal del logo
  static const text     = Colors.black87;    // títulos negros
  static const textDim  = Colors.black54;    // párrafos
  static const card     = Colors.white;
  static const divider  = Color(0x14000000); // negro con baja opacidad
}

class AppText {
  // Títulos ahora en negro
  static const h1 = TextStyle(
    fontSize: 44, fontWeight: FontWeight.w800, color: AppColors.text, height: 1.10,
  );
  static const h2 = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.text,
  );

  // Subtítulo más elegante (sin cursiva, más interlineado, gris suave)
  static const lead = TextStyle(
    fontSize: 18, color: AppColors.textDim, height: 1.55, letterSpacing: .2, fontWeight: FontWeight.w400,
  );

  static const body = TextStyle(fontSize: 16, color: AppColors.textDim, height: 1.50, letterSpacing: .15);
  static const cardTitle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text);
}

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
  late Animation<double> _exercisesAnimation; // Nueva animación para los ejercicios

  // Instancia del servicio
  final UserExerciseTaken _userExerciseTaken = UserExerciseTaken();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Intervalos de aparición (se mantienen)
    _imageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeIn)),
    );
    _descriptionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeIn)),
    );
    _missionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)),
    );
    _featuresAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeIn)),
    );
    _exercisesAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // status bar con iconos oscuros
      child: Scaffold(
        // Fondo totalmente blanco
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760), // control ancho en desktop
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(height: 28),

                    // --- HERO ---
                    FadeTransition(
                      opacity: _imageAnimation,
                      child: Image.asset('assets/kinesiology.png', height: 220),
                    ),
                    const SizedBox(height: 28),

                    FadeTransition(
                      opacity: _titleAnimation,
                      child: const Text('Un Kine Amigo', textAlign: TextAlign.center, style: AppText.h1),
                    ),
                    const SizedBox(height: 12),

                    // Subtítulo elegante con ancho controlado
                    FadeTransition(
                      opacity: _descriptionAnimation,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 660),
                        child: const Text(
                          'Tu guía esencial para el movimiento, la salud y la fisioterapia. '
                          'Descubre una vida sin límites.',
                          textAlign: TextAlign.center,
                          style: AppText.lead,
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),
                    const _DividerTitle(text: '¿Cuál es Nuestra Misión?'),
                    const SizedBox(height: 12),

                    // --- Misión: versión más elegante (Patrón A aplicado) ---
                    FadeTransition(
                      opacity: _missionAnimation,
                      child: const _MissionBlock(
                        text:
                          'En Unkineamigo, creemos que el movimiento es la clave para una vida plena. '
                          'Te ofrecemos herramientas y conocimiento para prevenir lesiones, fortalecer tu cuerpo '
                          'y recuperar tu movilidad, todo de manera accesible y segura.',
                      ),
                    ),

                    const SizedBox(height: 32),
                    const _DividerTitle(text: '¿Qué te espera?'),
                    const SizedBox(height: 16),

                    // Features en layout responsive (Wrap)
                    FadeTransition(
                      opacity: _featuresAnimation,
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: const [
                          _FeatureTile(
                            icon: Icons.fitness_center,
                            title: 'Guías de Ejercicios',
                            desc: 'Rutinas detalladas diseñadas por expertos.',
                          ),
                          _FeatureTile(
                            icon: Icons.health_and_safety_rounded,
                            title: 'Prevención y Cuidado',
                            desc: 'Evita lesiones y mantente en óptimas condiciones.',
                          ),
                          _FeatureTile(
                            icon: Icons.school_rounded,
                            title: 'Educación en Kinesiología',
                            desc: 'Anatomía, biomecánica y salud integral.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                    const _DividerTitle(text: 'Mis Ejercicios Tomados'),
                    const SizedBox(height: 12),

                    // Lista de ejercicios (tu lógica intacta, solo envuelta en card suave)
                    FadeTransition(
                      opacity: _exercisesAnimation,
                      child: _CardSoft(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _userExerciseTaken.getUserTakenExercises(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            if (snapshot.hasError) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: Text('Error al cargar los ejercicios.', style: AppText.body)),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: Text('No has tomado ningún ejercicio.', style: AppText.body)),
                              );
                            }

                            final exercises = snapshot.data!;
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: exercises.length,
                              separatorBuilder: (_, __) => const Divider(height: 16, color: AppColors.divider),
                              itemBuilder: (context, index) {
                                final e = exercises[index];
                                return _ExerciseTile(
                                  title: e['nombre'],
                                  difficulty: e['dificultadNombre'],
                                  category: e['categoriaNombre'],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 40), // respiración antes del footer negro
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------- (Mantengo tu helper original si quieres seguir usando) -----------
  // Widget auxiliar para las características (se dejó una versión mejor abajo)
  static Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 40, color: AppColors.primary),
        const SizedBox(height: 12),
        Text(title, textAlign: TextAlign.center, style: AppText.cardTitle),
        const SizedBox(height: 4),
        Text(description, textAlign: TextAlign.center, style: AppText.body),
      ],
    );
  }
}

/// ----------------- COMPONENTES DE UI (solo estética) -----------------

class _DividerTitle extends StatelessWidget {
  final String text;
  const _DividerTitle({required this.text});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AppColors.divider, height: 1),
        const SizedBox(height: 12),
        Text(text, style: AppText.h2, textAlign: TextAlign.center),
      ],
    );
  }
}

class _CardSoft extends StatelessWidget {
  final Widget child;
  const _CardSoft({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

// Bloque de misión elegante: franja lateral gradiente + icono de comillas
class _MissionBlock extends StatelessWidget {
  final String text;
  const _MissionBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
        border: Border.all(color: AppColors.divider),
      ),
      child: IntrinsicHeight( // <- PATRÓN A: fuerza a que la fila mida alto del contenido
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // <- estira la franjita vertical
          children: [
            // franja lateral (SIN height infinito)
            Container(
              width: 6,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.teal],
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.format_quote_rounded, color: AppColors.teal, size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(text, textAlign: TextAlign.left, style: AppText.body),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  const _FeatureTile({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360, // para que el Wrap arme 2–3 columnas según ancho
      child: _CardSoft(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.teal,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.cardTitle),
                  const SizedBox(height: 2),
                  Text(desc, style: AppText.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final String title, difficulty, category;
  const _ExerciseTile({required this.title, required this.difficulty, required this.category});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.teal.withOpacity(.12),
        child: const Icon(Icons.fitness_center, color: AppColors.teal),
      ),
      title: Text(title, style: AppText.cardTitle),
      subtitle: Text('Dificultad: $difficulty · Categoría: $category', style: AppText.body),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
