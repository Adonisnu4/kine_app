import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:kine_app/features/ejercicios/screens/sesion_ejercicio_screen.dart';

class AppColors {
  static const background = Color(0xFFF6F6F7);
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF47A5D6);
  static const orange = Color(0xFFE28825);
  static const text = Color(0xFF101010);
  static const textMuted = Color(0xFF6D6D6D);
  static const border = Color(0x11000000);
}

/// Pantalla principal que muestra el detalle de un Plan de Ejercicios
class PlanEjercicioDetalleScreen extends StatefulWidget {
  final String planId; // ID del plan en Firestore
  final String planName; // Nombre del plan para mostrar en el AppBar

  const PlanEjercicioDetalleScreen({
    super.key,
    required this.planId,
    required this.planName,
  });

  @override
  State<PlanEjercicioDetalleScreen> createState() =>
      _PlanEjercicioDetalleScreenState();
}

/// Estado de la pantalla
class _PlanEjercicioDetalleScreenState
    extends State<PlanEjercicioDetalleScreen> {
  // Instancia de Firestore para realizar consultas
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controla si la descripción del plan está expandida o contraída
  bool _descExpanded = false;

  // COMENZAR PLAN

  // Método que crea un registro en "plan_tomados_por_usuarios"
  // y marca el inicio de un plan para un usuario
  Future<void> _comenzarPlan(List<dynamic> sesionesMaestras) async {
    final firestore = FirebaseFirestore.instance;

    // Obtiene el ID del usuario actual
    final userId = FirebaseAuth.instance.currentUser?.uid;

    // Si no hay usuario autenticado, devolver error
    if (userId == null) throw Exception("Usuario no autenticado.");

    // Si el plan no tiene sesiones maestras, no continuar
    if (sesionesMaestras.isEmpty) return;

    // Obtiene el ID del plan que se está visualizando
    final planId = widget.planId;
    if (planId.isEmpty) return;

    // Referencia al documento del plan
    final planRef = firestore.collection('plan').doc(planId);

    // Referencia al documento del usuario
    final userRef = firestore.collection('usuarios').doc(userId);

    // Prepara la copia del arreglo de sesiones para registrar progreso
    final sesionesProgreso = sesionesMaestras.map((s) {
      final sessionMap = Map<String, dynamic>.from(s);
      // Si no existe campo completada, se asigna false
      sessionMap['completada'] = sessionMap['completada'] ?? false;
      return sessionMap;
    }).toList();

    // Crea un nuevo documento en la colección "plan_tomados_por_usuarios"
    final ejecucionRef = await firestore
        .collection('plan_tomados_por_usuarios')
        .add({
          'usuario': userRef, // referencia al usuario
          'plan': planRef, // referencia al plan
          'estado': 'en_progreso', // estado inicial
          'fecha_inicio': FieldValue.serverTimestamp(), // fecha desde servidor
          'sesion_actual': 0, // índice de sesión actual
          'sesiones': sesionesProgreso, // copia de sesiones
        });

    // Verifica si la pantalla sigue montada antes de navegar
    if (!mounted) return;

    // Navega a la pantalla de ejecución de sesión
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SesionEjercicioScreen(ejecucionId: ejecucionRef.id),
      ),
    );
  }

  //Interfaz de usuario

  // Método que construye toda la interfaz de la pantalla
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // Barra superior
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          widget.planName, // Muestra nombre del plan
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),

      // StreamBuilder escucha cambios en tiempo real del plan
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('plan').doc(widget.planId).snapshots(),
        builder: (context, snapshot) {
          // Si hay error al leer Firestore
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar el plan: ${snapshot.error}'),
            );
          }

          // Mientras se establece la conexión
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si no existe el documento
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el plan.'));
          }

          // Extrae campos del plan
          final planData = snapshot.data!.data() as Map<String, dynamic>;
          final sesiones = planData['sesiones'] as List<dynamic>? ?? [];
          final descripcion =
              (planData['descripcion'] as String?) ?? 'Sin descripción.';
          final duracionSemanas = planData['duracion_semanas'] ?? 0;

          // Si el plan no tiene sesiones
          if (sesiones.isEmpty) {
            return const Center(
              child: Text('Este plan aún no tiene sesiones asignadas.'),
            );
          }

          // Calcula totales
          final totalSesiones = sesiones.length;
          final totalEjercicios = _countAllExercises(sesiones);

          // Construye la interfaz principal
          return Column(
            children: [
              _HeaderBar(), // Línea naranja decorativa
              // Tarjeta superior con información del plan
              _buildPlanInfoCard(
                descripcion: descripcion,
                duracionSemanas: duracionSemanas,
                totalSesiones: totalSesiones,
                totalEjercicios: totalEjercicios,
              ),

              // Lista de sesiones
              Expanded(child: _buildSesionesList(sesiones)),

              // Botones inferiores
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tips del plan próximamente'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: AppColors.blue,
                            width: 1,
                          ),
                          foregroundColor: AppColors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(0, 50),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Ver tips'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _comenzarPlan(sesiones),
                        icon: const Icon(Icons.play_arrow_rounded, size: 24),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6.0),
                          child: Text(
                            'Comenzar plan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.1,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  //TARJETA SUPERIOR

  // Construye la tarjeta con información del plan
  Widget _buildPlanInfoCard({
    required String descripcion,
    required int duracionSemanas,
    required int totalSesiones,
    required int totalEjercicios,
  }) {
    // Texto para duración
    final duracionText = duracionSemanas > 0
        ? '$duracionSemanas semanas'
        : 'No especificada';

    // Decide número de líneas si la descripción está expandida o no
    final maxLines = _descExpanded ? 99 : 3;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila con indicadores
          Row(
            children: [
              _Badge(icon: Icons.calendar_month_rounded, label: duracionText),
              const SizedBox(width: 8),
              _Badge(
                icon: Icons.playlist_add_check_rounded,
                label: '$totalSesiones sesiones',
              ),
              const SizedBox(width: 8),
              _Badge(
                icon: Icons.fitness_center_rounded,
                label: '$totalEjercicios ejercicios',
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1, color: Color(0x11000000)),

          const SizedBox(height: 12),

          const Text(
            'Descripción del plan',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            descripcion,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 8),

          // Botón de "ver más" o "ver menos"
          GestureDetector(
            onTap: () => setState(() => _descExpanded = !_descExpanded),
            child: Text(
              _descExpanded ? 'Ver menos' : 'Ver más',
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Barra decorativa naranja
          Container(
            width: 44,
            height: 3.5,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }

  // LISTA DE SESIONES

  Widget _buildSesionesList(List<dynamic> sesiones) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 12),
      itemCount: sesiones.length,
      itemBuilder: (context, index) {
        final sesionActual = sesiones[index] as Map<String, dynamic>;

        final numeroSesion = sesionActual['numero_sesion'] ?? (index + 1);

        final ejerciciosData = sesionActual['ejercicios'];

        final sesionCompletada = sesionActual['completada'] == true;

        int totalEjerciciosSesion = 0;

        // Calcula total según tipo de estructura
        if (ejerciciosData is Map) {
          totalEjerciciosSesion = ejerciciosData.length;
        } else if (ejerciciosData is List) {
          totalEjerciciosSesion = ejerciciosData.length;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),

              // Icono que indica si está completada
              leading: Container(
                height: 32,
                width: 32,
                decoration: BoxDecoration(
                  color: sesionCompletada
                      ? Colors.green.withOpacity(.12)
                      : AppColors.blue.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  sesionCompletada
                      ? Icons.check_rounded
                      : Icons.access_time_rounded,
                  color: sesionCompletada ? Colors.green : AppColors.blue,
                  size: 18,
                ),
              ),

              // Título de la sesión
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sesión $numeroSesion',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: sesionCompletada
                            ? AppColors.textMuted
                            : AppColors.text,
                        decoration: sesionCompletada
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),

                  // Chip de estado
                  _StatusChip(
                    text: sesionCompletada ? 'Completada' : 'Pendiente',
                    color: sesionCompletada ? Colors.green : AppColors.blue,
                  ),
                ],
              ),

              // Subtítulo con el número de ejercicios
              subtitle: Text(
                '$totalEjerciciosSesion ejercicios',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),

              iconColor: AppColors.text,
              collapsedIconColor: AppColors.textMuted,

              // Construye la lista de ejercicios de esta sesión
              children: _buildEjerciciosList(ejerciciosData),
            ),
          ),
        );
      },
    );
  }

  // LISTA DE EJERCICIOS

  List<Widget> _buildEjerciciosList(dynamic ejerciciosData) {
    // Manejo si no hay ejercicios
    if (ejerciciosData == null ||
        (ejerciciosData is Map && ejerciciosData.isEmpty) ||
        (ejerciciosData is List && ejerciciosData.isEmpty)) {
      return const [ListTile(title: Text('No hay ejercicios en esta sesión.'))];
    }

    // Si ejerciciosData es un Map
    if (ejerciciosData is Map<String, dynamic>) {
      return ejerciciosData.entries.map<Widget>((entry) {
        final item = entry.value as Map<String, dynamic>;
        final completado = item['completado'] ?? false;
        final tiempoSesion = item['tiempo_segundos'] ?? 0;

        final ejercicioRef = item['ejercicio'] as DocumentReference?;

        if (ejercicioRef == null) {
          return const ListTile(
            title: Text('Ejercicio sin referencia'),
            subtitle: Text('Falta el documento del ejercicio.'),
          );
        }

        // Construye un ListTile desde Firestore
        return _buildEjercicioTileFromRef(
          ejercicioRef.id,
          completado,
          tiempoSesion,
        );
      }).toList();
    }

    return const [ListTile(title: Text('Error de formato de ejercicios.'))];
  }

  // Lee un ejercicio desde Firestore y lo transforma en widget
  Widget _buildEjercicioTileFromRef(
    String ejercicioId,
    bool completado,
    int tiempoSesion,
  ) {
    final ejercicioRef = _firestore.collection('ejercicios').doc(ejercicioId);

    return StreamBuilder<DocumentSnapshot>(
      stream: ejercicioRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Cargando ejercicio...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: Text('Error al cargar ejercicio ID: $ejercicioId'),
          );
        }

        final ejercicioData = snapshot.data!.data() as Map<String, dynamic>;
        final nombre = ejercicioData['nombre'] ?? 'Ejercicio sin nombre';

        return _buildEjercicioTile(
          nombreEjercicio: nombre,
          tiempoSegundos: tiempoSesion,
          completado: completado,
        );
      },
    );
  }

  // Construye un tile visual para un ejercicio
  Widget _buildEjercicioTile({
    required String nombreEjercicio,
    required int tiempoSegundos,
    required bool completado,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),

        // Icono circular
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: (completado ? Colors.green : AppColors.blue).withOpacity(
              .12,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            completado ? Icons.check_circle : Icons.directions_run_rounded,
            color: completado ? Colors.green : AppColors.blue,
            size: 18,
          ),
        ),

        // Nombre del ejercicio
        title: Text(
          nombreEjercicio,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: completado ? AppColors.textMuted : AppColors.text,
            decoration: completado ? TextDecoration.lineThrough : null,
          ),
        ),

        // Duración si corresponde
        subtitle: tiempoSegundos > 0
            ? Text(
                'Duración recomendada: $tiempoSegundos seg',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              )
            : null,
      ),
    );
  }

  // utilidades

  // Cuenta la cantidad total de ejercicios del plan
  int _countAllExercises(List<dynamic> sesiones) {
    int total = 0;
    for (final s in sesiones) {
      final m = s as Map<String, dynamic>;
      final ex = m['ejercicios'];
      if (ex is Map) total += ex.length;
      if (ex is List) total += ex.length;
    }
    return total;
  }
}

// widgets pequeños reutilizables
/// Barra decorativa naranja al inicio
class _HeaderBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 48,
        height: 3.5,
        margin: const EdgeInsets.fromLTRB(16, 10, 0, 6),
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

/// Badge pequeño reutilizable
class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.blue, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip que muestra el estado (completada o pendiente)
class _StatusChip extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: -.1,
        ),
      ),
    );
  }
}
