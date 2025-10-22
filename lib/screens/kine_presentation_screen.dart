// lib/screens/kine_presentation_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/screens/booking_screen.dart'; // Importar BookingScreen

class KinePresentationScreen extends StatelessWidget {
  final String kineId;
  // kineData AHORA es obligatorio y contiene los datos reales
  final Map<String, String> kineData;

  const KinePresentationScreen({
    super.key,
    required this.kineId,
    required this.kineData, // Ya no es opcional
  });

  // Función de navegación que usa los datos reales
  void _navigateToBooking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          // 👈 USA LOS DATOS REALES PASADOS
          kineId: kineId,
          kineNombre: kineData['name']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usamos los datos pasados (kineData) directamente
    final String kineName = kineData['name'] ?? 'Kinesiólogo';
    final String kineTitle = kineData['specialization'] ?? 'Especialista';
    final String kinePhotoUrl =
        kineData['photoUrl'] ?? 'https://via.placeholder.com/150';
    final String kinePresentation =
        kineData['presentation'] ?? 'No hay presentación.';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil Profesional'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // Ya no se necesita FutureBuilder
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(kinePhotoUrl),
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: Text(
                kineName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Center(
              child: Text(
                kineTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.teal),
              ),
            ),
            const Divider(height: 30),
            Text(
              'Mi Carta de Presentación',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                kinePresentation,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _navigateToBooking(context);
                },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Agendar Cita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
