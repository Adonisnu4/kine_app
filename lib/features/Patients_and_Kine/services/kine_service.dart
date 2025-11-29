// lib/features/patients/services/kine_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Servicio encargado de cargar información de kinesiólogos
/// desde la colección 'usuarios' en Firestore.
///
/// Este archivo NO dibuja UI. Es exclusivamente lógica de acceso a datos.
class KineService {
  // Instancia principal de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene el listado de kinesiólogos que tienen algún valor en el campo
  /// 'specialization'. Se considera kinesiólogo a cualquier usuario que haya
  /// definido una especialización.
  ///
  /// Ordena los resultados de la siguiente manera:
  /// 1. Primero por 'perfilDestacado' (descendente)
  /// 2. Luego por 'nombre_completo' (ascendente)
  ///
  /// Retorna una lista de mapas, donde cada mapa representa un kinesiólogo.
  Future<List<Map<String, dynamic>>> getKineDirectory() async {
    try {
      // Consulta a Firestore:
      // - Filtra usuarios que tienen un valor en 'specialization'
      // - Ordena primero por perfil destacado
      // - Luego ordena por nombre
      final querySnapshot = await _firestore
          .collection('usuarios')
          .where('specialization', isGreaterThan: '')
          .orderBy('perfilDestacado', descending: true)
          .orderBy('nombre_completo', descending: false)
          .get();

      // Si no existen documentos, se retorna una lista vacía
      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Mapea cada documento de Firestore a un mapa de datos limpio para la UI
      final kineList = querySnapshot.docs.map((doc) {
        final data = doc.data();

        return {
          // ID del documento
          'id': doc.id,

          // Nombre completo del kinesiólogo
          'name': (data['nombre_completo'] as String?) ?? 'Kinesiólogo(a)',

          // Especialización del kinesiólogo
          'specialization':
              (data['specialization'] as String?) ?? 'Sin especialización',

          // Foto de perfil (URL)
          'photoUrl':
              (data['imagen_perfil'] as String?) ??
              'https://via.placeholder.com/150',

          // Años o cantidad de experiencia
          'experience': (data['experience']?.toString()) ?? '0',

          // Carta de presentación o descripción
          'presentation':
              (data['carta_presentacion'] as String?) ??
              'No ha publicado su carta.',
        };
      }).toList();

      return kineList;
    } catch (e) {
      // En caso de error, se muestra en consola para debugging
      debugPrint('Error al cargar kinesiólogos en servicio: $e');

      // Se relanza un error más claro para que la UI pueda manejarlo
      throw Exception('Fallo al obtener el directorio de Kinesiólogos.');
    }
  }
}
