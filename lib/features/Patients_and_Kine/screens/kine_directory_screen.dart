import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/features/Patients_and_Kine/services/kine_service.dart';
import 'kine_presentation_screen.dart';
import '../../auth/screens/profile_screen.dart';

/// Pantalla que muestra un directorio de kinesiólogos disponibles.
class KineDirectoryScreen extends StatefulWidget {
  const KineDirectoryScreen({super.key});

  @override
  State<KineDirectoryScreen> createState() => _KineDirectoryScreenState();
}

class _KineDirectoryScreenState extends State<KineDirectoryScreen> {
  final KineService _kineService = KineService();

  // Future que almacenará la carga inicial del directorio
  late Future<List<Map<String, dynamic>>> _kineListFuture;

  @override
  void initState() {
    super.initState();

    // Carga inicial del directorio al abrir la pantalla
    _kineListFuture = _kineService.getKineDirectory();
  }

  /// Recarga la lista de kinesiólogos (útil al volver de otra pantalla)
  void _reloadKineList() {
    setState(() {
      _kineListFuture = _kineService.getKineDirectory();
    });
  }

  /// Maneja la navegación cuando el usuario toca un kinesiólogo de la lista.
  /// Si toca su propio perfil, lo lleva a su PerfilScreen.
  /// Si toca otro kinesiólogo, lo lleva a su presentación profesional.
  void _navigateToKineScreen(Map<String, dynamic> kine) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    final Widget destinationScreen;

    // Si el usuario toca su propio elemento, mostrar su perfil personal
    if (currentUserId != null && kine['id'] == currentUserId) {
      destinationScreen = const ProfileScreen();
    } else {
      // Sino muestra la presentación del kinesiólogo seleccionado

      // Convertimos todos los valores a String para evitar errores
      destinationScreen = KinePresentationScreen(
        kineId: kine['id']!,
        kineData: kine.map((key, value) {
          return MapEntry(key, value?.toString() ?? '');
        }),
      );
    }

    // Navega a la pantalla correspondiente
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );

    // Al volver, recargamos la lista por si hubo cambios
    _reloadKineList();
  }

  @override
  Widget build(BuildContext context) {
    // Paleta local usada en esta pantalla
    const background = Color(0xFFF4F4F4);
    const blue = Color(0xFF47A5D6);
    const orange = Color(0xFFE28825);

    return Scaffold(
      backgroundColor: background,

      // El AppBar lo gestiona la pantalla Home
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Título + subtítulo + barra naranja
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                // Título principal
                Text(
                  'Directorio de Kinesiólogos',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    letterSpacing: -0.1,
                  ),
                ),

                SizedBox(height: 4),

                // Subtítulo descriptivo
                Text(
                  'Encuentra profesionales disponibles para ti.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6D6D6D),
                    height: 1.2,
                  ),
                ),

                SizedBox(height: 4),

                // Barra decorativa naranja
                _OrangeBar(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Contenido dinámico: lista de kinesiólogos
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _kineListFuture,

              builder: (context, snapshot) {
                // 1. Cargando
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Error en la carga
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ocurrió un error al cargar: ${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                // 3. Lista vacía
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No hay kinesiólogos disponibles en este momento.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                // 4. Lista cargada correctamente
                final kineList = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: kineList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),

                  // Crea cada item del directorio
                  itemBuilder: (context, index) {
                    final kine = kineList[index];

                    // Información del kinesiólogo
                    final photoUrl = kine['photoUrl'] as String?;
                    final name = (kine['name'] ?? 'Kinesiólogo') as String;
                    final specialization =
                        (kine['specialization'] ?? 'Sin especialidad')
                            as String;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x0F000000)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x05000000),
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),

                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),

                        // Foto del kinesiólogo
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              (photoUrl != null && photoUrl.isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,

                          // Si no tiene foto, muestra un ícono por defecto
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),

                        // Nombre
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                            color: Colors.black,
                          ),
                        ),

                        // Especialidad
                        subtitle: Text(
                          specialization,
                          style: const TextStyle(
                            color: Color(0xFF6D6D6D),
                            fontSize: 12.5,
                          ),
                        ),

                        // Flecha visual de navegación
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.black45,
                        ),

                        // Acción al tocar el elemento
                        onTap: () => _navigateToKineScreen(kine),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Widget pequeño decorativo: barra naranja debajo del título
class _OrangeBar extends StatelessWidget {
  const _OrangeBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 3.5,
      decoration: BoxDecoration(
        color: const Color(0xFFE28825),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
