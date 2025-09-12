import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa el servicio de ejercicios
import 'package:kine_app/services/exercises_service.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Crea una instancia de tu servicio
    final ExercisesService exercisesService = ExercisesService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejercicios Disponibles'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Llama al método que obtiene todos los detalles
        future: exercisesService.getExercisesWithDetails(),
        builder: (context, snapshot) {
          // Si el estado de la conexión es de espera, muestra un indicador de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si hay un error, lo muestra
          if (snapshot.hasError) {
            return Center(child: Text('Algo salió mal: ${snapshot.error}'));
          }

          // Si los datos están listos, los muestra en una lista
          if (snapshot.hasData) {
            final documents = snapshot.data!;
            
            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                // Obtiene los datos de cada documento
                final data = documents[index];
                
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    title: Text(
                      // Usa el nombre del ejercicio
                      data['nombre'] ?? 'Nombre no disponible',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    // Muestra la dificultad y la categoría en el subtítulo
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dificultad: ${data['dificultadNombre'] ?? 'No disponible'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Categoría: ${data['categoriaNombre'] ?? 'No disponible'}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    leading: const Icon(Icons.fitness_center, color: Colors.blueAccent),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Presionaste en ${data['nombre'] ?? 'un ejercicio'}')),
                      );
                    },
                  ),
                );
              },
            );
          }
          
          // En caso de que no haya datos, muestra un mensaje
          return const Center(child: Text('No hay ejercicios disponibles.'));
        },
      ),
    );
  }
}
