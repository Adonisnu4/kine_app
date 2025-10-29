import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/screens/ejercicios/sesion_ejercicio_screen.dart';

class PlanEjercicioDetalleScreen extends StatefulWidget {
  final String planId;
  final String planName;

  const PlanEjercicioDetalleScreen({
    super.key,
    required this.planId,
    required this.planName,
  });

  @override
  State<PlanEjercicioDetalleScreen> createState() =>
      _PlanEjercicioDetalleScreenState();
}

class _PlanEjercicioDetalleScreenState
    extends State<PlanEjercicioDetalleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _comenzarPlan(List<dynamic> sesionesMaestras) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      throw Exception("Usuario no autenticado.");
    }

    if (sesionesMaestras.isEmpty) {
      print('⚠️ Error: El plan no tiene sesiones definidas.');
      return;
    }

    final String? planId = widget.planId;
    if (planId == null || planId.isEmpty) {
      print('⚠️ Error: planId no válido.');
      return;
    }

    // Referencias
    final DocumentReference planRef = firestore.collection('plan').doc(planId);
    final DocumentReference userRef = firestore
        .collection('usuarios')
        .doc(userId);

    // Clonamos las sesiones maestras agregando "completada: false"
    final List<Map<String, dynamic>> sesionesProgreso = sesionesMaestras.map((
      s,
    ) {
      final sessionMap = Map<String, dynamic>.from(s);
      sessionMap['completada'] = sessionMap['completada'] ?? false;
      return sessionMap;
    }).toList();

    // Creamos el nuevo documento con ID automático
    final CollectionReference ejecucionCollection = firestore.collection(
      'plan_tomados_por_usuarios',
    );

    final DocumentReference ejecucionRef = await ejecucionCollection.add({
      'usuario': userRef,
      'plan': planRef,
      'estado': 'en_progreso',
      'fecha_inicio': FieldValue.serverTimestamp(),
      'sesion_actual': 0,
      'sesiones': sesionesProgreso,
    });

    print('✅ Nuevo plan iniciado con ID automático: ${ejecucionRef.id}');

    // Obtenemos los datos de la primera sesión
    final Map<String, dynamic> sesionActualData = sesionesProgreso.first;
    final ejerciciosData = sesionActualData['ejercicios'];
    final nombreSesion = sesionActualData['nombre'] ?? 'Sesión 1';

    // Navegar a la pantalla de la sesión
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            SesionEjercicioScreen(ejecucionId: ejecucionRef.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.planName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('plan').doc(widget.planId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar el plan: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el plan.'));
          }

          final Map<String, dynamic> planData =
              snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> sesiones = planData['sesiones'] ?? [];
          final String descripcion =
              planData['descripcion'] ?? 'No hay descripción disponible.';
          final int duracionSemanas = planData['duracion_semanas'] ?? 0;

          if (sesiones.isEmpty) {
            return const Center(
              child: Text('Este plan aún no tiene sesiones asignadas.'),
            );
          }

          return Column(
            children: [
              _buildPlanInfoCard(context, descripcion, duracionSemanas),
              // Lista de sesiones (debe estar expandida)
              Expanded(child: _buildSesionesList(sesiones)),

              // ⭐️ BOTÓN DE ACCIÓN FIJO EN LA PARTE INFERIOR ⭐️
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  bottom: 24.0,
                  top: 8.0,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _comenzarPlan(sesiones),
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'COMENZAR PLAN',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ... (El resto de las funciones _buildPlanInfoCard y _buildSesionesList quedan igual o con las últimas correcciones)
  // [CÓDIGO DE _buildPlanInfoCard, _buildSesionesList, _buildEjercicioTileFromRef, y _buildEjercicioTile aquí]

  Widget _buildPlanInfoCard(
    BuildContext context,
    String descripcion,
    int duracionSemanas,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final String duracionText = duracionSemanas > 0
        ? '$duracionSemanas semanas'
        : 'Duración no especificada';

    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.deepPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Duración total: $duracionText',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            Text(
              'Descripción del plan',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descripcion,
              style: textTheme.bodyLarge?.copyWith(
                color: Colors.black87,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSesionesList(List<dynamic> sesiones) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12.0, bottom: 16.0),
      itemCount: sesiones.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> sesionActual =
            sesiones[index] as Map<String, dynamic>;
        final int numeroSesion = sesionActual['numero_sesion'] ?? (index + 1);
        final dynamic ejerciciosData = sesionActual['ejercicios'];
        final bool sesionCompletada = sesionActual['completada'] == true;

        int totalEjerciciosSesion = 0;
        if (ejerciciosData is Map) {
          totalEjerciciosSesion = ejerciciosData.length;
        } else if (ejerciciosData is List) {
          totalEjerciciosSesion = ejerciciosData.length;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          elevation: 1.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            leading: Icon(
              sesionCompletada
                  ? Icons.check_circle_rounded
                  : Icons.pending_actions_rounded,
              color: sesionCompletada ? Colors.green : Colors.deepPurple,
              size: 28,
            ),
            title: Text(
              'Sesión $numeroSesion',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: sesionCompletada ? Colors.grey.shade700 : Colors.black87,
                decoration: sesionCompletada
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            subtitle: Text('$totalEjerciciosSesion ejercicios'),
            children: _buildEjerciciosList(ejerciciosData),
          ),
        );
      },
    );
  }

  // Se mantiene la lógica para manejar la lista de referencias
  // En PlanEjercicioDetalleScreen.dart
  List<Widget> _buildEjerciciosList(dynamic ejerciciosData) {
    // 1. Verificación de datos nulos/vacíos (Este sí es necesario)
    if (ejerciciosData == null ||
        (ejerciciosData is Map && ejerciciosData.isEmpty) ||
        (ejerciciosData is List && ejerciciosData.isEmpty)) {
      print("TEST: Ejercicios vacíos o nulos.");
      return [const ListTile(title: Text('No hay ejercicios en esta sesión.'))];
    }

    // 2. Procesamos el Map<clave_sesion, datos_ejercicio>
    if (ejerciciosData is Map<String, dynamic>) {
      print("TEST: Procesando ejercicios como un MAPA.");

      // Usamos .entries para iterar sobre cada par clave-valor (ejercicio_1, ejercicio_2, etc.)
      return ejerciciosData.entries.map<Widget>((entry) {
        final String claveEjercicio = entry.key; // ej. "ejercicio_1"
        final Map<String, dynamic> item = entry.value as Map<String, dynamic>;

        final bool completado = item['completado'] ?? false;
        final int tiempoSesion = item['tiempo_segundos'] ?? 0;

        // ✅ AHORA EXTRAEMOS LA REFERENCIA DIRECTAMENTE
        // Asegúrate de que 'ejercicio' sea la clave para el DocumentReference
        final DocumentReference? ejercicioRef =
            item['ejercicio'] as DocumentReference?;

        // Verificación de referencia
        if (ejercicioRef == null) {
          print(
            '❌ Error: El ejercicio "$claveEjercicio" no tiene la clave "ejercicio" (DocumentReference).',
          );
          return ListTile(
            title: Text('$claveEjercicio - Error de referencia.'),
            subtitle: const Text(
              'Falta la referencia al documento del ejercicio.',
            ),
          );
        }

        // ✅ ¡TU PRINT DE DEPURACIÓN AHORA SE EJECUTARÁ AQUÍ!
        print(
          '🚀 Referencia a buscar para $claveEjercicio: ${ejercicioRef.id}. Tiempo: $tiempoSesion',
        );

        // Llamamos a la función de resolución con la ID, ya que _buildEjercicioTileFromRef la espera
        return _buildEjercicioTileFromRef(
          ejercicioRef.id, // Le pasamos el ID del documento
          completado,
          tiempoSesion,
        );
      }).toList();
    }

    // 3. Fallback final
    print(
      '❌ Error: ejerciciosData tiene un tipo de dato inesperado: ${ejerciciosData.runtimeType}.',
    );
    return [const ListTile(title: Text('Error de formato de ejercicios.'))];
  }

  // ✅ FUNCIÓN REFINADA: Solo se garantiza la carga del "nombre"
  Widget _buildEjercicioTileFromRef(
    String ejercicioId,
    bool completado,
    int tiempoSesion, // Renombrado de 'duracion' a 'tiempoSesion'
  ) {
    final DocumentReference ejercicioRef = _firestore
        .collection('ejercicios')
        .doc(ejercicioId);
    print(
      "TEST: Llamada a _buildEjercicioTileFromRef para ID: $ejercicioId",
    ); // Print de prueba

    return StreamBuilder<DocumentSnapshot>(
      stream: ejercicioRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircularProgressIndicator.adaptive(),
            title: Text('Cargando ejercicio...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return ListTile(
            leading: const Icon(
              Icons.error,
              color: Color.fromARGB(255, 253, 247, 246),
            ),
            title: Text('Error al cargar datos del ejercicio ID: $ejercicioId'),
          );
        }

        final Map<String, dynamic> ejercicioData =
            snapshot.data!.data() as Map<String, dynamic>;

        // ✅ Mapeo de campos: 'nombre' de la tabla 'ejercicios' a 'nombre_ejercicio' del widget.
        final Map<String, dynamic> finalInfo = {
          'nombre_ejercicio': ejercicioData['nombre'] ?? 'Nombre no encontrado',
          'tiempo_segundos': tiempoSesion, // Usamos la duración del plan
          'completado': completado, // Estado de completado del plan
        };
        print(
          '✅ Nombre obtenido para $ejercicioId: ${finalInfo['nombre_ejercicio']}',
        ); // Print de confirmación de nombre

        return _buildEjercicioTile(finalInfo);
      },
    );
  }

  Widget _buildEjercicioTile(Map<String, dynamic> info) {
    final String nombreEjercicio =
        info['nombre_ejercicio'] ?? 'Nombre ejercicio no encontrado';
    final int tiempoSegundos = info['tiempo_segundos'] ?? 0;
    final bool completado = info['completado'] == true;

    return ListTile(
      contentPadding: const EdgeInsets.only(
        left: 56.0,
        right: 16.0,
        bottom: 4.0,
      ),
      leading: Icon(
        completado ? Icons.check_circle : Icons.directions_run_rounded,
        color: completado ? Colors.green : Colors.orange.shade700,
      ),
      title: Text(
        nombreEjercicio,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: completado ? Colors.grey.shade700 : Colors.black87,
          decoration: completado
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tiempoSegundos > 0)
            Text(
              'Duracion: $tiempoSegundos seg',
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
