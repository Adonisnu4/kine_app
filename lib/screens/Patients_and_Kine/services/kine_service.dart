// lib/features/patients/services/kine_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KineService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Carga los kinesiólogos desde la colección 'usuarios'
  Future<List<Map<String, dynamic>>> getKineDirectory() async {
    try {
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('specialization', isGreaterThan: '')
          .orderBy('perfilDestacado', descending: true)
          .orderBy('nombre_completo', descending: false)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final kineList = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': (data['nombre_completo'] as String?) ?? 'Kinesiólogo(a)',
          'specialization':
              (data['specialization'] as String?) ?? 'Sin especialización',
          'photoUrl':
              (data['imagen_perfil'] as String?) ??
              'https://via.placeholder.com/150',
          'experience': (data['experience']?.toString()) ?? '0',
          'presentation':
              (data['carta_presentacion'] as String?) ??
              'No ha publicado su carta.',
        };
      }).toList();

      return kineList;
    } catch (e) {
      debugPrint('Error al cargar kinesiólogos en servicio: $e');
      // Re-lanza un error más específico para que la UI lo maneje
      throw Exception('Fallo al obtener el directorio de Kinesiólogos.');
    }
  }
}
