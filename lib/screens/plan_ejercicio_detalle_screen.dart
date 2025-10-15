// plan_ejercicio_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _PlanEjercicioDetalleScreenState extends State<PlanEjercicioDetalleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de ${widget.planName}'),
        backgroundColor: Colors.deepPurple,
      ),
      // Solo necesitamos UN FutureBuilder para leer el plan
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('plan').doc(widget.planId).get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el plan: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el plan.'));
          }

          final Map<String, dynamic> planData = snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> sesiones = planData['sesiones'] ?? [];

          if (sesiones.isEmpty) {
            return const Center(child: Text('Este plan aún no tiene sesiones asignadas.'));
          }

          return ListView.builder(
            itemCount: sesiones.length,
            itemBuilder: (context, index) {
              final Map<String, dynamic> sesionActual = sesiones[index] as Map<String, dynamic>;
              final int numeroSesion = sesionActual['numero_sesion'] ?? (index + 1);
              final Map<String, dynamic> ejerciciosData = sesionActual['ejercicios'] ?? {};

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

  // --- ¡FUNCIÓN SIMPLIFICADA! ---
  // Ya no necesita un FutureBuilder, porque ya tenemos todos los datos.
  List<Widget> _buildEjerciciosList(Map<String, dynamic> ejerciciosData) {
    if (ejerciciosData.isEmpty) {
      return [const ListTile(title: Text('No hay ejercicios en esta sesión.'))];
    }

    // Mapeamos los valores directamente a un ListTile
    return ejerciciosData.values.map<Widget>((ejercicioInfo) {
      final info = ejercicioInfo as Map<String, dynamic>;

      // Leemos los datos directamente del mapa
      final String nombreEjercicio = info['nombre_ejercicio'] ?? 'Nombre no encontrado';
      final int tiempoSegundos = info['tiempo_segundos'] ?? 0;

      // Devolvemos el widget directamente, sin esperas
      return ListTile(
        contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0, bottom: 8.0, top: 4.0),
        leading: const Icon(Icons.directions_run, color: Colors.orange),
        title: Text(nombreEjercicio, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Text(
          '$tiempoSegundos seg',
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
      );
    }).toList();
  }
}