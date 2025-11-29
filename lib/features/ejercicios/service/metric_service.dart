import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:intl/intl.dart';

import 'package:kine_app/features/ejercicios/models/patient_metrics.dart';

class MetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene las métricas calculadas de un paciente según su historial
  Future<PatientMetrics> getPatientMetrics(String patientId) async {
    // Referencia al documento del usuario dentro de "usuarios"
    final DocumentReference usuarioRef = _firestore
        .collection('usuarios')
        .doc(patientId);

    // Busca todos los planes tomados por ese usuario
    final querySnapshot = await _firestore
        .collection('plan_tomados_por_usuarios')
        .where('usuario', isEqualTo: usuarioRef)
        .get();

    // Si no tiene planes, devolver métricas vacías
    if (querySnapshot.docs.isEmpty) {
      return PatientMetrics();
    }

    // Variables para cálculos
    int totalEjerciciosCompletados = 0;
    int totalEjerciciosAsignados = 0;
    int totalSegundosCompletados = 0;
    int totalPlanesTerminados = 0;
    bool estaEnPlanActivo = false;

    // Set que almacena días únicos donde hizo actividad
    final Set<String> diasActivosSet = {};

    // Fecha más antigua entre todos los planes del usuario
    DateTime? earliestStartDate;

    // Cantidad de ejercicios completados por cada día de la semana
    // índice 0 = lunes, ... índice 6 = domingo
    List<int> ejerciciosPorDia = List.filled(7, 0);

    // Recorre cada documento "plan_tomados_por_usuarios"
    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      // Fecha de inicio del plan (si existe)
      final Timestamp? tsInicioPlan = data['fecha_inicio'];
      if (tsInicioPlan != null) {
        final planStartDate = tsInicioPlan.toDate();

        // Registra la fecha de inicio más antigua
        if (earliestStartDate == null ||
            planStartDate.isBefore(earliestStartDate)) {
          earliestStartDate = planStartDate;
        }
      }

      // Detecta si tiene un plan en progreso
      if (data['estado'] == 'en_progreso') {
        estaEnPlanActivo = true;
      }

      // Cuenta planes terminados
      if (data['estado'] == 'terminado') {
        totalPlanesTerminados++;
      }

      // Accede a todas las sesiones del plan actual
      final List<dynamic> sesiones = data['sesiones'] ?? [];

      // Recorre cada sesión
      for (var sesion in sesiones) {
        // Cada sesión contiene un mapa de ejercicios
        final Map<String, dynamic> ejercicios = sesion['ejercicios'] ?? {};

        // Recorre todos los ejercicios de la sesión
        for (var ejercicioData in ejercicios.values) {
          // Aumenta el contador total de ejercicios asignados
          totalEjerciciosAsignados++;

          // Verifica si el ejercicio está completado
          final bool completado = ejercicioData['completado'] ?? false;

          if (completado) {
            // Total de ejercicios completados
            totalEjerciciosCompletados++;

            // Suma el tiempo completado
            final int tiempo = ejercicioData['tiempo_segundos'] ?? 0;
            totalSegundosCompletados += tiempo;

            // Fecha en que se completó (para actividad semanal y gráfica)
            final Timestamp? fechaCompletadoTS =
                ejercicioData['fecha_completado'];

            if (fechaCompletadoTS != null) {
              final fechaCompletado = fechaCompletadoTS.toDate();

              // 1. Guarda el día exacto en formato yyyy-MM-dd
              diasActivosSet.add(
                DateFormat('yyyy-MM-dd').format(fechaCompletado),
              );

              // 2. Calcula el índice del día para la gráfica semanal
              // weekday devuelve:
              // 1 = lunes, 7 = domingo
              int dayIndex = fechaCompletado.weekday - 1;

              // Verifica límites (0 a 6)
              if (dayIndex >= 0 && dayIndex < 7) {
                ejerciciosPorDia[dayIndex]++;
              }
            }
          }
        }
      }
    }

    // Convierte los segundos totales en horas
    final int totalHoras = (totalSegundosCompletados / 3600).round();

    // Total de días en los que el usuario realizó actividad
    final int diasActivos = diasActivosSet.length;

    int diasInactivos = 0;

    // Calcula días inactivos desde la fecha más antigua registrada
    if (earliestStartDate != null) {
      final today = DateTime.now();

      // Calcula el rango total de días desde que comenzó el primer plan
      final int totalDiasDesdeInicio =
          today.difference(earliestStartDate).inDays + 1;

      // Días donde no hubo actividad
      if (totalDiasDesdeInicio > diasActivos) {
        diasInactivos = totalDiasDesdeInicio - diasActivos;
      }
    }

    // Devuelve todas las métricas calculadas en un modelo
    return PatientMetrics(
      diasActivos: diasActivos,
      diasInactivos: diasInactivos,
      totalHorasCompletadas: totalHoras,
      totalEjerciciosCompletados: totalEjerciciosCompletados,
      totalEjerciciosAsignados: totalEjerciciosAsignados,
      totalPlanesTerminados: totalPlanesTerminados,
      estaEnPlanActivo: estaEnPlanActivo,
      ejerciciosPorDiaSemana: ejerciciosPorDia,
    );
  }

  /// Marca actividad reciente del paciente
  /// Actualiza el campo "lastExerciseDate" en la colección usuarios
  Future<void> marcarActividad(String pacienteId) async {
    try {
      await _firestore.collection('usuarios').doc(pacienteId).update({
        'lastExerciseDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Manejo de error básico
      print('Error al marcar actividad: $e');
    }
  }
}
