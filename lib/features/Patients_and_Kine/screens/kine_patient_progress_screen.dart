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
  final PlanService _planService = PlanService();
  final MetricsService _metricsService = MetricsService();

  late Future<Map<String, dynamic>> _dashboardData;
  late AnimationController _animationController;

  bool _mostrarTodosLosPlanes = false; // 👈 Nuevo estado para “Ver más”

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
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text('Progreso de ${widget.patientName}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontraron datos.'));
          }

          final metrics = snapshot.data!['metrics'] as PatientMetrics;
          final plans = snapshot.data!['plans'] as List<PlanTomado>;

          // 👇 Limita la cantidad de planes mostrados
          final planesVisibles = _mostrarTodosLosPlanes
              ? plans
              : plans.take(5).toList();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _dashboardData = _loadDashboardData());
            },
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildMetricsDashboard(metrics),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                const Text(
                  'Planes Asignados',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // 👇 Lista de planes limitada
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
                          color: Colors.teal,
                        ),
                        label: Text(
                          _mostrarTodosLosPlanes
                              ? 'Ver menos'
                              : 'Ver todos (${plans.length})',
                          style: const TextStyle(
                            color: Colors.teal,
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

  // ==============================================
  // 🔹 PANEL DE MÉTRICAS
  // ==============================================
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                color: Colors.teal,
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
                  color: Colors.deepPurple,
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),

            // --- Gráfico 1 ---
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
            const Divider(),

            // --- Gráfico 2 ---
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
                          color: Colors.teal,
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
            const Divider(),

            // --- Adherencia ---
            const SizedBox(height: 24),
            const Divider(),
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
                // 🔹 Indicador circular limpio y proporcionado
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

                // 🔹 Leyenda limpia y alineada verticalmente
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.teal, size: 12),
                        const SizedBox(width: 8),
                        Text(
                          '${metrics.totalEjerciciosCompletados} Completados',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: Colors.grey.shade500,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${metrics.totalEjerciciosAsignados} Asignados',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  // ==============================================
  // 🔹 TARJETA DE PLAN
  // ==============================================
  Widget _buildPlanCard(PlanTomado plan) {
    final bool isInProgress = plan.estado == 'en_progreso';
    return Card(
      elevation: 1,
      color: const Color(0xFFF9F9FC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          plan.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          plan.descripcion,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        trailing: Chip(
          avatar: const Icon(
            Icons.directions_run_rounded,
            size: 16,
            color: Colors.blue,
          ),
          label: Text(
            isInProgress ? 'EN PROGRESO' : plan.estado.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blue,
            ),
          ),
          backgroundColor: Colors.blue.shade50,
        ),
      ),
    );
  }
}

// ==============================================
// 🔹 COMPONENTES REUTILIZABLES
// ==============================================
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
