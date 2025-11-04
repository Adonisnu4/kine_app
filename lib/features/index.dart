import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/features/ejercicios/sesion_ejercicio_screen.dart';
import 'package:kine_app/services/planes_usuarios_service.dart'; // Servicio para las sesiones

// Suponiendo que PlanTomado es una clase definida en planes_usuarios_service.dart

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
    _reloadPlans(); // Llama a la función de recarga al inicio
  }

  // ⭐️ FUNCIÓN CLAVE: Recarga los datos y actualiza el FutureBuilder
  void _reloadPlans() {
    setState(() {
      _plansFuture = obtenerPlanesEnProgresoPorUsuario();
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
        // Usamos ListView para hacer toda la pantalla desplazable (incluyendo la Guía)
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

              // ------------------------------------
              // 🌟 BARRA SEPARADORA AÑADIDA
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Divider(
                  height: 30, // Espacio vertical alrededor del divisor
                  thickness: 1, // Grosor de la línea
                  color: Colors.black12, // Color de la línea
                ),
              ),
              // ------------------------------------

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
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    }

                    // Si no hay datos (la lista está vacía)
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize
                                .min, // Ocupar solo el espacio necesario verticalmente
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
                                  // 💡 Implementación para cambiar la pestaña en el HomeScreen
                                  final TabController? controller =
                                      DefaultTabController.of(context);

                                  if (controller != null) {
                                    // El índice 1 corresponde a la pestaña 'Ejercicios' (PlanEjercicioScreen)
                                    controller.animateTo(1);
                                  } else {
                                    print(
                                      'Error: TabController no encontrado.',
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 24,
                                ),
                                label: const Text('COMIENZA YA'),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: const Color.fromARGB(
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

                    // Si los datos están listos, muestra la lista de planes
                    final plans = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16.0,
                        0,
                        16.0,
                        16.0,
                      ), // Ajuste de padding
                      itemCount: plans.length,
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        return _PlanCard(
                          plan: plan,
                          // ⭐️ CAMBIO APLICADO AQUÍ
                          onTapResume: () {
                            _navigateToSession(plan.id);
                          },
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

// --- SECCIÓN DE LA GUÍA DE SALUD (Se mantiene igual) ---
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
          // Título específico de la Guía
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
            children: [
              const Icon(
                Icons.fitness_center,
                size: 20,
                color: Colors.blueAccent,
              ),
              const SizedBox(width: 8),
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
// ------------------------------------

// Widget de tarjeta para mostrar los detalles de un PlanTomado (Se mantiene igual)
class _PlanCard extends StatelessWidget {
  final PlanTomado plan;
  final VoidCallback onTapResume; // Callback para el botón de reanudar

  const _PlanCard({required this.plan, required this.onTapResume});

  @override
  Widget build(BuildContext context) {
    String estadoDisplay;
    Color estadoColor;
    bool showResumeButton = true; // Flag para mostrar el botón

    switch (plan.estado) {
      case 'terminado':
        estadoDisplay = 'Completado';
        estadoColor = Colors.green;
        showResumeButton = false; // No mostrar si está terminado
        break;
      case 'en_progreso':
        estadoDisplay = 'En progreso';
        estadoColor = Colors.orange;
        break;
      case 'pendiente':
        estadoDisplay = 'Pendiente';
        estadoColor = Colors.blueAccent; // Usaremos azul para pendiente/activo
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
            // --- NUEVA SECCIÓN PARA EL BOTÓN ---
            if (showResumeButton) ...[
              const Divider(height: 20),
              SizedBox(
                width: double.infinity, // Ocupar todo el ancho disponible
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
                    backgroundColor:
                        Colors.teal, // Un color que llame la atención
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
            // -----------------------------------
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
    // ... (Se mantiene igual)
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
