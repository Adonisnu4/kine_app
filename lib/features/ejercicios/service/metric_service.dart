// lib/features/ejercicios/service/metric_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// 🔥 ¡CORREGIDO! Importa el modelo, NO lo define aquí.
import 'package:kine_app/features/ejercicios/models/patient_metrics.dart';

class MetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene las métricas de progreso de un paciente.
  Future<PatientMetrics> getPatientMetrics(String patientId) async {
    final DocumentReference usuarioRef = _firestore
        .collection('usuarios')
        .doc(patientId);

    final querySnapshot = await _firestore
        .collection('plan_tomados_por_usuarios')
        .where('usuario', isEqualTo: usuarioRef)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return PatientMetrics(); // Devuelve métricas vacías
    }

    int totalEjerciciosCompletados = 0;
    int totalEjerciciosAsignados = 0;
    int totalSegundosCompletados = 0;
    int totalPlanesTerminados = 0;
    bool estaEnPlanActivo = false;
    final Set<String> diasActivosSet = {};
    DateTime? earliestStartDate;

    // [0] = Lunes, [1] = Martes, ..., [6] = Domingo
    List<int> ejerciciosPorDia = List.filled(7, 0);

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final Timestamp? tsInicioPlan = data['fecha_inicio'];
      if (tsInicioPlan != null) {
        final planStartDate = tsInicioPlan.toDate();
        if (earliestStartDate == null ||
            planStartDate.isBefore(earliestStartDate!)) {
          earliestStartDate = planStartDate;
        }
      }

      if (data['estado'] == 'en_progreso') estaEnPlanActivo = true;
      if (data['estado'] == 'terminado') totalPlanesTerminados++;

      final List<dynamic> sesiones = data['sesiones'] ?? [];

      for (var sesion in sesiones) {
        final Map<String, dynamic> ejercicios = sesion['ejercicios'] ?? {};

        for (var ejercicioData in ejercicios.values) {
          totalEjerciciosAsignados++;
          final bool completado = ejercicioData['completado'] ?? false;
          if (completado) {
            totalEjerciciosCompletados++;
            final int tiempo = ejercicioData['tiempo_segundos'] ?? 0;
            totalSegundosCompletados += tiempo;

            final Timestamp? fechaCompletadoTS =
                ejercicioData['fecha_completado'];
            if (fechaCompletadoTS != null) {
              final fechaCompletado = fechaCompletadoTS.toDate();

              // 1. Añade al set de días activos (lógica existente)
              diasActivosSet.add(
                DateFormat('yyyy-MM-dd').format(fechaCompletado),
              );

              // 2. Lógica para el gráfico de barras
              // DateTime.weekday devuelve 1 para Lunes y 7 para Domingo.
              // Restamos 1 para que coincida con el índice de nuestra lista (0-6).
              int dayIndex = fechaCompletado.weekday - 1;
              if (dayIndex >= 0 && dayIndex < 7) {
                ejerciciosPorDia[dayIndex]++;
              }
            }
          }
        }
      }
    }

    final int totalHoras = (totalSegundosCompletados / 3600).round();
    final int diasActivos = diasActivosSet.length;
    int diasInactivos = 0;

    if (earliestStartDate != null) {
      final today = DateTime.now();
      final int totalDiasDesdeInicio =
          today.difference(earliestStartDate!).inDays + 1;

      if (totalDiasDesdeInicio > diasActivos) {
        diasInactivos = totalDiasDesdeInicio - diasActivos;
      }
    }

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

  /// Marca la fecha actual como última actividad realizada por el paciente.
  /// Esto actualiza 'lastExerciseDate' en el documento 'usuarios'.
  Future<void> marcarActividad(String pacienteId) async {
    try {
      await _firestore.collection('usuarios').doc(pacienteId).update({
        'lastExerciseDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Manejar el error, por ejemplo, imprimirlo
      print('Error al marcar actividad: $e');
      // Opcionalmente, relanzar el error si quieres que la UI lo maneje
      // throw Exception('No se pudo marcar la actividad');
    }
  }
}
