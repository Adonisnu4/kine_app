import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// 💡 Importamos el servicio y el modelo que ya tienes
import 'package:kine_app/features/ejercicios/service/plan_service.dart';

/// Esta es la NUEVA PANTALLA que muestra el progreso
/// de los planes de un paciente específico.
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
  // Usamos el servicio que ya tienes
  final PlanService _planService = PlanService();
  // Un "Future" para guardar la lista de planes cuando se cargue
  late Future<List<PlanTomado>> _plansFuture;

  @override
  void initState() {
    super.initState();
    // 💡 Apenas se abre la pantalla, llamamos a la función del servicio
    //    para obtener los planes de ESE paciente
    _plansFuture = _planService.obtenerPlanesPorPacienteId(widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Progreso de ${widget.patientName}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<PlanTomado>>(
        future: _plansFuture, // Espera a que se carguen los planes
        builder: (context, snapshot) {
          // --- 1. Estado de Carga ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // --- 2. Estado de Error ---
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text('Error al cargar el progreso: ${snapshot.error}'),
              ),
            );
          }
          // --- 3. Estado Vacío ---
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Este paciente no ha tomado ningún plan de ejercicios.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // --- 4. Estado con Datos ---
          final planes = snapshot.data!;
          // Construye la lista de tarjetas
          return ListView.builder(
            padding: const EdgeInsets.all(10), // Espacio alrededor de la lista
            itemCount: planes.length,
            itemBuilder: (context, index) {
              final plan = planes[index];
              // Dibuja una tarjeta por cada plan
              return _buildPlanCard(plan);
            },
          );
        },
      ),
    );
  }

  /// Construye la tarjeta visual para cada plan
  Widget _buildPlanCard(PlanTomado plan) {
    final bool isCompleted = plan.estado == 'terminado';
    final bool isInProgress = plan.estado == 'en_progreso';

    // Define el estilo (color, ícono, texto) basado en el estado del plan
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
      statusText = plan.estado.toUpperCase(); // 'pausado', 'cancelado', etc.
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: statusColor.withOpacity(
            0.3,
          ), // Borde sutil del color del estado
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Fila Superior: Título y Estado ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título del Plan
                Flexible(
                  child: Text(
                    plan.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // Chip de Estado
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

            // Descripción corta
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

            // --- Fila Inferior: Detalles (Sesión / Fecha) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Sesión Actual
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
                      'Sesión ${plan.sesionActual + 1}', // Se suma 1 porque el índice 0 es la Sesión 1
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),

                // Fecha de Inicio
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
                      // Formatea la fecha (ej: 04 Nov 2025)
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
  }
}
