import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/features/ejercicios/screens/sesion_ejercicio_screen.dart';

/// Si ya tienes esta clase en otro archivo, usa esa y borra esta.
class AppColors {
  static const background = Color(0xFFF4F4F4);
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF47A5D6);     // azul del logo
  static const orange = Color(0xFFE28825);   // acento
  static const text = Color(0xFF101010);
  static const textMuted = Color(0xFF6D6D6D);
  static const border = Color(0x11000000);
}

class PlanEjercicioDetalleScreen extends StatefulWidget {
  final String planId;
  final String planName;

  const PlanEjercicioDetalleScreen({
    super.key,
    required this.planId,
    required this.planName,
  });

  @override
  State<PlanEjercicioDetalleScreen> createState() =>
      _PlanEjercicioDetalleScreenState();
}

class _PlanEjercicioDetalleScreenState
    extends State<PlanEjercicioDetalleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ----------------------- COMENZAR PLAN -----------------------
  void _comenzarPlan(List<dynamic> sesionesMaestras) async {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      // aquí puedes mostrar un snackbar
      throw Exception("Usuario no autenticado.");
    }

    if (sesionesMaestras.isEmpty) {
      debugPrint('⚠️ El plan no tiene sesiones definidas.');
      return;
    }

    final planId = widget.planId;
    if (planId.isEmpty) {
      debugPrint('⚠️ planId no válido.');
      return;
    }

    final planRef = firestore.collection('plan').doc(planId);
    final userRef = firestore.collection('usuarios').doc(userId);

    final sesionesProgreso = sesionesMaestras.map((s) {
      final sessionMap = Map<String, dynamic>.from(s);
      sessionMap['completada'] = sessionMap['completada'] ?? false;
      return sessionMap;
    }).toList();

    final ejecucionRef =
        await firestore.collection('plan_tomados_por_usuarios').add({
      'usuario': userRef,
      'plan': planRef,
      'estado': 'en_progreso',
      'fecha_inicio': FieldValue.serverTimestamp(),
      'sesion_actual': 0,
      'sesiones': sesionesProgreso,
    });

    // ir a la sesión
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SesionEjercicioScreen(
          ejecucionId: ejecucionRef.id,
        ),
      ),
    );
  }

  // ----------------------- BUILD -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Text(
          widget.planName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('plan').doc(widget.planId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar el plan: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el plan.'));
          }

          final planData =
              snapshot.data!.data() as Map<String, dynamic>;
          final sesiones = planData['sesiones'] as List<dynamic>? ?? [];
          final descripcion =
              planData['descripcion'] ?? 'No hay descripción disponible.';
          final duracionSemanas = planData['duracion_semanas'] ?? 0;

          if (sesiones.isEmpty) {
            return const Center(
              child: Text('Este plan aún no tiene sesiones asignadas.'),
            );
          }

          return Column(
            children: [
              _buildPlanInfoCard(descripcion, duracionSemanas),
              Expanded(child: _buildSesionesList(sesiones)),
              // botón fijo abajo
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: ElevatedButton.icon(
                  onPressed: () => _comenzarPlan(sesiones),
                  icon: const Icon(Icons.play_arrow_rounded, size: 26),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(
                      'Comenzar plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .1,
                      ),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFE28825),
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
          );
        },
      ),
    );
  }

  // ----------------------- UI HELPERS -----------------------
  Widget _buildPlanInfoCard(String descripcion, int duracionSemanas) {
    final duracionText =
        duracionSemanas > 0 ? '$duracionSemanas semanas' : 'No especificada';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Duración total: $duracionText',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0x11000000)),
          const SizedBox(height: 14),
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
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          // acento naranja chiquito
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSesionesList(List<dynamic> sesiones) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      itemCount: sesiones.length,
      itemBuilder: (context, index) {
        final sesionActual = sesiones[index] as Map<String, dynamic>;
        final numeroSesion = sesionActual['numero_sesion'] ?? (index + 1);
        final ejerciciosData = sesionActual['ejercicios'];
        final sesionCompletada = sesionActual['completada'] == true;

        int totalEjerciciosSesion = 0;
        if (ejerciciosData is Map) {
          totalEjerciciosSesion = ejerciciosData.length;
        } else if (ejerciciosData is List) {
          totalEjerciciosSesion = ejerciciosData.length;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              childrenPadding: const EdgeInsets.only(bottom: 10),
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
              title: Text(
                'Sesión $numeroSesion',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: sesionCompletada
                      ? AppColors.textMuted
                      : AppColors.text,
                  decoration:
                      sesionCompletada ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                '$totalEjerciciosSesion ejercicios',
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
              iconColor: AppColors.text,
              collapsedIconColor: AppColors.textMuted,
              children: _buildEjerciciosList(ejerciciosData),
            ),
          ),
        );
      },
    );
  }

  // ----------------------- ejercicios -----------------------
  List<Widget> _buildEjerciciosList(dynamic ejerciciosData) {
    if (ejerciciosData == null ||
        (ejerciciosData is Map && ejerciciosData.isEmpty) ||
        (ejerciciosData is List && ejerciciosData.isEmpty)) {
      return const [
        ListTile(
          title: Text('No hay ejercicios en esta sesión.'),
        )
      ];
    }

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

        return _buildEjercicioTileFromRef(
          ejercicioRef.id,
          completado,
          tiempoSesion,
        );
      }).toList();
    }

    return const [
      ListTile(title: Text('Error de formato de ejercicios.')),
    ];
  }

  Widget _buildEjercicioTileFromRef(
    String ejercicioId,
    bool completado,
    int tiempoSesion,
  ) {
    final ejercicioRef =
        _firestore.collection('ejercicios').doc(ejercicioId);

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

        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: Text('Error al cargar ejercicio ID: $ejercicioId'),
          );
        }

        final ejercicioData =
            snapshot.data!.data() as Map<String, dynamic>;
        final nombre = ejercicioData['nombre'] ?? 'Ejercicio sin nombre';

        return _buildEjercicioTile(
          nombreEjercicio: nombre,
          tiempoSegundos: tiempoSesion,
          completado: completado,
        );
      },
    );
  }

  Widget _buildEjercicioTile({
    required String nombreEjercicio,
    required int tiempoSegundos,
    required bool completado,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 60, right: 16),
      leading: Icon(
        completado ? Icons.check_circle : Icons.directions_run_rounded,
        color: completado ? Colors.green : AppColors.text,
      ),
      title: Text(
        nombreEjercicio,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: completado ? AppColors.textMuted : AppColors.text,
          decoration: completado ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: tiempoSegundos > 0
          ? Text(
              'Duración: $tiempoSegundos seg',
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            )
          : null,
    );
  }
}
