import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'plan_ejercicio_detalle_screen.dart';

/// si ya tienes esta clase en otro archivo, usa esa y borra esto
class AppColors {
  static const background = Color(0xFFF4F4F4);
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF47A5D6);     // del logo
  static const orange = Color(0xFFE28825);   // acento
  static const text = Color(0xFF101010);
  static const textMuted = Color(0xFF6D6D6D);
  static const border = Color(0x11000000);
}

class PlanEjercicioScreen extends StatefulWidget {
  const PlanEjercicioScreen({super.key});

  @override
  State<PlanEjercicioScreen> createState() => _PlanEjercicioScreenState();
}

class _PlanEjercicioScreenState extends State<PlanEjercicioScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- LÓGICA FIRESTORE ----------------
  Future<void> _tomarPlan({
    required String planId,
    required String planNombre,
  }) async {
    final User? usuarioActual = _auth.currentUser;

    if (usuarioActual == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: Debes iniciar sesión para empezar un plan.'),
        ),
      );
      return;
    }

    if (planId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error: El ID de este plan es inválido.'),
        ),
      );
      return;
    }

    final String usuarioId = usuarioActual.uid;

    try {
      final planesActivosQuery = _firestore
          .collection('plan_tomados_por_usuarios')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('activo', isEqualTo: true)
          .limit(1);

      final querySnapshot = await planesActivosQuery.get();

      if (querySnapshot.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text('Ya tienes un plan activo. ¡Termínalo primero!'),
          ),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al verificar tus planes: $e'),
        ),
      );
      return;
    }

    final Map<String, dynamic> planTomadoData = {
      'usuarioId': usuarioId,
      'planId': planId,
      'planNombre': planNombre,
      'fecha_inicio': FieldValue.serverTimestamp(),
      'activo': true,
      'progreso': {},
    };

    try {
      await _firestore
          .collection('plan_tomados_por_usuarios')
          .add(planTomadoData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('¡Plan "$planNombre" añadido a tu perfil!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('No se pudo añadir el plan: $e'),
        ),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // el header lo pone el HomeScreen, acá solo cuerpo
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // bloque de título como los otros
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: [
                  const Text(
                    'Planes disponibles',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Text(
                'Elige un plan y añádelo a tu progreso.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            // línea/acento sutil
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Container(
                height: 3.5,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            // LISTA
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('plan').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Ocurrió un error al cargar los planes:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.view_list_outlined,
                              size: 70,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No hay planes disponibles',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Pronto se añadirán nuevos planes de ejercicio.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot document = docs[index];
                      final data =
                          document.data() as Map<String, dynamic>;
                      final String planName =
                          data['nombre'] ?? 'Plan sin título';
                      final String planId = document.id;
                      final String? descripcion = data['descripcion'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),
                          leading: Container(
                            height: 42,
                            width: 42,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fitness_center_rounded,
                              color: AppColors.blue,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            planName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.5,
                              color: AppColors.text,
                            ),
                          ),
                          subtitle: descripcion != null && descripcion.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    descripcion,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textMuted,
                                      height: 1.25,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlanEjercicioDetalleScreen(
                                  planId: planId,
                                  planName: planName,
                                ),
                              ),
                            );
                          },
                          trailing: IconButton(
                            tooltip: 'Tomar plan',
                            onPressed: () => _tomarPlan(
                              planId: planId,
                              planNombre: planName,
                            ),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
