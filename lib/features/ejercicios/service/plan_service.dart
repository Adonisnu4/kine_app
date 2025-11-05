import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Necesario para Future

// --- MODELO ---
// (Este es el modelo de 'PlanTomado' que me enviaste)
class PlanTomado {
  final String id;
  final String nombre; // Viene de la colección 'plan'
  final String descripcion; // Viene de la colección 'plan'
  final String estado; // Viene de la colección 'plan_tomados_por_usuarios'
  final DateTime
  fechaInicio; // Viene de la colección 'plan_tomados_por_usuarios'
  final int sesionActual; // Viene de la colección 'plan_tomados_por_usuarios'

  PlanTomado({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estado,
    required this.fechaInicio,
    required this.sesionActual,
  });
}

// --- SERVICIO ---
// Clase de servicio para gestionar los planes de los usuarios
class PlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 💡 --- ¡NUEVA FUNCIÓN PARA EL KINESIÓLOGO! ---
  /// Obtiene TODOS los planes tomados por un PACIENTE específico.
  /// El Kine usa esto para ver el progreso de otros.
  Future<List<PlanTomado>> obtenerPlanesPorPacienteId(String patientId) async {
    print('--- INICIO CONSULTA KINE: Planes del paciente $patientId ---');

    // Referencia al paciente que el Kine está viendo
    final DocumentReference usuarioRef = _db
        .collection('usuarios')
        .doc(patientId);

    try {
      // 1. CONSULTA INICIAL:
      final querySnapshot = await _db
          .collection('plan_tomados_por_usuarios')
          .where(
            'usuario',
            isEqualTo: usuarioRef,
          ) // Filtra por el ID del paciente
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('CONSULTA KINE: Se encontraron 0 planes para el paciente.');
        return []; // Devuelve lista vacía si no tiene planes
      }

      print(
        '🎉 Documentos de planes tomados encontrados: ${querySnapshot.docs.length}',
      );

      // 2. Mapear y combinar los resultados (usando la función helper de abajo)
      final fetchTasks = querySnapshot.docs.map((planTomadoDoc) async {
        return _mapearPlanTomado(planTomadoDoc);
      }).toList();

      final rawPlanes = await Future.wait(fetchTasks);
      // Filtra cualquier resultado nulo
      final planes = rawPlanes.whereType<PlanTomado>().toList();

      print('--- FIN DE CONSULTA KINE ---');
      return planes;
    } on FirebaseException catch (e) {
      print('❌ ERROR de Firebase (código ${e.code}): ${e.message}');
      throw Exception('No se pudieron cargar los planes: ${e.message}');
    }
  }

  /// --- FUNCIÓN EXISTENTE (PARA EL PACIENTE) ---
  /// Obtiene TODOS los planes tomados por el USUARIO LOGUEADO.
  /// El Paciente usa esto para ver sus propios planes.
  Future<List<PlanTomado>> obtenerPlanesPorUsuario() async {
    print('--- INICIO CONSULTA PACIENTE: Mis Planes ---');
    final user = _auth.currentUser;
    if (user == null) {
      print('🔴 ERROR: No hay usuario autenticado.');
      return [];
    }

    // Filtra por el ID del usuario actual
    final DocumentReference usuarioRef = _db
        .collection('usuarios')
        .doc(user.uid);

    try {
      final querySnapshot = await _db
          .collection('plan_tomados_por_usuarios')
          .where('usuario', isEqualTo: usuarioRef)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('CONSULTA PACIENTE: Se encontraron 0 planes.');
        return [];
      }

      final fetchTasks = querySnapshot.docs.map((planTomadoDoc) async {
        return _mapearPlanTomado(planTomadoDoc);
      }).toList();

      final rawPlanes = await Future.wait(fetchTasks);
      final planes = rawPlanes.whereType<PlanTomado>().toList();

      print('--- FIN DE CONSULTA PACIENTE ---');
      return planes;
    } on FirebaseException catch (e) {
      print('❌ ERROR de Firebase (código ${e.code}): ${e.message}');
      throw Exception('No se pudieron cargar los planes: ${e.message}');
    }
  }

  /// --- FUNCIÓN EXISTENTE (PARA EL PACIENTE) ---
  /// Obtiene solo los planes EN PROGRESO del USUARIO LOGUEADO.
  Future<List<PlanTomado>> obtenerPlanesEnProgresoPorUsuario() async {
    print('--- INICIO CONSULTA PACIENTE: Planes En Progreso ---');
    final user = _auth.currentUser;
    if (user == null) {
      print('🔴 ERROR: No hay usuario autenticado.');
      return [];
    }

    final DocumentReference usuarioRef = _db
        .collection('usuarios')
        .doc(user.uid);

    try {
      final querySnapshot = await _db
          .collection('plan_tomados_por_usuarios')
          .where('usuario', isEqualTo: usuarioRef)
          .where('estado', isEqualTo: 'en_progreso') // <-- Filtro de estado
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('CONSULTTú PACIENTE: Se encontraron 0 planes en progreso.');
        return [];
      }

      final fetchTasks = querySnapshot.docs.map((planTomadoDoc) async {
        return _mapearPlanTomado(planTomadoDoc);
      }).toList();

      final rawPlanes = await Future.wait(fetchTasks);
      final planes = rawPlanes.whereType<PlanTomado>().toList();

      print('--- FIN DE CONSULTA PACIENTE (En Progreso) ---');
      return planes;
    } on FirebaseException catch (e) {
      print('❌ ERROR de Firebase (código ${e.code}): ${e.message}');
      throw Exception(
        'No se pudieron cargar los planes en progreso: ${e.message}',
      );
    }
  }

  /// --- FUNCIÓN HELPER INTERNA ---
  /// Combina los datos de 'plan_tomados_por_usuarios' y 'plan'
  Future<PlanTomado?> _mapearPlanTomado(DocumentSnapshot planTomadoDoc) async {
    final dataTomado = planTomadoDoc.data() as Map<String, dynamic>;
    // Obtiene la referencia al plan (ej: /plan/planguia1)
    final planRef = dataTomado['plan'] as DocumentReference?;

    if (planRef == null) {
      print(
        '⚠️ Advertencia: Documento ${planTomadoDoc.id} no tiene referencia de plan.',
      );
      return null; // Devuelve nulo si no hay plan
    }

    // Busca la información del plan (nombre, descripción)
    final planSnapshot = await planRef.get();

    // Si el plan fue borrado
    if (!planSnapshot.exists) {
      print(
        '⚠️ Advertencia: El plan referenciado (${planRef.path}) no existe.',
      );
      return PlanTomado(
        id: planTomadoDoc.id,
        nombre: 'Plan Eliminado o Inexistente',
        descripcion: 'Los detalles del plan no pudieron ser cargados.',
        estado: dataTomado['estado'] as String? ?? 'N/A',
        fechaInicio:
            (dataTomado['fecha_inicio'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        sesionActual: dataTomado['sesion_actual'] as int? ?? 0,
      );
    }

    // Si todo existe, combina los datos
    final dataPlan = planSnapshot.data() as Map<String, dynamic>;

    return PlanTomado(
      id: planTomadoDoc.id,
      nombre: dataPlan['nombre'] as String? ?? 'Plan sin nombre',
      descripcion: dataPlan['descripcion'] as String? ?? 'Sin descripción.',
      // Datos de la copia del usuario
      estado: dataTomado['estado'] as String? ?? 'N/A',
      fechaInicio:
          (dataTomado['fecha_inicio'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      sesionActual: dataTomado['sesion_actual'] as int? ?? 0,
    );
  }
}
