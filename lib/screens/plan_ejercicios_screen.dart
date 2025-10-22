import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Asegúrate de que esta importación esté
import 'plan_ejercicio_detalle_screen.dart';

class PlanEjercicioScreen extends StatefulWidget {
  const PlanEjercicioScreen({super.key});

  @override
  State<PlanEjercicioScreen> createState() => _PlanEjercicioScreenState();
}

class _PlanEjercicioScreenState extends State<PlanEjercicioScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ESTA ES LA FUNCIÓN CLAVE QUE HACE TODO AUTOMÁTICAMENTE
  Future<void> _tomarPlan({required String planId, required String planNombre}) async {
    // 1. VERIFICA SI HAY UN USUARIO LOGUEADO
    final User? usuarioActual = _auth.currentUser;

    if (usuarioActual == null) {
      // Si no hay usuario, muestra un error y no hace nada más.
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: El ID de este plan es inválido.'),
        ),
      );
      return; // Detiene la ejecución
    }

    // 3. SI TODO ESTÁ BIEN, OBTIENE EL ID DEL USUARIO Y PREPARA LOS DATOS
    final String usuarioId = usuarioActual.uid;

    final Map<String, dynamic> planTomadoData = {
      'usuarioId': usuarioId,
      'planId': planId,
      'planNombre': planNombre,
      'fecha_inicio': FieldValue.serverTimestamp(),
      'activo': true,
      'progreso': {}, // El campo se llama "progreso" y es un mapa vacío
    };

    // 4. GUARDA LOS DATOS EN FIRESTORE
    try {
      await _firestore.collection('plan_tomados_por_usuarios').add(planTomadoData);

      // Muestra un mensaje de éxito al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('¡Plan "$planNombre" añadido a tu perfil!'),
        ),
      );
    } catch (e) {
      // Si algo sale mal al guardar, muestra un error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('No se pudo añadir el plan: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('plan').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay planes de ejercicio disponibles.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          // Construye la lista de planes
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              // Es más seguro usar .get() para evitar errores si un campo no existe
              final String planName = (document.data() as Map<String, dynamic>)['nombre'] ?? 'Plan sin título';
              final String planId = document.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 3.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  leading: const Icon(Icons.fitness_center, color: Colors.deepPurple, size: 40),
                  title: Text(
                    planName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  // ESTE ES EL BOTÓN QUE DISPARA TODA LA LÓGICA AUTOMÁTICA
                  trailing: ElevatedButton(
                    onPressed: () {
                      // Al presionarlo, se llama a la función con los datos de este plan
                      _tomarPlan(planId: planId, planNombre: planName);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Empezar'),
                  ),
                  onTap: () {
                    // Si tocas la tarjeta, vas a los detalles
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