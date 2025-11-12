// lib/screens/KinePatientProgressScreen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 🔥 ¡CORREGIDO! Todos los imports apuntan a los archivos correctos.
import 'package:kine_app/features/ejercicios/models/plan_tomado.dart';
import 'package:kine_app/features/ejercicios/models/patient_metrics.dart';
import 'package:kine_app/features/ejercicios/service/metric_service.dart';
import 'package:kine_app/features/ejercicios/service/plan_service.dart';
import 'package:kine_app/features/ejercicios/screens/plan_ejercicio_detalle_screen.dart';

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

class _KinePatientProgressScreenState extends State<KinePatientProgressScreen> {
  final PlanService _planService = PlanService();
  final MetricsService _metricsService = MetricsService();
  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = _loadDashboardData();
  }

  Future<Map<String, dynamic>> _loadDashboardData() async {
    try {
      final metricsFuture = _metricsService.getPatientMetrics(widget.patientId);
      final plansFuture = _planService.obtenerPlanesPorPacienteId(
        widget.patientId,
      );
      final metrics = await metricsFuture;
      final plans = await plansFuture;
      return {'metrics': metrics, 'plans': plans};
    } catch (e) {
      throw Exception("Error al cargar datos del panel: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No se encontraron datos.'));
          }

          final PatientMetrics metrics = snapshot.data!['metrics'];
          final List<PlanTomado> plans = snapshot.data!['plans'];

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardData = _loadDashboardData();
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricsSection(metrics),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
                  child: Text(
                    'Planes Asignados',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(child: _buildPlansList(plans)),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- 🔥 MÉTRICAS ACTUALIZADAS (SIN HORAS) ---
  Widget _buildMetricsSection(PatientMetrics metrics) {
    final double adherence = (metrics.totalEjerciciosAsignados > 0)
        ? (metrics.totalEjerciciosCompletados /
                  metrics.totalEjerciciosAsignados) *
              100
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MetricBox(
                value: metrics.estaEnPlanActivo ? 'Activo' : 'Inactivo',
                label: 'Estado Actual',
                icon: metrics.estaEnPlanActivo
                    ? Icons.directions_run
                    : Icons.pause_circle,
                color: metrics.estaEnPlanActivo ? Colors.green : Colors.grey,
              ),
              _MetricBox(
                value: metrics.totalPlanesTerminados.toString(),
                label: 'Planes Completados',
                icon: Icons.check_circle_outline,
                color: Colors.blue,
              ),
              _MetricBox(
                value: metrics.diasActivos.toString(),
                label: 'Días Activos',
                icon: Icons.calendar_today_outlined,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adherencia Total: ${adherence.toStringAsFixed(0)}% (${metrics.totalEjerciciosCompletados} de ${metrics.totalEjerciciosAsignados} ej.)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: adherence / 100,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(List<PlanTomado> plans) {
    if (plans.isEmpty) {
      return const Center(
        child: Text('Este paciente no tiene planes asignados.'),
      );
    }

    plans.sort((a, b) {
      if (a.estado == 'en_progreso' && b.estado != 'en_progreso') return -1;
      if (a.estado != 'en_progreso' && b.estado == 'en_progreso') return 1;
      return b.fechaInicio.compareTo(a.fechaInicio);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        final bool isCompleted = plan.estado == 'terminado';
        final bool isInProgress = plan.estado == 'en_progreso';
        final Color statusColor;
        final IconData statusIcon;
        final String statusText;

        if (isCompleted) {
          statusColor = Colors.green.shade600;
          statusIcon = Icons.check_circle_rounded;
          statusText = 'COMPLETADO';
        } else if (isInProgress) {
          statusColor = Colors.blue.shade600;
          statusIcon = Icons.directions_run_rounded;
          statusText = 'EN PROGRESO';
        } else {
          statusColor = Colors.grey.shade600;
          statusIcon = Icons.pause_circle_rounded;
          statusText = plan.estado.toUpperCase();
        }

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        plan.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      avatar: Icon(statusIcon, color: statusColor, size: 18),
                      label: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: statusColor.withOpacity(0.1),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                  child: Text(
                    plan.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
                const Divider(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PROGRESO',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sesión ${plan.sesionActual + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'FECHA INICIO',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat(
                            'dd MMM yyyy',
                            'es_ES',
                          ).format(plan.fechaInicio),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Widget de KPI
class _MetricBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _MetricBox({
    required this.value,
    required this.label,
    required this.icon,
    this.color = Colors.black,
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
