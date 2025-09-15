import 'package:flutter/material.dart';
import 'package:kine_app/services/exercises_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseDetailsScreen extends StatelessWidget {
  final String exerciseId;

  const ExerciseDetailsScreen({super.key, required this.exerciseId});

  // Nueva función para guardar el ejercicio para el usuario actual
 Future<void> _takeExercise(BuildContext context, String exerciseId) async {
  final User? user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debes iniciar sesión para tomar un ejercicio.')),
    );
    return;
  }

  try {
    // Usamos el UID del usuario actual para acceder a su documento
    final userExerciseRef = FirebaseFirestore.instance
        .collection('ejercicios_tomados_por_usuarios')
        .doc(user.uid)
        .collection('mis_ejercicios')
        .doc(exerciseId); // ID del documento para el ejercicio tomado

    await userExerciseRef.set({
      'fecha_tomado': FieldValue.serverTimestamp(),
      'completado': false,
      'ejercicio': FirebaseFirestore.instance.doc('ejercicios/$exerciseId'), // Referencia al documento original del ejercicio
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Ejercicio tomado con éxito!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al tomar el ejercicio: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final ExercisesService exercisesService = ExercisesService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Ejercicio'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: exercisesService.getExerciseById(exerciseId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final exercise = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['nombre'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dificultad: ${exercise['dificultadNombre']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Categoría: ${exercise['categoriaNombre']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Descripción:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    exercise['descripcion'] ?? 'No hay descripción disponible.',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(), // Empuja el botón al final de la pantalla
                  ElevatedButton.icon(
                    onPressed: () => _takeExercise(context, exerciseId),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Tomar este ejercicio'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50), // Ancho completo
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }

          return const Center(child: Text('No se encontraron los detalles del ejercicio.'));
        },
      ),
    );
  }
}