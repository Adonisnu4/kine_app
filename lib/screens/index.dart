import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _imageAnimation, _titleAnimation, _descriptionAnimation, _missionAnimation, _featuresAnimation, _planAnimation;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Future<QueryDocumentSnapshot?> _takenPlanFuture;

  // Función para obtener el plan activo del usuario (sin cambios)
  Future<QueryDocumentSnapshot?> _getTakenPlan() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;
    final String uid = currentUser.uid;
    final QuerySnapshot snapshot = await _firestore
        .collection('plan_tomados_por_usuarios')
        .where('usuarioId', isEqualTo: uid)
        .where('activo', isEqualTo: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }

  // Función para terminar un plan
  Future<void> _finishPlan(String planDocumentId) async {
    try {
      // 1. Se actualiza la base de datos
      await _firestore
          .collection('plan_tomados_por_usuarios')
          .doc(planDocumentId)
          .update({'activo': false});

      // ✅ 2. CORRECCIÓN: Se añade la verificación `if (mounted)`
      // Esto asegura que el widget todavía existe antes de intentar mostrar la notificación.
      if (mounted) {
        // Notificación flotante con el mensaje correcto
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Plan terminado'),
          ),
        );

        // Se actualiza la pantalla para que el plan desaparezca
        setState(() {
          _takenPlanFuture = _getTakenPlan();
        });
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Error al finalizar el plan: $e'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Tus animaciones (sin cambios)
    _imageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)));
    _titleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6, curve: Curves.easeIn)));
    _descriptionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8, curve: Curves.easeIn)));
    _missionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.easeIn)));
    _featuresAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.7, 1.0, curve: Curves.easeIn)));
    _planAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeIn)));
    
    _takenPlanFuture = _getTakenPlan();
    
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
                // --- TUS SECCIONES EXISTENTES (SIN CAMBIOS) ---
                const SizedBox(height: 20),
                FadeTransition(opacity: _imageAnimation, child: Image.asset('assets/kinesiology.png', height: 250)),
                const SizedBox(height: 48),
                FadeTransition(opacity: _titleAnimation, child: const Text('Unkineamigo', textAlign: TextAlign.center, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color.fromRGBO(52, 152, 219, 1)))),
                const SizedBox(height: 16),
                FadeTransition(opacity: _descriptionAnimation, child: const Text('Tu guía esencial para el movimiento, la salud y la fisioterapia. Descubre una vida sin límites.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.black87, fontStyle: FontStyle.italic))),
                const SizedBox(height: 48),
                FadeTransition(opacity: _missionAnimation, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [const Text('Nuestra Misión', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromRGBO(52, 152, 219, 1))), const SizedBox(height: 12), const Text('En Unkineamigo, creemos que el movimiento es la clave para una vida plena. Te ofrecemos herramientas y conocimiento para prevenir lesiones, fortalecer tu cuerpo y recuperar tu movilidad, todo de manera accesible y segura.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54))])),
                const SizedBox(height: 48),
                FadeTransition(opacity: _featuresAnimation, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [const Text('¿Qué te espera?', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromRGBO(52, 152, 219, 1))), const SizedBox(height: 20), _buildFeatureItem(icon: Icons.fitness_center, title: 'Guías de Ejercicios', description: 'Rutinas detalladas para cada parte del cuerpo, diseñadas por expertos.'), const SizedBox(height: 20), _buildFeatureItem(icon: Icons.shield, title: 'Prevención y Cuidado', description: 'Consejos prácticos para evitar lesiones y mantener tu cuerpo en óptimas condiciones.'), const SizedBox(height: 20), _buildFeatureItem(icon: Icons.school, title: 'Educación en Kinesiología', description: 'Recursos didácticos sobre anatomía, biomecánica y salud integral.')])),
                const SizedBox(height: 48),

                // --- SECCIÓN "MI PLAN ACTIVO" ---
                FadeTransition(
                  opacity: _planAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Mi Plan Activo',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color.fromRGBO(52, 152, 219, 1)),
                      ),
                      const SizedBox(height: 20),
                      FutureBuilder<QueryDocumentSnapshot?>(
                        future: _takenPlanFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return const Center(child: Text('Error al cargar tu plan.'));
                          }
                          if (!snapshot.hasData || snapshot.data == null) {
                            return const Center(child: Text('No has tomado ningún plan todavía.', textAlign: TextAlign.center));
                          }
                          
                          final planDocument = snapshot.data!;
                          final planData = planDocument.data() as Map<String, dynamic>;
                          final Timestamp? fechaInicio = planData['fecha_inicio'];
                          
                          return _buildPlanCard(
                            title: planData['planNombre'] ?? 'Plan sin nombre',
                            startDate: fechaInicio?.toDate(),
                            documentId: planDocument.id,
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

  // Widgets auxiliares (sin cambios)
  static Widget _buildFeatureItem({required IconData icon, required String title, required String description}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[Icon(icon, size: 40, color: const Color.fromRGBO(52, 152, 219, 1)), const SizedBox(height: 12), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)), const SizedBox(height: 4), Text(description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black54))]);
  }

  Widget _buildPlanCard({required String title, DateTime? startDate, required String documentId}) {
    final String formattedDate = startDate != null
        ? DateFormat('d \'de\' MMMM \'de\' yyyy', 'es_ES').format(startDate)
        : 'Fecha no registrada';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.assignment_turned_in, color: Colors.green, size: 40),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('Iniciado el: $formattedDate'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.play_arrow), label: const Text('Continuar'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)))),
                TextButton.icon(
                  onPressed: () {
                    _finishPlan(documentId);
                  },
                  icon: const Icon(Icons.check_circle_outline, color: Colors.orange),
                  label: const Text('Terminar', style: TextStyle(color: Colors.orange)),
                  style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}