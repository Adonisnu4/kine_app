import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'plan_ejercicio_detalle_screen.dart'; // Asegúrate que la ruta sea correcta

class PlanEjercicioScreen extends StatefulWidget {
  const PlanEjercicioScreen({super.key});

  @override
  State<PlanEjercicioScreen> createState() => _PlanEjercicioScreenState();
}

class _PlanEjercicioScreenState extends State<PlanEjercicioScreen> {
  // Instancia de Firestore para realizar las consultas
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- LÓGICA DE FIRESTORE (SIN CAMBIOS) ---
  Future<void> _tomarPlan({
    required String planId,
    required String planNombre,
  }) async {
    // 1. VERIFICA SI HAY UN USUARIO LOGUEADO
    final User? usuarioActual = _auth.currentUser;

    if (usuarioActual == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: Debes iniciar sesión para empezar un plan.'),
        ),
      );
      return; // Detiene la ejecución
    }

    // 2. VERIFICA QUE LOS DATOS DEL PLAN SEAN VÁLIDOS
    if (planId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: El ID de este plan es inválido.'),
        ),
      );
      return; // Detiene la ejecución
    }

    final String usuarioId = usuarioActual.uid;

    // --- 3. NUEVO: VERIFICAR SI YA TIENE UN PLAN ACTIVO ---
    try {
      final planesActivosQuery = _firestore
          .collection('plan_tomados_por_usuarios')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('activo', isEqualTo: true) // La clave está aquí
          .limit(1); // Solo necesitamos saber si existe uno

      final querySnapshot = await planesActivosQuery.get();

      if (querySnapshot.docs.isNotEmpty) {
        // Si la lista NO está vacía, es porque ya tiene un plan activo.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text('Ya tienes un plan activo. ¡Termínalo primero!'),
          ),
        );
        return; // Detiene la ejecución
      }
    } catch (e) {
      // Error al consultar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al verificar tus planes: $e'),
        ),
      );
      return;
    }
    // --- FIN DE LA VERIFICACIÓN ---

    // 4. SI TODO ESTÁ BIEN, PREPARA LOS DATOS
    final Map<String, dynamic> planTomadoData = {
      'usuarioId': usuarioId,
      'planId': planId,
      'planNombre': planNombre,
      'fecha_inicio': FieldValue.serverTimestamp(),
      'activo': true, // El nuevo plan nace como 'activo'
      'progreso': {}, // El campo se llama "progreso" y es un mapa vacío
    };

    // 5. GUARDA LOS DATOS EN FIRESTORE
    try {
      await _firestore
          .collection('plan_tomados_por_usuarios')
          .add(planTomadoData);

      if (!mounted) return;
      // Muestra un mensaje de éxito al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('¡Plan "$planNombre" añadido a tu perfil!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Si algo sale mal al guardar, muestra un error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('No se pudo añadir el plan: $e'),
        ),
      );
    }
  }

  // --- BUILD WIDGET (CON CAMBIOS DE UI) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- CAMBIO UI: Fondo y AppBar consistentes ---
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Planes Disponibles'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('plan').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // Se corrigió la interpolación de texto aquí
            return Center(
              child: Text(
                '¡Ups! Ocurrió un error al cargar los planes: ${snapshot.error}', // Quitamos la doble barra
                textAlign: TextAlign.center,
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- CAMBIO UI: Estado vacío mejorado ---
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list_alt_rounded,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay planes disponibles',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pronto se añadirán nuevos planes de ejercicio.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Construye la lista de planes
          return ListView.builder(
            // --- CAMBIO UI: Padding para la lista ---
            padding: const EdgeInsets.all(8.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              final String planName =
                  (document.data() as Map<String, dynamic>)['nombre'] ??
                  'Plan sin título';
              final String planId = document.id;

              return Card(
                // --- CAMBIO UI: Márgenes y elevación sutiles ---
                margin: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 6.0,
                ),
                elevation: 1.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),

                  // --- CAMBIO UI: Leading pulido con CircleAvatar ---
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.deepPurple.shade50,
                    child: Icon(
                      Icons.fitness_center,
                      color: Colors.deepPurple.shade700,
                      size: 28,
                    ),
                  ),

                  title: Text(
                    planName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),

                  // Navegación al tocar (se mantiene la lógica)
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlanEjercicioDetalleScreen(
                          planId: planId,
                          planName: planName,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
