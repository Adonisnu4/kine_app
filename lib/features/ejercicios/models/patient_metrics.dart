class PatientMetrics {
  final int
  diasActivos; // Número total de días en que el paciente realizó actividades o ejercicios.
  final int
  diasInactivos; // Número de días en que el paciente no realizó ninguna actividad.
  final int
  totalHorasCompletadas; // Total de horas completadas por el paciente en sus planes o ejercicios.
  final int
  totalEjerciciosCompletados; // Cantidad total de ejercicios que el paciente ha marcado como completados.
  final int
  totalEjerciciosAsignados; // Cantidad total de ejercicios que han sido asignados al paciente.
  final int
  totalPlanesTerminados; // Número de planes completos que el paciente ha finalizado.
  final bool
  estaEnPlanActivo; // Indica si el paciente actualmente tiene un plan de ejercicios activo.
  final List<int>
  ejerciciosPorDiaSemana; // Lista que representa la cantidad de ejercicios realizados por día de la semana.

  // Constructor principal de la clase PatientMetrics.
  // Permite inicializar las métricas del paciente con valores predeterminados.
  PatientMetrics({
    this.diasActivos = 0,
    this.diasInactivos = 0,
    this.totalHorasCompletadas = 0,
    this.totalEjerciciosCompletados = 0,
    this.totalEjerciciosAsignados = 0,
    this.totalPlanesTerminados = 0,
    this.estaEnPlanActivo = false,

    // Lista opcional. Si no se proporciona, se inicializa con una lista
    // de 7 elementos en cero, representando los días de la semana.
    List<int>? ejerciciosPorDiaSemana,
  }) : ejerciciosPorDiaSemana =
           // Si la lista es null, se asigna una lista con 7 ceros.
           ejerciciosPorDiaSemana ?? List.filled(7, 0);
}
