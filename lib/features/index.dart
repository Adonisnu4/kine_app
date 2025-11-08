import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/features/ejercicios/models/plan_tomado.dart';
import 'package:kine_app/features/ejercicios/screens/sesion_ejercicio_screen.dart';
import 'package:kine_app/features/ejercicios/service/plan_service.dart';

class Index extends StatefulWidget {
  const Index({super.key});

  @override
  State<Index> createState() => _IndexState();
}

class _IndexState extends State<Index> {
  // servicio
  final PlanService _planService = PlanService();
  late Future<List<PlanTomado>> _plansFuture;

  // tips auto
  late Timer _tipTimer;
  final Random _rnd = Random();
  late List<String> _allTips;
  int _currentTipIndex = 0;

  @override
  void initState() {
    super.initState();

    // lista de tips
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
      'Calienta SIEMPRE antes de fútbol o pádel.',
      'Usa calzado acorde a tu actividad.',
      'Sé constante: poco pero todos los días.',
      'Registra tu dolor (0-10) para ver avances.',
      'Extiende columna si trabajas en PC.',
      'Haz pausas activas de cuello y hombros.',
      'Evita dormir boca abajo si tienes dolor cervical.',
      'Puentes de glúteo → activa cadena posterior.',
      'Si hay hormigueo o pérdida de fuerza: consulta.',
      'Respira por la nariz para relajar.',
      'No mantengas la misma postura más de 1 hora.',
      'Fortalece tobillos si te esguinzas seguido.',
      'Post-op: sigue exactamente lo que dijo tu kine.',
      'Celebra pequeños avances de movilidad.',
    ];

    // tip inicial random
    _currentTipIndex = _rnd.nextInt(_allTips.length);

    // cargar planes
    _reloadPlans();

    // timer para cambiar tip
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

  int _getNextRandomIndex(int current) {
    if (_allTips.length <= 1) return current;
    int next = current;
    // evitar repetir el mismo seguido
    while (next == current) {
      next = _rnd.nextInt(_allTips.length);
    }
    return next;
  }

  void _reloadPlans() {
    setState(() {
      _plansFuture = _planService.obtenerPlanesEnProgresoPorUsuario();
    });
  }

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
        backgroundColor: const Color(0xFFF6F6F6),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // título
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
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

              // guía kinesiología
              const _HealthGuideSection(),

              // título tips
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

              // card que cambia
              Padding(
                padding: pagePadding,
                child: _TipChangingCard(
                  tip: _allTips[_currentTipIndex],
                  index: _currentTipIndex,
                  total: _allTips.length,
                ),
              ),

              // separador fino
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
                child: Divider(
                  height: 0,
                  thickness: 0.4,
                  color: Color(0x22000000),
                ),
              ),

              // título planes
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

              // contenido
              Expanded(
                child: FutureBuilder<List<PlanTomado>>(
                  future: _plansFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

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
                                final TabController controller =
                                    DefaultTabController.of(context);
                                controller.animateTo(1);
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Comenzar ahora'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 26,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final plans = snapshot.data!;
                    return ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
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

/// ---------- CARD que cambia de tip ----------
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0x11000000),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // numerito
            Container(
              height: 32,
              width: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x11000000),
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
            // texto
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

/// --- SECCIÓN DE LA GUÍA DE SALUD ---
class _HealthGuideSection extends StatelessWidget {
  const _HealthGuideSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0x11000000),
        ),
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
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x0F000000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.timelapse, size: 16, color: Colors.black87),
                SizedBox(width: 6),
                Text(
                  'Estado: en progreso',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
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

/// --- TARJETA DE PLAN ---
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
        estadoColor = Colors.green.shade600;
        showResumeButton = false;
        break;
      case 'en_progreso':
        estadoDisplay = 'En progreso';
        estadoColor = Colors.orange.shade700;
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
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.only(bottom: 14.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x11000000)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plan.nombre,
                style: const TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                plan.descripcion,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
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
              Text(
                'Iniciado el: ${plan.fechaInicio.day}/${plan.fechaInicio.month}/${plan.fechaInicio.year}',
                style: const TextStyle(fontSize: 11.5, color: Colors.black45),
              ),
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
                      backgroundColor: Colors.black,
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
