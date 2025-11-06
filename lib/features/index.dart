import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/features/ejercicios/models/plan_tomado.dart';
import 'package:kine_app/features/ejercicios/screens/sesion_ejercicio_screen.dart';
import 'package:kine_app/features/ejercicios/service/plan_service.dart'; // Servicio para las sesiones

// Suponiendo que PlanTomado es una clase definida en plan_service.dart o planes_usuarios_service.dart

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  // Instancia del servicio de planes
  final PlanService _planService = PlanService();

  // Almacena el Future para evitar recargas constantes al reconstruir el widget
  late Future<List<PlanTomado>> _plansFuture;

  @override
  void initState() {
    super.initState();
    // Llama a la función del servicio al inicializar el estado
    _reloadPlans(); // Llama a la función de recarga al inicio
  }

  // ⭐️ FUNCIÓN CLAVE: Recarga los datos y actualiza el FutureBuilder
  void _reloadPlans() {
    setState(() {
      _plansFuture = _planService.obtenerPlanesEnProgresoPorUsuario();
    });
  }

  // ⭐️ FUNCIÓN CLAVE: Maneja la navegación y la recarga al volver
  void _navigateToSession(String ejecucionId) async {
    // 1. Navegamos a la pantalla de sesión y ESPERAMOS el regreso (pop)
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SesionEjercicioScreen(ejecucionId: ejecucionId),
      ),
    );

    // 2. UNA VEZ QUE REGRESA (pop), forzamos la recarga de los planes
    _reloadPlans();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // status bar con iconos oscuros
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TÍTULO PRINCIPAL DE LA PÁGINA
              const Padding(
                padding: EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                child: Text(
                  'KineApp | Guias',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueAccent,
                  ),
                ),
              ),

              // 1. SECCIÓN: GUÍA DE SALUD
              const _HealthGuideSection(),

              // 🌟 BARRA SEPARADORA
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Divider(height: 30, thickness: 1, color: Colors.black12),
              ),

              // 2. TÍTULO DE LA SECCIÓN DE PLANES
              const Padding(
                padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
                child: Text(
                  'Mis Planes de Ejercicios',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              // 3. WIDGET DE FUTUROS PLANES (ocupa el espacio restante)
              Expanded(
                child: FutureBuilder<List<PlanTomado>>(
                  future: _plansFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Error al cargar: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Actualmente no tienes planes de ejercicios en progreso.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  final TabController controller =
                                      DefaultTabController.of(context);
                                  controller.animateTo(1);
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 24,
                                ),
                                label: const Text('COMIENZA YA'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Color.fromARGB(
                                    255,
                                    0,
                                    217,
                                    255,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // ✅ Lista de planes cargados
                    final plans = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        return _PlanCard(
                          plan: plan,
                          onTapResume: () => _navigateToSession(plan.id),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- SECCIÓN DE LA GUÍA DE SALUD ---
class _HealthGuideSection extends StatelessWidget {
  const _HealthGuideSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu Guía de Kinesiología 🧘‍♀️',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aquí verás tus planes de kinesiología activos. Mantente constante y sigue las indicaciones de tu especialista.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Icon(Icons.fitness_center, size: 20, color: Colors.blueAccent),
              SizedBox(width: 8),
              Text(
                'Estado: En progreso',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- TARJETA DE PLAN ---
class _PlanCard extends StatelessWidget {
  final PlanTomado plan;
  final VoidCallback onTapResume;

  const _PlanCard({required this.plan, required this.onTapResume});

  @override
  Widget build(BuildContext context) {
    String estadoDisplay;
    Color estadoColor;
    bool showResumeButton = true;

    switch (plan.estado) {
      case 'terminado':
        estadoDisplay = 'Completado';
        estadoColor = Colors.green;
        showResumeButton = false;
        break;
      case 'en_progreso':
        estadoDisplay = 'En progreso';
        estadoColor = Colors.orange;
        break;
      case 'pendiente':
        estadoDisplay = 'Pendiente';
        estadoColor = Colors.blueAccent;
        break;
      default:
        estadoDisplay = 'Desconocido';
        estadoColor = Colors.grey;
        showResumeButton = false;
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
                  label: 'Estado: $estadoDisplay',
                  color: estadoColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Iniciado el: ${plan.fechaInicio.day}/${plan.fechaInicio.month}/${plan.fechaInicio.year}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (showResumeButton) ...[
              const Divider(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTapResume,
                  icon: Icon(
                    plan.estado == 'pendiente' ? Icons.play_arrow : Icons.redo,
                    size: 24,
                  ),
                  label: Text(
                    plan.estado == 'pendiente'
                        ? 'INICIAR SESIÓN'
                        : 'REANUDAR SESIÓN',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
