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

class _PlanEjercicioDetalleScreenState
    extends State<PlanEjercicioDetalleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de ${widget.planName}'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
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
              final int numeroSesion = sesionActual['numero_sesion'] ?? 0;
              final Map<String, dynamic> ejerciciosData = sesionActual['ejercicios'] ?? {};

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                elevation: 2.0,
                child: ExpansionTile(
                  leading: const Icon(Icons.fitness_center, color: Colors.green),
                  title: Text(
                    'Sesión $numeroSesion',
                    style: const TextStyle(fontWeight: FontWeight.bold),
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

  List<Widget> _buildEjerciciosList(Map<String, dynamic> ejerciciosData) {
    if (ejerciciosData.isEmpty) {
      return [
        const ListTile(
          title: Text('No hay ejercicios en esta sesión.'),
        )
      ];
    }
    
    return ejerciciosData.values.map<Widget>((ejercicioInfo) {
      final info = ejercicioInfo as Map<String, dynamic>;
      final int repeticiones = info['repeticiones'] ?? 0;
      
      final dynamic idEjercicioPathRaw = info['id_ejercicio'];
      if (idEjercicioPathRaw == null || idEjercicioPathRaw is! String || idEjercicioPathRaw.isEmpty) {
        return const ListTile(
          contentPadding: EdgeInsets.only(left: 32.0, right: 16.0),
          leading: Icon(Icons.warning, color: Colors.red),
          title: Text('Dato de ejercicio corrupto'),
          subtitle: Text('Falta ID en la base de datos'),
        );
      }
      
      final String idEjercicioPath = idEjercicioPathRaw;
      final String ejercicioId = idEjercicioPath.split('/').last;

      if (ejercicioId.isEmpty) {
          return const ListTile(
            contentPadding: EdgeInsets.only(left: 32.0, right: 16.0),
            leading: Icon(Icons.warning, color: Colors.red),
            title: Text('ID de ejercicio no válido'),
          );
      }

      return FutureBuilder<DocumentSnapshot>(
        // --- CORRECCIÓN CLAVE AQUÍ ---
        // Se asegura de que la búsqueda se haga en la colección 'ejercicio' (singular)
        future: _firestore.collection('ejercicio').doc(ejercicioId).get(),
        // -----------------------------
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListTile(
              contentPadding: EdgeInsets.only(left: 32.0, right: 16.0),
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
              title: Text('Cargando...'),
            );
          }

          if (snapshot.hasError || !snapshot.data!.exists) {
            return ListTile(
              contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: Text('Ejercicio no encontrado'),
              subtitle: Text('ID: $ejercicioId'),
            );
          }

          final ejercicioDocData = snapshot.data!.data() as Map<String, dynamic>;
          final String nombreEjercicio = ejercicioDocData['nombre'] ?? 'Nombre desconocido';
          
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 32.0, right: 16.0),
            leading: const Icon(Icons.directions_run, color: Colors.orange),
            title: Text(nombreEjercicio),
            trailing: Text(
              'Reps: $repeticiones',
              style: const TextStyle(color: Colors.black54),
            ),
          );
        },
      );
    }).toList();
  }
}