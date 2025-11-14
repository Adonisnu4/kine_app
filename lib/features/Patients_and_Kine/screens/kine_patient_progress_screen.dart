// lib/screens/kine_patient_progress_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kine_app/features/ejercicios/models/plan_tomado.dart';
import 'package:kine_app/features/ejercicios/models/patient_metrics.dart';
import 'package:kine_app/features/ejercicios/service/metric_service.dart';
import 'package:kine_app/features/ejercicios/service/plan_service.dart';

class KinePatientProgressScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const KinePatientProgressScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<KinePatientProgressScreen> createState() =>
      _KinePatientProgressScreenState();
}

class _KinePatientProgressScreenState extends State<KinePatientProgressScreen>
    with SingleTickerProviderStateMixin {
  // 🎨 Paleta (solo visual)
  static const _bg = Color(0xFFF6F7FB);
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _muted = Color(0xFF6D6D6D);
  static const _card = Colors.white;
  static const _border = Color(0x11000000);

  final PlanService _planService = PlanService();
  final MetricsService _metricsService = MetricsService();

  late Future<Map<String, dynamic>> _dashboardData;
  late AnimationController _animationController;

  bool _mostrarTodosLosPlanes = false;

  @override
  void initState() {
    super.initState();
    _dashboardData = _loadDashboardData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    final metrics = await _metricsService.getPatientMetrics(widget.patientId);
    final plans = await _planService.obtenerPlanesPorPacienteId(
      widget.patientId,
    );
    return {'metrics': metrics, 'plans': plans};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          'Progreso de ${widget.patientName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _blue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos.'));
          }

          final metrics = snapshot.data!['metrics'] as PatientMetrics;
          final plans = snapshot.data!['plans'] as List<PlanTomado>;

          final planesVisibles = _mostrarTodosLosPlanes
              ? plans
              : plans.take(5).toList();

          return RefreshIndicator(
            color: _blue,
            onRefresh: () async {
              setState(() => _dashboardData = _loadDashboardData());
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildMetricsDashboard(metrics),
                const SizedBox(height: 16),
                Container(height: 1, color: _border),
                const SizedBox(height: 10),
                const Text(
                  'Planes Asignados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...planesVisibles.map((plan) => _buildPlanCard(plan)).toList(),
                if (plans.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _mostrarTodosLosPlanes = !_mostrarTodosLosPlanes;
                          });
                        },
                        icon: Icon(
                          _mostrarTodosLosPlanes
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: _blue,
                        ),
                        label: Text(
                          _mostrarTodosLosPlanes
                              ? 'Ver menos'
                              : 'Ver todos (${plans.length})',
                          style: const TextStyle(
                            color: _blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ======== PANEL DE MÉTRICAS (visual) ========
  Widget _buildMetricsDashboard(PatientMetrics metrics) {
    final double adherence = (metrics.totalEjerciciosAsignados > 0)
        ? (metrics.totalEjerciciosCompletados /
                metrics.totalEjerciciosAsignados) *
            100
        : 0.0;

    final screenWidth = MediaQuery.of(context).size.width;

    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Resumen de Actividad',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _blue,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricBox(
                  value: metrics.diasActivos.toString(),
                  label: 'Días Activos',
                  icon: Icons.calendar_today,
                  color: Colors.green.shade600,
                ),
                _MetricBox(
                  value: metrics.diasInactivos.toString(),
                  label: 'Días Inactivos',
                  icon: Icons.nightlight_round,
                  color: Colors.redAccent,
                ),
                _MetricBox(
                  value: metrics.totalHorasCompletadas.toString(),
                  label: 'Horas Totales',
                  icon: Icons.timer_outlined,
                  color: Colors.yellow,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: _border),

            const SizedBox(height: 12),
            const Text(
              'Comparativa de Días Activos e Inactivos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: screenWidth * 0.35,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value == 0 ? 'Activos' : 'Inactivos');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: metrics.diasActivos.toDouble(),
                          color: Colors.green.shade400,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: metrics.diasInactivos.toDouble(),
                          color: Colors.redAccent,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            Container(height: 1, color: _border),

            const SizedBox(height: 12),
            const Text(
              'Ejercicios por Día de la Semana',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: screenWidth * 0.4,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                          if (value.toInt() >= 0 &&
                              value.toInt() < dias.length) {
                            return Text(dias[value.toInt()]);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(7, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: metrics.ejerciciosPorDiaSemana[i].toDouble(),
                          color: _blue,
                          width: 10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 24),
            Container(height: 1, color: _border),

            // --- Adherencia ---
            const SizedBox(height: 12),
            const Text(
              'Adherencia Total',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Indicador circular
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 95,
                      height: 95,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 9,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    SizedBox(
                      width: 95,
                      height: 95,
                      child: CircularProgressIndicator(
                        value: adherence / 100,
                        strokeWidth: 9,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.teal,
                        ),
                      ),
                    ),
                    Text(
                      '${adherence.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 24),

                // Leyenda
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _AdherenceStat(
                      // Usa el widget
                      color: Colors.teal,
                      label: 'Completados',
                      value: metrics.totalEjerciciosCompletados,
                    ),
                    const SizedBox(height: 10),
                    _AdherenceStat(
                      // Usa el widget
                      color: Colors.grey.shade500,
                      label: 'Asignados',
                      value: metrics.totalEjerciciosAsignados,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ======== TARJETA DE PLAN (con color de ícono según estado) ========
  Widget _buildPlanCard(PlanTomado plan) {
    final bool isInProgress = plan.estado == 'en_progreso';
    final String statusText = isInProgress
        ? 'EN PROGRESO'
        : plan.estado.toUpperCase();
    final Color statusColor = isInProgress ? Colors.blue : Colors.grey;

    return Card(
      elevation: 1,
      color: const Color(0xFFF9F9FC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(
          plan.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          plan.descripcion,
          style: const TextStyle(color: _muted),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Chip(
          avatar: Icon(
            isInProgress ? Icons.directions_run_rounded : Icons.check_circle,
            size: 16,
            color: statusColor,
          ),
          label: Text(
            statusText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: statusColor,
            ),
          ),
          backgroundColor: statusColor.withOpacity(0.1),
        ),
      ),
    );
  }
}

// ==============================================
// 🔹 COMPONENTES REUTILIZABLES
// ==============================================

// 🚀 --- CÓDIGO RESTAURADO ---
class _MetricBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _MetricBox({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      ],
    );
  }
}
// 🚀 --- FIN CÓDIGO RESTAURADO ---

// 🚀 --- CÓDIGO RESTAURADO ---
class _AdherenceStat extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _AdherenceStat({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
// 🚀 --- FIN CÓDIGO RESTAURADO ---