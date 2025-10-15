import 'package:flutter/material.dart';

class KinePresentationScreen extends StatelessWidget {
  final String kineId;
  // Mantenemos kineData como un valor opcional de *datos iniciales*,
  // pero ya no lo usamos para evitar la carga en el FutureBuilder.
  final Map<String, String>? kineData;

  const KinePresentationScreen({
    super.key,
    required this.kineId,
    this.kineData,
  });

  /// 🚨 MODIFICADO: Esta función AHORA siempre simula la carga de datos por ID,
  /// ignorando el 'kineData' pasado en la navegación.
  Future<Map<String, String>> _fetchKinePresentation(String id) async {
    // SIMULACIÓN DE CARGA (Retraso de 1 segundo para simular red)
    await Future.delayed(const Duration(seconds: 1));

    // Si los datos originales SÍ fueron pasados (ej. desde el Directorio),
    // se usan como la fuente "fresca" si el ID coincide.
    if (kineData != null && kineData!['id'] == id) {
      // Incluye un sufijo para confirmar que son los datos frescos
      return {
        ...kineData!,
        'name': '${kineData!['name']}',
        'title':
            '${kineData!['specialization']}', // Usamos specialization como title
      };
    }

    // SIMULACIÓN DE FALLBACK: Carga por ID si no hay datos pasados o es otro ID.
    if (id == 'kine-101') {
      return {
        'id': 'kine-101',
        'name': 'Dr. Sofía Rojas (ID: $id)',
        'title': 'Kinesióloga Certificada en Neurorehabilitación',
        'presentation':
            '¡Hola! Soy la Dra. Rojas. Me especializo en rehabilitación neurológica y post-ictus. Mi objetivo es mejorar tu calidad de vida. (Carga por Fallback)',
        'photoUrl':
            'https://images.unsplash.com/photo-1559839734-2b7194cb90ab?fit=crop&w=600&q=80',
      };
    }
    throw Exception('Datos de kinesiólogo no disponibles para ID: $id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil Profesional'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // 🚨 MODIFICADO: Llama SIEMPRE a _fetchKinePresentation(kineId) para forzar la recarga.
      body: FutureBuilder<Map<String, String>>(
        future: _fetchKinePresentation(kineId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Error: Perfil del Kinesiólogo no encontrado. ${snapshot.error}',
              ),
            );
          }

          final kine = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(kine['photoUrl']!),
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    kine['name']!,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    kine['title']!,
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
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    kine['presentation'] ??
                        'Este kinesiólogo no tiene carta de presentación.',
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Navegando a Agendar Cita'),
                        ),
                      );
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
          );
        },
      ),
    );
  }
}
