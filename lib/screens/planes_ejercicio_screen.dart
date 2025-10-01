import 'package:flutter/material.dart';
import 'package:kine_app/screens/plan_ejercicio_detalle_screen.dart';
import 'package:kine_app/services/planes_ejercicios_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanesDeEjercicio extends StatelessWidget {
  const PlanesDeEjercicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes de Ejercicio'),
      ),
      // 🥇 Usa FutureBuilder para manejar el estado asíncrono
      body: FutureBuilder<List<DocumentSnapshot>>(
        // Llama a tu función aquí
        future: obtenerTodosLosPlanesEjercicio(), 
        
        builder: (context, snapshot) {
          // 🛑 1. Manejar el estado de Error
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }

          // ⏳ 2. Manejar el estado de Carga (Waiting)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ✅ 3. Mostrar los Datos (Done)
          // `snapshot.data` es la lista de DocumentSnapshot devuelta
          final List<DocumentSnapshot> documentos = snapshot.data ?? [];

          // Si no hay documentos, informa al usuario
          if (documentos.isEmpty) {
            return const Center(child: Text('No hay planes de ejercicio disponibles.'));
          }

          // Usamos ListView.builder para construir la lista eficientemente
          return ListView.builder(
            itemCount: documentos.length,
            itemBuilder: (context, index) {
              // Obtenemos los datos del documento actual
              // Debemos hacer un casting a Map<String, dynamic>
              final data = documentos[index].data() as Map<String, dynamic>?;

              // Obtener el nombre. Asumo que tienes un campo 'nombre'
              final nombrePlan = data?['nombre'] ?? 'Nombre no disponible';

              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(nombrePlan), // Aquí mostramos el nombre
                subtitle: Text('ID: ${documentos[index].id}'),
                onTap: () {
                  // Usamos Navigator.push para ir a la nueva página
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      // Pasamos los datos del plan a la nueva página
                      builder: (context) => PlanEjercicioDetalleScreen(
                        planId: documentos[index].id,
                        
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
