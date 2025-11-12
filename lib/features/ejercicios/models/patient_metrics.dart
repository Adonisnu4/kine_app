class PatientMetrics {
  final int diasActivos;
  final int diasInactivos;
  final int totalHorasCompletadas;
  final int totalEjerciciosCompletados;
  final int totalEjerciciosAsignados;
  final int totalPlanesTerminados;
  final bool estaEnPlanActivo;

  // --- 👇 NUEVO CAMPO AÑADIDO ---
  // Lista de 7 enteros (Lunes a Domingo)
  // [0] = Lunes, [1] = Martes, ..., [6] = Domingo
  final List<int> ejerciciosPorDiaSemana;

  PatientMetrics({
    this.diasActivos = 0,
    this.diasInactivos = 0,
    this.totalHorasCompletadas = 0,
    this.totalEjerciciosCompletados = 0,
    this.totalEjerciciosAsignados = 0,
    this.totalPlanesTerminados = 0,
    this.estaEnPlanActivo = false,
    // --- 👇 VALOR PREDETERMINADO AÑADIDO ---
    List<int>? ejerciciosPorDiaSemana,
  }) : ejerciciosPorDiaSemana =
           ejerciciosPorDiaSemana ?? List.filled(7, 0); // Lista de 7 ceros
}
