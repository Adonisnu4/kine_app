import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/features/ejercicios/models/plan_tomado.dart';
import 'package:kine_app/features/ejercicios/screens/sesion_ejercicio_screen.dart';
import 'package:kine_app/features/ejercicios/service/plan_service.dart';

/// Paleta general usada en esta pantalla.
/// Coincide con la usada en pantallas como login y splash.
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF6F6F6);

  static const blue = Color(0xFF47A5D6); // color primario
  static const orange = Color(0xFFE28825); // color acento
  static const greyText = Color(0xFF8A9397);
  static const lightBorder = Color(0x11000000);
}

/// Pantalla principal del usuario tipo "Inicio".
/// Muestra:
///  - Guía básica de salud kinesiológica
///  - Tip animado que cambia cada 10s
///  - Lista de planes de ejercicios en progreso
class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  // Servicio para obtener los planes en progreso desde Firestore
  final PlanService _planService = PlanService();

  // Future usado por FutureBuilder para cargar planes
  late Future<List<PlanTomado>> _plansFuture;

  // Timer que rota los tips automáticamente
  late Timer _tipTimer;

  // Generador aleatorio para seleccionar tips distintos
  final Random _rnd = Random();

  // Lista completa de tips
  late List<String> _allTips;

  // Índice actual del tip mostrado
  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();

    // Tips cargados de forma local
    _allTips = const [
      'Muévete cada 45 min si trabajas sentado.',
      'Calienta antes de hacer fuerza.',
      'La técnica es más importante que la velocidad.',
      'Fortalece el core para cuidar tu espalda.',
      'No entrenes con dolor agudo.',
      'Respira profundo para relajar la musculatura.',
      'Aplica frío en las primeras 24-48h de una inflamación.',
      'Aplica calor si hay rigidez o tensión muscular.',
      'Estira después del ejercicio, no antes.',
      'Camina 30 min al día para mejorar circulación.',
      'Los glúteos fuertes protegen tu zona lumbar.',
      'Evita mirar el celular hacia abajo mucho rato.',
      'Duerme suficiente para que el cuerpo se recupere.',
      'No bloquees la respiración al levantar peso.',
      'Activa hombros y escápulas antes de empujar o tirar.',
      'En esguinces: protege, descarga y consulta.',
      'No copies rutinas de internet sin adaptación.',
      'El dolor no siempre es daño, pero obsérvalo.',
      'Haz ejercicios de equilibrio 2 veces por semana.',
      'Los adultos mayores también deben hacer fuerza.',
      'Alterna posturas: sentado, de pie, caminando.',
      'No cargues siempre todo en el mismo lado.',
      'Al levantar peso, acércalo a tu cuerpo.',
      'Si estás mucho tiempo sentado, haz estiramientos de flexores de cadera.',
      'Fortalece la espalda, no solo el pecho.',
      'Si manejas mucho, trabaja el cuello y hombros.',
      'En lumbago: movimiento suave > reposo absoluto.',
      'En tendón: carga progresiva y controlada.',
      'Calienta siempre antes de fútbol o pádel.',
      'Usa calzado acorde a tu actividad.',
      'Sé constante: poco pero todos los días.',
      'Registra tu dolor (0–10) para ver avances.',
      'Extiende columna si trabajas en PC.',
      'Haz pausas activas de cuello y hombros.',
      'Evita dormir boca abajo si tienes dolor cervical.',
      'Puentes de glúteo activan cadena posterior.',
      'Si hay hormigueo o pérdida de fuerza: consulta.',
      'Respira por la nariz para relajar.',
      'No mantengas la misma postura más de 1 hora.',
      'Fortalece tobillos si te esguinzas seguido.',
      'Post-op: sigue exactamente lo que dijo tu kine.',
      'Celebra pequeños avances de movilidad.',
    ];

    // Selección inicial aleatoria
    _currentTipIndex = _rnd.nextInt(_allTips.length);

    // Cargar lista de planes
    _reloadPlans();

    /// Timer que actualiza el tip cada 10 segundos.
    _tipTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      setState(() {
        _currentTipIndex = _getNextRandomIndex(_currentTipIndex);
      });
    });
  }

  @override
  void dispose() {
    _tipTimer.cancel();
    super.dispose();
  }

  /// Genera un índice aleatorio diferente al actual.
  int _getNextRandomIndex(int current) {
    if (_allTips.length <= 1) return current;

    int next = current;
    while (next == current) {
      next = _rnd.nextInt(_allTips.length);
    }
    return next;
  }

  /// Llama al servicio para recargar los planes en progreso.
  void _reloadPlans() {
    setState(() {
      _plansFuture = _planService.obtenerPlanesEnProgresoPorUsuario();
    });
  }

  /// Navega a la pantalla de sesión de ejercicios.
  /// Al volver, recarga los planes.
  void _navigateToSession(String ejecucionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SesionEjercicioScreen(ejecucionId: ejecucionId),
      ),
    );
    _reloadPlans();
  }

  @override
  Widget build(BuildContext context) {
    const pagePadding = EdgeInsets.symmetric(horizontal: 16.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Encabezado principal (título + barra naranja)
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
                child: Text(
                  'KineApp | Guías',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 10),
                child: Container(
                  width: 48,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              /// Bloque fijo de guía de salud
              const _HealthGuideSection(),

              /// Título de tips dinámicos
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 6),
                child: Text(
                  'Tips Kinesiológicos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              /// Tarjeta animada que muestra el tip actual
              Padding(
                padding: pagePadding,
                child: _TipChangingCard(
                  tip: _allTips[_currentTipIndex],
                  index: _currentTipIndex,
                  total: _allTips.length,
                ),
              ),

              /// Separador visual
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
                child: Divider(
                  height: 0,
                  thickness: 0.35,
                  color: Color(0x22000000),
                ),
              ),

              /// Título sección "Mis planes de ejercicios"
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Text(
                  'Mis planes de ejercicios',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),

              /// Contenido principal: lista de planes del usuario
              Expanded(
                child: FutureBuilder<List<PlanTomado>>(
                  future: _plansFuture,
                  builder: (context, snapshot) {
                    // Estado de carga
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Error en la consulta
                    if (snapshot.hasError) {
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          Text(
                            'Error al cargar: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      );
                    }

                    // Lista vacía
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'Actualmente no tienes planes de ejercicios en progreso.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // Envía al tab de ejercicios
                                final TabController controller =
                                    DefaultTabController.of(context);
                                controller.animateTo(1);
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Comenzar ahora'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 26,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    // Con datos → construir lista de planes
                    final plans = snapshot.data!;

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

/// Tarjeta animada que muestra un tip y cambia automáticamente.
/// Usa AnimatedSwitcher para transiciones suaves.
class _TipChangingCard extends StatelessWidget {
  final String tip;
  final int index;
  final int total;

  const _TipChangingCard({
    required this.tip,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) {
        return FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(tip),
        width: double.infinity,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Número del tip dentro de un círculo
            Container(
              height: 32,
              width: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.orange.withOpacity(.65)),
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 12),

            /// Texto del tip
            Expanded(
              child: Text(
                tip,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sección superior fija que muestra una mini guía informativa.
class _HealthGuideSection extends StatelessWidget {
  const _HealthGuideSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu Guía de Kinesiología',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Mantén tu rutina, respeta las cargas y sigue lo que te indicó tu kine.',
            style: TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 12),

          /// Chip informativo con el estado de la guía
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.timelapse, size: 16, color: AppColors.blue),
                SizedBox(width: 6),
                Text(
                  'Estado: en progreso',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta que muestra un plan de ejercicios tomado.
/// Incluye:
///  - nombre
///  - descripción
///  - sesión actual
///  - estado
///  - fecha inicio
///  - botón para iniciar/reanudar
class _PlanCard extends StatelessWidget {
  final PlanTomado plan;
  final VoidCallback onTapResume;

  const _PlanCard({required this.plan, required this.onTapResume});

  @override
  Widget build(BuildContext context) {
    String estadoDisplay;
    Color estadoColor;
    bool showResumeButton = true;

    /// Conversión de estado interno -> texto y color
    switch (plan.estado) {
      case 'terminado':
        estadoDisplay = 'Completado';
        estadoColor = Colors.green.shade600;
        showResumeButton = false;
        break;

      case 'en_progreso':
        estadoDisplay = 'En progreso';
        estadoColor = AppColors.orange;
        break;

      case 'pendiente':
        estadoDisplay = 'Pendiente';
        estadoColor = Colors.black87;
        break;

      default:
        estadoDisplay = 'Desconocido';
        estadoColor = Colors.grey;
        showResumeButton = false;
    }

    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 14.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.lightBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Nombre del plan
              Text(
                plan.nombre,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),

              /// Breve descripción
              Text(
                plan.descripcion,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),

              /// Fila con datos de sesión + estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: 'Sesión ${plan.sesionActual + 1}',
                  ),
                  _buildInfoChip(
                    icon: Icons.circle,
                    label: estadoDisplay,
                    color: estadoColor,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              /// Fecha de inicio
              Text(
                'Iniciado el: ${plan.fechaInicio.day}/${plan.fechaInicio.month}/${plan.fechaInicio.year}',
                style: const TextStyle(fontSize: 11.5, color: Colors.black45),
              ),

              /// Botón de acción si el plan no está completado
              if (showResumeButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onTapResume,
                    icon: Icon(
                      plan.estado == 'pendiente'
                          ? Icons.play_arrow_rounded
                          : Icons.redo_rounded,
                      size: 18,
                    ),
                    label: Text(
                      plan.estado == 'pendiente'
                          ? 'Iniciar sesión'
                          : 'Reanudar sesión',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF47A5D6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Construye un pequeño indicador con ícono + texto
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    Color color = Colors.black54,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
