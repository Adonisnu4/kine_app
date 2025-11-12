import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Necesario para Future

// Clase para representar un Plan (ajusta según tus necesidades reales)
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

/// Obtiene TODOS los planes tomados por el usuario, independientemente de su estado.
Future<List<PlanTomado>> obtenerPlanesPorUsuario() async {
  print('--- INICIO DE CONSULTA MULTI-COLECCIÓN DE PLANES POR USUARIO ---');

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print(
      'ERROR: No hay usuario autenticado. La consulta no puede continuar.',
    );
    return [];
  }

  final db = FirebaseFirestore.instance;
  final userId = user.uid;

  // Crea la DocumentReference del usuario para el filtro de la consulta inicial
  final DocumentReference usuarioRef = db.collection('usuarios').doc(userId);

  print('Usuario ID: $userId');
  print('Buscando planes tomados con referencia: ${usuarioRef.path}');

  try {
    // 1. CONSULTA INICIAL: Obtener los documentos de 'plan_tomados_por_usuarios'
    final querySnapshot = await db
        .collection('plan_tomados_por_usuarios')
        .where('usuario', isEqualTo: usuarioRef)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print('CONSULTA EXITOSA: Se encontraron 0 planes para el usuario.');
      return [];
    }

    print(
      'Documentos de planes tomados encontrados: ${querySnapshot.docs.length}',
    );

    // 2. Mapear y combinar los resultados (Fetching de la colección 'plan' en paralelo)
    final fetchTasks = querySnapshot.docs.map((planTomadoDoc) async {
      final dataTomado = planTomadoDoc.data() as Map<String, dynamic>;

      // 2a. Obtener la referencia al plan real
      final planRef = dataTomado['plan'] as DocumentReference?;

      if (planRef == null) {
        print(
          'Advertencia: Documento ${planTomadoDoc.id} no tiene referencia de plan.',
        );
        return null; // Omitir este plan si la referencia es nula
      }

      // 2b. Obtener el snapshot del documento de plan (la información del nombre/descripción)
      final planSnapshot = await planRef.get();

      // 2c. Validar que el plan referenciado exista
      if (!planSnapshot.exists) {
        print(
          'Advertencia: El documento de plan referenciado (${planRef.path}) no existe.',
        );
        // Devolver un PlanTomado con datos de fallback
        return PlanTomado(
          id: planTomadoDoc.id,
          nombre: 'Plan Eliminado o Inexistente',
          descripcion: 'Los detalles del plan no pudieron ser cargados.',
          estado: dataTomado['estado'] is String
              ? dataTomado['estado'] as String
              : 'N/A',
          fechaInicio: dataTomado['fecha_inicio'] is Timestamp
              ? (dataTomado['fecha_inicio'] as Timestamp).toDate()
              : DateTime.now(),
          sesionActual: dataTomado['sesion_actual'] is int
              ? dataTomado['sesion_actual'] as int
              : 0,
        );
      }

      // 2d. Combinar datos y construir PlanTomado
      final dataPlan = planSnapshot.data() as Map<String, dynamic>;

      return PlanTomado(
        id: planTomadoDoc.id,
        // Datos del Plan (nombre, descripción)
        nombre: dataPlan['nombre'] is String
            ? dataPlan['nombre'] as String
            : 'Plan sin nombre',
        descripcion: dataPlan['descripcion'] is String
            ? dataPlan['descripcion'] as String
            : 'Sin descripción detallada.',

        // Datos específicos del usuario (estado, fechas, sesión actual)
        estado: dataTomado['estado'] is String
            ? dataTomado['estado'] as String
            : 'N/A',
        fechaInicio: dataTomado['fecha_inicio'] is Timestamp
            ? (dataTomado['fecha_inicio'] as Timestamp).toDate()
            : DateTime.now(),
        sesionActual: dataTomado['sesion_actual'] is int
            ? dataTomado['sesion_actual'] as int
            : 0,
      );
    }).toList();

    // 3. Esperar a que todas las tareas de búsqueda se completen
    final rawPlanes = await Future.wait(fetchTasks);

    // 4. Filtrar cualquier resultado nulo (si planRef era nulo)
    final planes = rawPlanes.whereType<PlanTomado>().toList();

    print('--- FIN DE CONSULTA MULTI-COLECCIÓN ---');
    return planes;
  } on FirebaseException catch (e) {
    print('ERROR de Firebase (código ${e.code}): ${e.message}');
    throw Exception('No se pudieron cargar los planes: ${e.message}');
  }
}

