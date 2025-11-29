// Importa las herramientas base de Flutter para construir la interfaz.
import 'package:flutter/material.dart';

// Importa Firebase Firestore para acceder a la base de datos en la nube.
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa FirebaseAuth para obtener información del usuario autenticado.
import 'package:firebase_auth/firebase_auth.dart';

// Importa la pantalla que muestra el detalle del plan seleccionado.
import 'plan_ejercicio_detalle_screen.dart';

class AppColors {
  static const background = Color(0xFFF4F4F4);
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF47A5D6);
  static const orange = Color(0xFFE28825);
  static const text = Color(0xFF101010);
  static const textMuted = Color(0xFF6D6D6D);
  static const border = Color(0x11000000);
}

// Pantalla que muestra todos los planes disponibles.
class PlanEjercicioScreen extends StatefulWidget {
  const PlanEjercicioScreen({super.key});

  @override
  State<PlanEjercicioScreen> createState() => _PlanEjercicioScreenState();
}

class _PlanEjercicioScreenState extends State<PlanEjercicioScreen> {
  // Instancia de Firestore para leer los datos.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instancia de FirebaseAuth para obtener el usuario actual.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  //  LÓGICA FIRESTORE – TOMAR PLAN
  // Método para asociar un plan al usuario actual (crear un plan en progreso).
  Future<void> _tomarPlan({
    required String planId,
    required String planNombre,
  }) async {
    // Obtiene el usuario actualmente autenticado.
    final User? usuarioActual = _auth.currentUser;

    // Verifica si el usuario no ha iniciado sesión.
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

    // Verifica si el ID del plan es válido.
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

    // Obtiene el UID del usuario.
    final String usuarioId = usuarioActual.uid;

    try {
      // Consulta si el usuario ya tiene un plan activo.
      final planesActivosQuery = _firestore
          .collection('plan_tomados_por_usuarios')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('activo', isEqualTo: true)
          .limit(1);

      // Ejecuta la consulta.
      final querySnapshot = await planesActivosQuery.get();

      // Si existe un plan activo, mostrar mensaje y no permitir agregar otro.
      if (querySnapshot.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text('Ya tienes un plan activo. Termínalo primero.'),
          ),
        );
        return;
      }
    } catch (e) {
      // Error al consultar planes activos.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al verificar tus planes: $e'),
        ),
      );
      return;
    }

    // Datos del nuevo plan tomado.
    final Map<String, dynamic> planTomadoData = {
      'usuarioId': usuarioId, // usuario que toma el plan
      'planId': planId, // ID del plan
      'planNombre': planNombre, // nombre del plan
      'fecha_inicio': FieldValue.serverTimestamp(), // fecha desde servidor
      'activo': true, // marca que está en curso
      'progreso': {}, // progreso vacío al inicio
    };

    try {
      // Guarda el registro en la colección.
      await _firestore
          .collection('plan_tomados_por_usuarios')
          .add(planTomadoData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text('Plan "$planNombre" añadido a tu perfil.'),
        ),
      );
    } catch (e) {
      // Error al añadir el plan.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('No se pudo añadir el plan: $e'),
        ),
      );
    }
  }

  // Interfaz de usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de fondo de la pantalla.
      backgroundColor: AppColors.background,

      // SafeArea evita que el contenido quede detrás de elementos del sistema.
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Espacio superior inicial.
            const SizedBox(height: 6),

            // Título de la sección.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                children: const [
                  Text(
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

            // Subtítulo descriptivo.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Text(
                'Elige un plan y añádelo a tu progreso.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ),

            // Línea decorativa debajo del título.
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

            // LISTA DE PLANES - Contenido dinámico con StreamBuilder.
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Escucha en tiempo real la colección 'plan'.
                stream: _firestore.collection('plan').snapshots(),
                builder: (context, snapshot) {
                  // Error al cargar información.
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

                  // Estado de espera mientras se conecta al Stream.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Si no hay planes disponibles.
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

                  // Obtiene la lista de documentos retornados por Firestore.
                  final docs = snapshot.data!.docs;

                  // Construye la lista visualmente.
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot document = docs[index];

                      // Convierte los datos del documento a Map.
                      final data = document.data() as Map<String, dynamic>;

                      // Obtiene los datos del plan.
                      final String planName =
                          data['nombre'] ?? 'Plan sin título';
                      final String planId = document.id;
                      final String? descripcion = data['descripcion'];

                      // Tarjeta que representa un plan en la lista.
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

                        // Contenido interactivo del plan.
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 10.0,
                          ),

                          // Icono a la izquierda.
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

                          // Nombre del plan.
                          title: Text(
                            planName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.5,
                              color: AppColors.text,
                            ),
                          ),

                          // Descripción del plan, si existe.
                          subtitle:
                              descripcion != null && descripcion.isNotEmpty
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

                          // Abre la pantalla de detalle del plan.
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

                          // Botón para tomar el plan en progreso.
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
