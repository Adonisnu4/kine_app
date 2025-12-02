import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'plan_ejercicio_detalle_screen.dart';

// --- Estilos de color (se mantienen igual) ---
class AppColors {
  static const background = Color(0xFFF4F4F4);
  static const white = Color(0xFFFFFFFF);
  static const blue = Color(0xFF47A5D6);
  static const orange = Color(0xFFE28825);
  static const text = Color(0xFF101010);
  static const textMuted = Color(0xFF6D6D6D);
  static const border = Color(0x11000000);
}

// --- Modelo de Zona de Trabajo para el filtro ---
class ZonaTrabajo {
  final String id;
  final String nombre;

  ZonaTrabajo({required this.id, required this.nombre});
}

// Pantalla que muestra todos los planes disponibles.
class PlanEjercicioScreen extends StatefulWidget {
  const PlanEjercicioScreen({super.key});

  @override
  State<PlanEjercicioScreen> createState() => _PlanEjercicioScreenState();
}

class _PlanEjercicioScreenState extends State<PlanEjercicioScreen> {
  // Instancias de Firestore y Auth.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- NUEVO ESTADO PARA EL FILTRO ---
  // Lista de zonas de trabajo disponibles (incluye una opción "Todos").
  List<ZonaTrabajo> _zonasDisponibles = [];
  // ID de la zona de trabajo seleccionada para filtrar. 'todos' por defecto.
  String _zonaSeleccionadaId = 'todos';
  // Referencia al documento 'zona_trabajo' de la zona seleccionada, o null para 'todos'.
  DocumentReference? _zonaSeleccionadaRef;

  @override
  void initState() {
    super.initState();
    _cargarZonasDeTrabajo();
  }

  // --- NUEVA LÓGICA FIRESTORE – CARGAR ZONAS DE TRABAJO ---
  Future<void> _cargarZonasDeTrabajo() async {
    try {
      // 1. Carga la colección de zonas de trabajo.
      final snapshot = await _firestore.collection('zona_trabajo').get();

      // 2. Mapea los documentos a objetos ZonaTrabajo.
      final zonas = snapshot.docs.map((doc) {
        return ZonaTrabajo(
          id: doc.id,
          nombre: doc.data()['nombre'] ?? 'Sin Nombre',
        );
      }).toList();

      // 3. Agrega la opción "Todos" al inicio de la lista.
      zonas.insert(
          0, ZonaTrabajo(id: 'todos', nombre: 'Todos los planes'));

      // 4. Actualiza el estado con las zonas disponibles.
      setState(() {
        _zonasDisponibles = zonas;
        // La zona seleccionada inicial es 'todos'.
        _zonaSeleccionadaRef = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Error al cargar zonas de trabajo: $e'),
        ),
      );
    }
  }

  // --- NUEVA LÓGICA DE FILTRADO ---
  void _seleccionarZona(String? newZonaId) {
    if (newZonaId == null || newZonaId == _zonaSeleccionadaId) return;

    setState(() {
      _zonaSeleccionadaId = newZonaId;
      if (newZonaId == 'todos') {
        _zonaSeleccionadaRef = null; // No aplica filtro
      } else {
        // Crea la referencia al documento de zona de trabajo
        _zonaSeleccionadaRef =
            _firestore.collection('zona_trabajo').doc(newZonaId);
      }
    });
  }

  // --- LÓGICA FIRESTORE – CONSULTA DE PLANES FILTRADA ---
  Stream<QuerySnapshot> _planesStream() {
    Query query = _firestore.collection('plan');

    // Aplica el filtro si no se ha seleccionado 'todos'.
    if (_zonaSeleccionadaRef != null) {
      // El campo 'zona_trabajo' en el documento 'plan' es de tipo DocumentReference
      query = query.where('zona_trabajo', isEqualTo: _zonaSeleccionadaRef);
    }

    // Opcionalmente, puedes ordenar la consulta.
    query = query.orderBy('nombre');

    return query.snapshots();
  }

  // LÓGICA FIRESTORE – TOMAR PLAN (se mantiene igual)
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
            content: Text('Ya tienes un plan activo. Termínalo primero.'),
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
          content: Text('Plan "$planNombre" añadido a tu perfil.'),
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

  // Interfaz de usuario
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            // Línea decorativa.
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

            // --- NUEVO WIDGET DE FILTRO (Dropdown) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x05000000),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _zonaSeleccionadaId,
                    icon: const Icon(Icons.filter_list),
                    hint: const Text('Filtrar por zona de trabajo'),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15.0,
                    ),
                    items: _zonasDisponibles.map((ZonaTrabajo zona) {
                      return DropdownMenuItem<String>(
                        value: zona.id,
                        child: Text(zona.nombre),
                      );
                    }).toList(),
                    onChanged: _seleccionarZona,
                  ),
                ),
              ),
            ),
            // --- FIN WIDGET DE FILTRO ---

            // LISTA DE PLANES - Contenido dinámico con StreamBuilder.
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Usa la nueva función de Stream que aplica el filtro.
                stream: _planesStream(),
                builder: (context, snapshot) {
                  // Manejo de errores y estados de carga/vacío (se mantiene igual)
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

                  final docs = snapshot.data!.docs;

                  if (docs.isEmpty) {
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
                              'No hay planes para la zona seleccionada.',
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

                  // Construye la lista visualmente. (Se mantiene igual)
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final DocumentSnapshot document = docs[index];
                      final data = document.data() as Map<String, dynamic>;

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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlanEjercicioDetalleScreen(
                                  planId: planId,
                                  planName: planName,
                                ),
                              ),
                            );
                          },
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