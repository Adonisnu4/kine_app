import 'package:flutter/material.dart';

import 'package:kine_app/services/planes_ejercicios_service.dart';

// ----------------------------------------------------------------------
// PANTALLA DE DETALLE: MUESTRA UN SOLO PLAN
// ----------------------------------------------------------------------
class PlanEjercicioDetalleScreen extends StatefulWidget {
  final String planId;

  // Recibe el ID del plan
  const PlanEjercicioDetalleScreen({super.key, required this.planId});

  @override
  State<PlanEjercicioDetalleScreen> createState() =>
      _PlanEjercicioDetalleScreenState();
}

class _PlanEjercicioDetalleScreenState
    extends State<PlanEjercicioDetalleScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo negro
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Detalle del Plan',
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: FutureBuilder<Map<String, dynamic>?>(
        // Llama a la función que obtiene un solo plan, usando el ID recibido
        future: ObtenerPlanEjercicio(widget.planId),

        builder: (context, snapshot) {
          // --- Manejo de Estados ---
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

          final Map<String, dynamic>? planData = snapshot.data;

          if (planData == null) {
            return Center(
              child: Text(
                'El plan no fue encontrado.',
                style: const TextStyle(color: Colors.black),
              ),
            );
          }
          // --- Fin Manejo de Estados ---

          // --- Mostrar Datos ---
          final String nombre = planData['nombre'] ?? 'Plan sin nombre';
          final String descripcion =
              planData['descripcion'] ?? 'No hay descripción disponible.';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ID: ${widget.planId}',
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Descripción:',
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  descripcion,
                  style: const TextStyle(color: Colors.black, fontSize: 18),
                ),
                // Aquí puedes añadir más detalles del plan
              ],
            ),
          );
        },
      ),
    );
  }
}
