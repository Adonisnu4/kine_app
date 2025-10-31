import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/services/user_planes_taken.dart';

// Importa las funciones y clases del servicio

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  // Almacena el Future para evitar recargas constantes al reconstruir el widget
  late Future<List<PlanTomado>> _plansFuture;

  @override
  void initState() {
    super.initState();
    // Llama a la función del servicio al inicializar el estado
    _plansFuture = obtenerPlanesPorUsuario();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // status bar con iconos oscuros
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Planes de Kinesiología'),
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        backgroundColor: Colors.grey[50],
        body: FutureBuilder<List<PlanTomado>>(
          future: _plansFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // Muestra un indicador de carga mientras se obtienen los datos
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              // Muestra el error en caso de fallo (útil para debug)
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Error al cargar: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              );
            }

            // Si no hay datos (la lista está vacía)
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  // Usamos Column para apilar el mensaje y el botón
                  child: Column(
                    mainAxisSize: MainAxisSize
                        .min, // Ocupar solo el espacio necesario verticalmente
                    children: [
                      const Text(
                        'Aún no has tomado ningún plan de ejercicios.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                      const SizedBox(
                        height: 20,
                      ), // Espacio entre el texto y el botón
                      ElevatedButton.icon(
                        onPressed: () {
                          // 💡 Implementación para cambiar la pestaña en el HomeScreen

                          final TabController? controller =
                              DefaultTabController.of(context);

                          if (controller != null) {
                            // El índice 1 corresponde a la pestaña 'Ejercicios' (PlanEjercicioScreen) en el HomeScreen del paciente.
                            print("Si");
                            controller.animateTo(1);
                          } else {
                            // Manejo de errores si el controlador no se encuentra (no debería pasar)
                            print('Error: TabController no encontrado.');
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline, size: 24),
                        label: const Text(
                          'COMENZA YA',
                          // ... otros estilos
                        ),
                        // ... otros estilos del botón
                      ),
                    ],
                  ),
                ),
              );
            }

            // Si los datos están listos, muestra la lista de planes
            final plans = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: plans.length,
              itemBuilder: (context, index) {
                final plan = plans[index];
                return _PlanCard(plan: plan);
              },
            );
          },
        ),
      ),
    );
  }
}

// Widget de tarjeta para mostrar los detalles de un PlanTomado
class _PlanCard extends StatelessWidget {
  final PlanTomado plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    String estadoDisplay;
    Color estadoColor;

    switch (plan.estado) {
      case 'terminado':
        estadoDisplay = 'Completado';
        estadoColor = Colors.green;
        break;
      case 'en_progreso':
        estadoDisplay = 'En progreso'; // <-- ¡Este es el cambio para mostrar!
        estadoColor = Colors.orange;
        break;
      case 'pendiente':
        estadoDisplay = 'Pendiente';
        estadoColor = Colors.blueGrey;
        break;
      default:
        estadoDisplay = 'Desconocido';
        estadoColor = Colors.grey;
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              plan.nombre,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              plan.descripcion,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(
                  icon: Icons.access_time,
                  label: 'Sesión: ${plan.sesionActual + 1}',
                ),
                _buildInfoChip(
                  icon: Icons.check_circle_outline,
                  label: 'Estado: ${estadoDisplay}',
                  color: estadoColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Iniciado el: ${plan.fechaInicio.day}/${plan.fechaInicio.month}/${plan.fechaInicio.year}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // Pequeño widget auxiliar para mostrar información en 'chips'
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color color = Colors.black54,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
