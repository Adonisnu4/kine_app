// lib/features/ejercicios/models/patient_metrics.dart

class PatientMetrics {
  final int diasActivos;
  final int totalHorasCompletadas; // La clase lo mantiene
  final int totalEjerciciosCompletados;
  final int totalEjerciciosAsignados;
  final int totalPlanesTerminados;
  final bool estaEnPlanActivo;

  PatientMetrics({
    this.diasActivos = 0,
    this.totalHorasCompletadas = 0,
    this.totalEjerciciosCompletados = 0,
    this.totalEjerciciosAsignados = 0,
    this.totalPlanesTerminados = 0,
    this.estaEnPlanActivo = false,
  });
}
