import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';

import 'package:kine_app/features/ejercicios/models/plan_tomado.dart';

// Servicio responsable de consultar y mapear los planes tomados por un usuario
class PlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //OBTENER PLANES POR ID DEL PACIENTE

  /// Obtiene todos los planes tomados por un paciente según su ID.
  Future<List<PlanTomado>> obtenerPlanesPorPacienteId(String patientId) async {
    // Crea una referencia al documento del usuario dentro de "usuarios"
    final DocumentReference usuarioRef = _db
        .collection('usuarios')
        .doc(patientId);

    try {
      // Consulta todos los documentos en "plan_tomados_por_usuarios"
      // donde la referencia "usuario" coincide con el usuario buscado
      final querySnapshot = await _db
          .collection('plan_tomados_por_usuarios')
          .where('usuario', isEqualTo: usuarioRef)
          .get();

      // Si el usuario no tiene planes, devolver lista vacía
      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // Mapea cada documento a un objeto PlanTomado (async)
      final fetchTasks = querySnapshot.docs.map((planTomadoDoc) async {
        return _mapearPlanTomado(planTomadoDoc);
      }).toList();

      // Espera todas las operaciones asíncronas
      final rawPlanes = await Future.wait(fetchTasks);

      // Filtra cualquier null que pueda haber retornado
      final planes = rawPlanes.whereType<PlanTomado>().toList();

      return planes;
    } on FirebaseException catch (e) {
      print('ERROR de Firebase (código ${e.code}): ${e.message}');
      throw Exception('No se pudieron cargar los planes: ${e.message}');
    }
  }

  //OBTENER PLANES TOMADOS POR EL USUARIO ACTUAL

  /// Obtiene todos los planes tomados por el usuario actualmente autenticado.
  Future<List<PlanTomado>> obtenerPlanesPorUsuario() async {
    final user = _auth.currentUser;

    if (user == null) return [];

    final DocumentReference usuarioRef = _db
        .collection('usuarios')
        .doc(user.uid);

    try {
      final querySnapshot = await _db
          .collection('plan_tomados_por_usuarios')
          .where('usuario', isEqualTo: usuarioRef)
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      final fetchTasks = querySnapshot.docs.map((planTomadoDoc) async {
        return _mapearPlanTomado(planTomadoDoc);
      }).toList();

      final rawPlanes = await Future.wait(fetchTasks);
      final planes = rawPlanes.whereType<PlanTomado>().toList();

      return planes;
    } on FirebaseException catch (e) {
      print('ERROR de Firebase (código ${e.code}): ${e.message}');
      throw Exception('No se pudieron cargar los planes: ${e.message}');
    }
  }

  //OBTENER PLANES EN PROGRESO POR USUARIO AUTENTICADO

  /// Devuelve únicamente los planes cuyo estado es "en_progreso".
  Future<List<PlanTomado>> obtenerPlanesEnProgresoPorUsuario() async {
    final user = _auth.currentUser;

    if (user == null) return [];

    final DocumentReference usuarioRef = _db
        .collection('usuarios')
        .doc(user.uid);

    try {
      // Filtra por usuario y estado "en_progreso"
      final querySnapshot = await _db
          .collection('plan_tomados_por_usuarios')
          .where('usuario', isEqualTo: usuarioRef)
          .where('estado', isEqualTo: 'en_progreso')
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      final fetchTasks = querySnapshot.docs.map((planTomadoDoc) async {
        return _mapearPlanTomado(planTomadoDoc);
      }).toList();

      final rawPlanes = await Future.wait(fetchTasks);
      final planes = rawPlanes.whereType<PlanTomado>().toList();

      return planes;
    } on FirebaseException catch (e) {
      print('ERROR de Firebase (código ${e.code}): ${e.message}');
      throw Exception(
        'No se pudieron cargar los planes en progreso: ${e.message}',
      );
    }
  }

  //MAPEAR DOCUMENTO A MODELO PlanTomado

  /// Convierte un DocumentSnapshot del plan tomado en un objeto PlanTomado
  Future<PlanTomado?> _mapearPlanTomado(DocumentSnapshot planTomadoDoc) async {
    // Obtiene el mapa de datos del documento plan tomado
    final dataTomado = planTomadoDoc.data() as Map<String, dynamic>;

    // Referencia al plan original (colección "plan")
    final planRef = dataTomado['plan'] as DocumentReference?;

    // Si el plan original ya no existe, devuelve un PlanTomado especial
    if (planRef == null) {
      return null;
    }

    // Obtiene los datos del plan base
    final planSnapshot = await planRef.get();

    // Caso donde el plan fue eliminado pero el usuario aún tiene registro
    if (!planSnapshot.exists) {
      return PlanTomado(
        id: planTomadoDoc.id,
        nombre: 'Plan Eliminado',
        descripcion: 'Este plan ya no existe.',
        estado: dataTomado['estado'] as String? ?? 'N/A',
        fechaInicio:
            (dataTomado['fecha_inicio'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        sesionActual: dataTomado['sesion_actual'] as int? ?? 0,

        // Se añade la lista de sesiones del documento tomado
        sesiones: dataTomado['sesiones'] as List<dynamic>? ?? [],
      );
    }

    // Datos reales del plan original
    final dataPlan = planSnapshot.data() as Map<String, dynamic>;

    // Construye el objeto del modelo
    return PlanTomado(
      id: planTomadoDoc.id,
      nombre: dataPlan['nombre'] as String? ?? 'Plan sin nombre',
      descripcion: dataPlan['descripcion'] as String? ?? 'Sin descripción.',
      estado: dataTomado['estado'] as String? ?? 'N/A',
      fechaInicio:
          (dataTomado['fecha_inicio'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      sesionActual: dataTomado['sesion_actual'] as int? ?? 0,

      // Mantiene las sesiones del documento del usuario
      sesiones: dataTomado['sesiones'] as List<dynamic>? ?? [],
    );
  }
}