/// Obtiene solo los planes tomados por el usuario que tienen el estado "en_progreso".
Future<List<PlanTomado>> obtenerPlanesEnProgresoPorUsuario() async {
  print('--- INICIO DE CONSULTA DE PLANES EN PROGRESO POR USUARIO ---');

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print(
      'ERROR: No hay usuario autenticado. La consulta no puede continuar.',
    );
    return [];
  }

  final db = FirebaseFirestore.instance;
  final userId = user.uid;

  final DocumentReference usuarioRef = db.collection('usuarios').doc(userId);
  print('Usuario ID: $userId');
  print('Buscando planes tomados con estado: "en_progreso"');

  try {
    // 1. CONSULTA INICIAL: Obtener los documentos de 'plan_tomados_por_usuarios'
    // Se añade el filtro 'estado'
    final querySnapshot = await db
        .collection('plan_tomados_por_usuarios')
        .where('usuario', isEqualTo: usuarioRef)
        .where('estado', isEqualTo: 'en_progreso') // <-- FILTRO AÑADIDO
        .get();

    if (querySnapshot.docs.isEmpty) {
      print(
        'CONSULTA EXITOSA: Se encontraron 0 planes en progreso para el usuario.',
      );
      return [];
    }

    print(
      'Documentos de planes en progreso encontrados: ${querySnapshot.docs.length}',
    );

    // 2. Mapear y combinar los resultados (Fetching de la colección 'plan' en paralelo)
    final fetchTasks = querySnapshot.docs.map((planTomadoDoc) async {
      final dataTomado = planTomadoDoc.data() as Map<String, dynamic>;

      // 2a. Obtener la referencia al plan real
      final planRef = dataTomado['plan'] as DocumentReference?;

      if (planRef == null) {
        print(
          'Advertencia: Documento ${planTomadoDoc.id} no tiene referencia de plan.',
        );
        return null; // Omitir este plan si la referencia es nula
      }

      // 2b. Obtener el snapshot del documento de plan (la información del nombre/descripción)
      final planSnapshot = await planRef.get();

      // 2c. Validar que el plan referenciado exista
      if (!planSnapshot.exists) {
        print(
          'Advertencia: El documento de plan referenciado (${planRef.path}) no existe.',
        );
        // Devolver un PlanTomado con datos de fallback
        return PlanTomado(
          id: planTomadoDoc.id,
          nombre: 'Plan Eliminado o Inexistente',
          descripcion: 'Los detalles del plan no pudieron ser cargados.',
          estado: dataTomado['estado'] is String
              ? dataTomado['estado'] as String
              : 'N/A',
          fechaInicio: dataTomado['fecha_inicio'] is Timestamp
              ? (dataTomado['fecha_inicio'] as Timestamp).toDate()
              : DateTime.now(),
          sesionActual: dataTomado['sesion_actual'] is int
              ? dataTomado['sesion_actual'] as int
              : 0,
        );
      }

      // 2d. Combinar datos y construir PlanTomado
      final dataPlan = planSnapshot.data() as Map<String, dynamic>;

      return PlanTomado(
        id: planTomadoDoc.id,
        // Datos del Plan (nombre, descripción)
        nombre: dataPlan['nombre'] is String
            ? dataPlan['nombre'] as String
            : 'Plan sin nombre',
        descripcion: dataPlan['descripcion'] is String
            ? dataPlan['descripcion'] as String
            : 'Sin descripción detallada.',

        // Datos específicos del usuario (estado, fechas, sesión actual)
        estado: dataTomado['estado'] is String
            ? dataTomado['estado'] as String
            : 'N/A',
        fechaInicio: dataTomado['fecha_inicio'] is Timestamp
            ? (dataTomado['fecha_inicio'] as Timestamp).toDate()
            : DateTime.now(),
        sesionActual: dataTomado['sesion_actual'] is int
            ? dataTomado['sesion_actual'] as int
            : 0,
      );
    }).toList();

    // 3. Esperar a que todas las tareas de búsqueda se completen
    final rawPlanes = await Future.wait(fetchTasks);

    // 4. Filtrar cualquier resultado nulo
    final planes = rawPlanes.whereType<PlanTomado>().toList();

    print('--- FIN DE CONSULTA DE PLANES EN PROGRESO ---');
    return planes;
  } on FirebaseException catch (e) {
    print('ERROR de Firebase (código ${e.code}): ${e.message}');
    throw Exception(
      'No se pudieron cargar los planes en progreso: ${e.message}',
    );
  }
}
