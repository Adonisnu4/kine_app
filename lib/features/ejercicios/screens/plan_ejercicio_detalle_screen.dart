import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/features/ejercicios/screens/sesion_ejercicio_screen.dart';

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
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      // en tu proyecto puedes mostrar snackbar aquí
      throw Exception("Usuario no autenticado.");
    }

    if (sesionesMaestras.isEmpty) {
      debugPrint('⚠️ Error: El plan no tiene sesiones definidas.');
      return;
    }

    final String planId = widget.planId;
    if (planId.isEmpty) {
      debugPrint('⚠️ Error: planId no válido.');
      return;
    }

    final DocumentReference planRef = firestore.collection('plan').doc(planId);
    final DocumentReference userRef =
        firestore.collection('usuarios').doc(userId);

    // clonamos las sesiones para guardarlas en el progreso
    final List<Map<String, dynamic>> sesionesProgreso =
        sesionesMaestras.map((s) {
      final sessionMap = Map<String, dynamic>.from(s);
      sessionMap['completada'] = sessionMap['completada'] ?? false;
      return sessionMap;
    }).toList();

    final CollectionReference ejecucionCollection =
        firestore.collection('plan_tomados_por_usuarios');

    final DocumentReference ejecucionRef = await ejecucionCollection.add({
      'usuario': userRef,
      'plan': planRef,
      'estado': 'en_progreso',
      'fecha_inicio': FieldValue.serverTimestamp(),
      'sesion_actual': 0,
      'sesiones': sesionesProgreso,
    });

    debugPrint('✅ Nuevo plan iniciado: ${ejecucionRef.id}');

    // ir directo a la primera sesión
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SesionEjercicioScreen(
          ejecucionId: ejecucionRef.id,
        ),
      ),
    );
  }

  // ----------------------- BUILD -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
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

          final Map<String, dynamic> planData =
              snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> sesiones = planData['sesiones'] ?? [];
          final String descripcion =
              planData['descripcion'] ?? 'No hay descripción disponible.';
          final int duracionSemanas = planData['duracion_semanas'] ?? 0;

          if (sesiones.isEmpty) {
            return const Center(
              child: Text('Este plan aún no tiene sesiones asignadas.'),
            );
          }

          return Column(
            children: [
              _buildPlanInfoCard(
                context,
                descripcion,
                duracionSemanas,
              ),
              // lista de sesiones
              Expanded(child: _buildSesionesList(sesiones)),
              // botón fijo
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
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
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
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

  Widget _buildPlanInfoCard(
    BuildContext context,
    String descripcion,
    int duracionSemanas,
  ) {
    final String duracionText =
        duracionSemanas > 0 ? '$duracionSemanas semanas' : 'No especificada';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0x11000000)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.035),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Duración total: $duracionText',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
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
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.grey.shade700,
              height: 1.3,
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
        final Map<String, dynamic> sesionActual =
            sesiones[index] as Map<String, dynamic>;
        final int numeroSesion = sesionActual['numero_sesion'] ?? (index + 1);
        final dynamic ejerciciosData = sesionActual['ejercicios'];
        final bool sesionCompletada = sesionActual['completada'] == true;

        int totalEjerciciosSesion = 0;
        if (ejerciciosData is Map) {
          totalEjerciciosSesion = ejerciciosData.length;
        } else if (ejerciciosData is List) {
          totalEjerciciosSesion = ejerciciosData.length;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x11000000)),
          ),
          child: Theme(
            // para que el ExpansionTile no cambie el color
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              childrenPadding: const EdgeInsets.only(bottom: 10),
              leading: Icon(
                sesionCompletada
                    ? Icons.check_circle_rounded
                    : Icons.schedule_rounded,
                color: sesionCompletada ? Colors.green : Colors.black,
                size: 26,
              ),
              title: Text(
                'Sesión $numeroSesion',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color:
                      sesionCompletada ? Colors.grey.shade700 : Colors.black87,
                  decoration:
                      sesionCompletada ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                '$totalEjerciciosSesion ejercicios',
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                ),
              ),
              iconColor: Colors.black,
              collapsedIconColor: Colors.black54,
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
        final Map<String, dynamic> item = entry.value as Map<String, dynamic>;
        final bool completado = item['completado'] ?? false;
        final int tiempoSesion = item['tiempo_segundos'] ?? 0;
        final DocumentReference? ejercicioRef =
            item['ejercicio'] as DocumentReference?;

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
    final DocumentReference ejercicioRef =
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

        final Map<String, dynamic> ejercicioData =
            snapshot.data!.data() as Map<String, dynamic>;

        final String nombre =
            ejercicioData['nombre'] ?? 'Ejercicio sin nombre';

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
      contentPadding: const EdgeInsets.only(left: 58, right: 16),
      leading: Icon(
        completado ? Icons.check_circle : Icons.directions_run_rounded,
        color: completado ? Colors.green : Colors.black,
      ),
      title: Text(
        nombreEjercicio,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: completado ? Colors.grey.shade700 : Colors.black87,
          decoration: completado ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: tiempoSegundos > 0
          ? Text(
              'Duración: $tiempoSegundos seg',
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
            )
          : null,
    );
  }
}
