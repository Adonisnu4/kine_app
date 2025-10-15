import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'plan_ejercicio_detalle_screen.dart'; // Asegúrate de que esta ruta sea correcta

class PlanEjercicioScreen extends StatefulWidget {
  const PlanEjercicioScreen({super.key});

  @override
  State<PlanEjercicioScreen> createState() => _PlanEjercicioScreenState();
}

class _PlanEjercicioScreenState extends State<PlanEjercicioScreen> {
  // Instancia de Firestore para realizar las consultas
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Planes de Ejercicio'),
        backgroundColor: Theme.of(context).primaryColor,
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
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                DocumentSnapshot document = snapshot.data!.docs[index];
                Map<String, dynamic> data = document.data()! as Map<String, dynamic>;

                // Obtenemos el nombre del plan para pasarlo a la siguiente pantalla
                final String planName = data['nombre'] ?? 'Plan sin título';

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  elevation: 2.0,
                  child: ListTile(
                    leading: const Icon(Icons.fitness_center, color: Colors.blue),
                    title: Text(
                      planName, // Usamos la variable local planName
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Se corrigió la interpolación de texto aquí
                    subtitle: Text('ID del Plan: ${document.id}'), // Quitamos la doble barra
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlanEjercicioDetalleScreen(
                            planId: document.id,
                            planName: planName, // ¡AHORA SÍ PASAMOS EL planName!
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text(
                'Aún no hay planes de ejercicio disponibles. ¡Es hora de crear algunos!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }
        },
      ),
    );
  }
}
