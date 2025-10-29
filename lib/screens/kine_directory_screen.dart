// Archivo: lib/screens/kine_directory_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'kine_presentation_screen.dart';
import 'profile_screen.dart';

class KineDirectoryScreen extends StatefulWidget {
  const KineDirectoryScreen({super.key});

  @override
  State<KineDirectoryScreen> createState() => _KineDirectoryScreenState();
}

class _KineDirectoryScreenState extends State<KineDirectoryScreen> {
  late Future<List<Map<String, String>>> _kineListFuture;

  @override
  void initState() {
    super.initState();
    _kineListFuture = _fetchKinesiologistsFromFirestore();
  }

  void _reloadKineList() {
    setState(() {
      _kineListFuture = _fetchKinesiologistsFromFirestore();
    });
  }

  /// Carga los kinesiólogos desde la colección 'usuarios'
  Future<List<Map<String, String>>> _fetchKinesiologistsFromFirestore() async {
    try {
      //CAMBIO: Apuntamos a la colección 'usuarios'
      final querySnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          // CAMBIO: Filtramos por un campo que solo tienen los kinesiólogos.
          .where('specialization', isGreaterThan: '')
          // --- INICIO DE LA IMPLEMENTACIÓN DEL ORDEN ---
          // 1. Ordena por 'perfilDestacado' (true irá antes que false)
          .orderBy('perfilDestacado', descending: true)
          // 2. (Opcional) Luego ordena alfabéticamente
          .orderBy('nombre_completo', descending: false)
          // --- FIN DE LA IMPLEMENTACIÓN ---
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final kineList = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>; // Aseguramos el tipo
        return {
          'id': doc.id,
          'name': (data['nombre_completo'] as String?) ?? 'Kinesiólogo(a)',
          'specialization':
              (data['specialization'] as String?) ?? 'Sin especialización',
          'photoUrl':
              (data['imagen_perfil'] as String?) ??
              'https://via.placeholder.com/150',
          'experience':
              (data['experience']?.toString()) ??
              '0', // Usamos .toString() para asegurar String
          'presentation':
              (data['carta_presentacion'] as String?) ??
              'No ha publicado su carta.',
        };
      }).toList();

      return kineList;
    } catch (e) {
      debugPrint('Error al cargar kinesiólogos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: ${e.toString()}')),
        );
      }
      return [];
    }
  }

  void _navigateToKineScreen(Map<String, String> kine) async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final Widget destinationScreen;

    if (currentUserId != null && kine['id'] == currentUserId) {
      destinationScreen = const ProfileScreen();
    } else {
      destinationScreen = KinePresentationScreen(
        kineId: kine['id']!,
        kineData: kine,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Directorio de Kinesiólogos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, String>>>(
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
