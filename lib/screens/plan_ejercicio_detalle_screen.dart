// plan_ejercicio_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:kine_app/services/planes_ejercicios_service.dart';

// ----------------------------------------------------------------------
// PANTALLA DE DETALLE: MUESTRA UN SOLO PLAN
// ----------------------------------------------------------------------
class PlanEjercicioDetalleScreen extends StatefulWidget {
  final String planId;
  final String planName;

  const PlanEjercicioDetalleScreen({
    super.key,
    required this.planId,
    required this.planName,
  });

  @override
  State<PlanEjercicioDetalleScreen> createState() =>
      _PlanEjercicioDetalleScreenState();
}

class _PlanEjercicioDetalleScreenState
    extends State<PlanEjercicioDetalleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de ${widget.planName}'),
        backgroundColor: Colors.deepPurple,
      ),

      body: FutureBuilder<Map<String, dynamic>?>(
        // Llama a la función que obtiene un solo plan, usando el ID recibido
        future: ObtenerPlanEjercicio(widget.planId),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el plan: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final Map<String, dynamic> planData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> sesiones = planData['sesiones'] ?? [];

          if (planData == null) {
            return Center(
              child: Text(
                'El plan no fue encontrado.',
                style: const TextStyle(color: Colors.black),
              ),
            );
          }

          // --- Mostrar Datos ---
          final String nombre = planData['nombre'] ?? 'Plan sin nombre';
          final String descripcion =
              planData['descripcion'] ?? 'No hay descripción disponible.';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 3.0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ExpansionTile(
                  leading: const Icon(Icons.fitness_center, color: Colors.deepPurple),
                  title: Text(
                    'Sesión $numeroSesion',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text('${ejerciciosData.length} ejercicios'),
                  children: _buildEjerciciosList(ejerciciosData),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
