// lib/features/ejercicios/service/metric_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 🔥 ¡CORREGIDO! Importa el modelo, NO lo define aquí.
import 'package:kine_app/features/ejercicios/models/patient_metrics.dart';

class MetricsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<PatientMetrics> getPatientMetrics(String patientId) async {
    final DocumentReference usuarioRef = _firestore
        .collection('usuarios')
        .doc(patientId);

    final querySnapshot = await _firestore
        .collection('plan_tomados_por_usuarios')
        .where('usuario', isEqualTo: usuarioRef)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return PatientMetrics();
    }

    int totalEjerciciosCompletados = 0;
    int totalEjerciciosAsignados = 0;
    int totalSegundosCompletados = 0;
    int totalPlanesTerminados = 0;
    bool estaEnPlanActivo = false;
    final Set<String> diasActivosSet = {};

    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

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
            final Timestamp? fechaInicio = data['fecha_inicio'];
            if (fechaInicio != null) {
              diasActivosSet.add(
                DateFormat('yyyy-MM-dd').format(fechaInicio.toDate()),
              );
            }
          }
        }
      }
    }

    final int totalHoras = (totalSegundosCompletados / 3600).round();

    return PatientMetrics(
      diasActivos: diasActivosSet.length,
      totalHorasCompletadas: totalHoras, // Aún lo calculamos
      totalEjerciciosCompletados: totalEjerciciosCompletados,
      totalEjerciciosAsignados: totalEjerciciosAsignados,
      totalPlanesTerminados: totalPlanesTerminados,
      estaEnPlanActivo: estaEnPlanActivo,
    );
  }
}
