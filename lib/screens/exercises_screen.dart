import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa el servicio de ejercicios
import 'package:kine_app/services/exercises_service.dart';
// Importa la nueva pantalla de detalles
import 'package:kine_app/screens/excersice_detail_screen.dart';


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
            
            // Si no hay documentos, muestra un mensaje
            if (documents.isEmpty) {
              return const Center(child: Text('No hay ejercicios disponibles.'));
            }

            return ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                // Obtiene los datos de cada documento
                final data = documents[index];
                
                // Obtiene la URL de la imagen, con un fallback por si no existe
                final imageUrl = data['imagen'] ?? 'https://via.placeholder.com/150?text=No+Image';

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    
                    // CORRECCIÓN APLICADA AQUÍ: Usa SizedBox y ClipRRect para un cuadrado
                    leading: SizedBox(
                      width: 60,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0), // Esquinas redondeadas
                        child: CachedNetworkImage(
        imageUrl: "https://kineapp.blob.core.windows.net/imagenes/imagen_test.jpg",
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
                        ),
                      ),
                    ),

                    title: Text(
                      data['nombre'] ?? 'Nombre no disponible',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
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
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blueAccent, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExerciseDetailsScreen(
                            exerciseId: data['id'],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
          
          return const Center(child: Text('No hay ejercicios disponibles.'));
        },
      ),
    );
  }
}