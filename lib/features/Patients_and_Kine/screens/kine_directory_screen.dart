// lib/features/patients/screens/kine_directory_screen.dart (CÓDIGO NUEVO)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Importa el nuevo servicio
import 'package:kine_app/features/Patients_and_Kine/services/kine_service.dart';
// Las pantallas importadas deben usar las nuevas rutas
import 'kine_presentation_screen.dart';
import '../../auth/screens/profile_screen.dart';

class KineDirectoryScreen extends StatefulWidget {
  const KineDirectoryScreen({super.key});

  @override
  State<KineDirectoryScreen> createState() => _KineDirectoryScreenState();
}

class _KineDirectoryScreenState extends State<KineDirectoryScreen> {
  // Inicializa el nuevo servicio
  final KineService _kineService = KineService();
  late Future<List<Map<String, dynamic>>>
  _kineListFuture; // El tipo de retorno ahora es dynamic

  @override
  void initState() {
    super.initState();
    // Usa el servicio
    _kineListFuture = _kineService.getKineDirectory();
  }

  void _reloadKineList() {
    setState(() {
      // Recarga usando el servicio
      _kineListFuture = _kineService.getKineDirectory();
    });
  }

  void _navigateToKineScreen(Map<String, dynamic> kine) async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final Widget destinationScreen;

    if (currentUserId != null && kine['id'] == currentUserId) {
      destinationScreen = const ProfileScreen();
    } else {
      destinationScreen = KinePresentationScreen(
        kineId: kine['id']!,
        kineData: kine
            .cast<
              String,
              String
            >(), // Aseguramos el tipo si la presentación lo necesita
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );

    _reloadKineList();
  }

  @override
  Widget build(BuildContext context) {
    // ... (El build del widget sigue igual, solo usa el nuevo tipo Future)
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Directorio de Kinesiólogos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Cambia a dynamic
        future: _kineListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Ocurrió un error al cargar: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay kinesiólogos disponibles en este momento.'),
            );
          }

          final kineList = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            itemCount: kineList.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 80, endIndent: 15),
            itemBuilder: (context, index) {
              final kine = kineList[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(kine['photoUrl']!),
                  backgroundColor: Colors.grey.shade200,
                ),
                title: Text(
                  kine['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(kine['specialization']!),
                trailing: const Icon(Icons.chevron_right, color: Colors.teal),
                onTap: () => _navigateToKineScreen(kine),
              );
            },
          );
        },
      ),
    );
  }
}
