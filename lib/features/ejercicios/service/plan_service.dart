import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Necesario para Future

// 🔥 ¡CORREGIDO! Importa el modelo, NO lo define aquí.
import 'package:kine_app/features/ejercicios/models/plan_tomado.dart';

class PlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<PlanTomado>> obtenerPlanesPorPacienteId(String patientId) async {
    final DocumentReference usuarioRef = _db
        .collection('usuarios')
        .doc(patientId);

    try {
      final querySnapshot = await _db
          .collection('plan_tomados_por_usuarios')
          .where('usuario', isEqualTo: usuarioRef)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      final fetchTasks = querySnapshot.docs.map((planTomadoDoc) async {
        return _mapearPlanTomado(planTomadoDoc);
      }).toList();

      final rawPlanes = await Future.wait(fetchTasks);
      final planes = rawPlanes.whereType<PlanTomado>().toList();
      return planes;
    } on FirebaseException catch (e) {
      print('❌ ERROR de Firebase (código ${e.code}): ${e.message}');
      throw Exception('No se pudieron cargar los planes: ${e.message}');
    }
  }

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
      print('❌ ERROR de Firebase (código ${e.code}): ${e.message}');
      throw Exception('No se pudieron cargar los planes: ${e.message}');
    }
  }

  Future<List<PlanTomado>> obtenerPlanesEnProgresoPorUsuario() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final DocumentReference usuarioRef = _db
        .collection('usuarios')
        .doc(user.uid);

    try {
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
      print('❌ ERROR de Firebase (código ${e.code}): ${e.message}');
      throw Exception(
        'No se pudieron cargar los planes en progreso: ${e.message}',
      );
    }
  }

  Future<PlanTomado?> _mapearPlanTomado(DocumentSnapshot planTomadoDoc) async {
    final dataTomado = planTomadoDoc.data() as Map<String, dynamic>;
    final planRef = dataTomado['plan'] as DocumentReference?;

    if (planRef == null) return null;

    final planSnapshot = await planRef.get();

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
        // --- 👇 LÍNEA AÑADIDA ---
        sesiones: dataTomado['sesiones'] as List<dynamic>? ?? [],
      );
    }

    final dataPlan = planSnapshot.data() as Map<String, dynamic>;

    return PlanTomado(
      id: planTomadoDoc.id,
      nombre: dataPlan['nombre'] as String? ?? 'Plan sin nombre',
      descripcion: dataPlan['descripcion'] as String? ?? 'Sin descripción.',
      estado: dataTomado['estado'] as String? ?? 'N/A',
      fechaInicio:
          (dataTomado['fecha_inicio'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      sesionActual: dataTomado['sesion_actual'] as int? ?? 0,
      // --- 👇 LÍNEA AÑADIDA ---
      sesiones: dataTomado['sesiones'] as List<dynamic>? ?? [],
    );
  }
}
