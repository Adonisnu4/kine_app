// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/screens/kine_directory_screen.dart';
import 'package:kine_app/services/get_user_data.dart';
import 'package:kine_app/screens/login_screen.dart';
import '../models/edit_presentation_modal.dart';
import '../models/edit_presentation_modal.dart' show PresentationData;
import 'package:kine_app/services/user_service.dart';

// --- Imports para las nuevas pantallas ---
import 'my_appointments_screen.dart'; // Para Pacientes
import 'manage_availability_screen.dart'; // Para Kinesiólogos
// --- FIN IMPORTS ---

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _userDataFuture;
  Map<String, dynamic>? _currentUserData; // Estado local para UI rápida

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData(); // Inicia la carga de datos
  }

  // Carga los datos del usuario desde Firestore
  Future<Map<String, dynamic>?> _loadUserData() async {
    final data = await getUserData();
    // Actualiza el estado local solo si el widget sigue "vivo"
    if (mounted) {
      setState(() {
        _currentUserData = data;
      });
    }
    return data;
  }

  // Vuelve a lanzar la carga de datos (usado después de guardar)
  void _refreshProfile() {
    setState(() {
      _userDataFuture = _loadUserData();
    });
  }

  // Guarda los datos de presentación editados por el Kine
  Future<void> _savePresentation(PresentationData data) async {
    try {
      await updateKinePresentation(
        specialization: data.specialization,
        experience: data.experience,
        presentation: data.presentation,
      );
      // Actualiza UI local inmediatamente
      if (_currentUserData != null && mounted) {
        setState(() {
          _currentUserData!['specialization'] = data.specialization;
          _currentUserData!['experience'] = data.experience;
          _currentUserData!['carta_presentacion'] = data.presentation;
        });
      }
      _refreshProfile(); // Recarga desde Firestore para confirmar
      // --- 👇 SNACKBAR RESTAURADO 👇 ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos profesionales guardados y publicados.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // --- FIN RESTAURACIÓN ---
    } catch (e) {
      print("Error al guardar presentación en Firestore: $e");
      // --- 👇 SNACKBAR RESTAURADO 👇 ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar los datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // --- FIN RESTAURACIÓN ---
      rethrow; // Permite que el modal sepa que hubo un error
    }
  }

  // Muestra modal de activación (placeholder)
  void _showActivationModal() {
    // --- 👇 SNACKBAR RESTAURADO 👇 ---
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mostrando modal de activación de cuenta... (Función no implementada)',
        ),
      ),
    );
    // --- FIN RESTAURACIÓN ---
  }

  // Muestra el modal para editar la presentación del Kine
  void _showEditPresentationModal({
    required String specialization,
    required String experience,
    required String presentation,
  }) {
    final initialData = (
      specialization: specialization,
      experience: experience,
      presentation: presentation,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => EditPresentationModal(
        initialData: initialData,
        onSave: _savePresentation,
      ),
    );
  }

  // Navega al directorio de Kines (para Paciente)
  void _navigateToServices() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const KineDirectoryScreen()),
    );
  }

  // Navega a "Mis Citas" (para Paciente)
  void _navigateToMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const MyAppointmentsScreen()),
    );
  }

  /// Navega a la pantalla donde el Kine gestiona su disponibilidad
  void _navigateToManageAvailability() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const ManageAvailabilityScreen()),
    );
  }

  // --- Widgets Helpers para construir la UI ---
  // Construye un item de estadística (Citas, Seguidores, etc.)
  Widget _buildStatItem(String label, String value) {
    // --- 👇 CÓDIGO RESTAURADO 👇 ---
    return Column(
      mainAxisSize: MainAxisSize.min, // Ocupa el mínimo espacio vertical
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
    // --- FIN RESTAURACIÓN ---
  }

  // Construye un elemento del menú del perfil (con icono, texto y flecha)
  Widget _buildProfileMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
  }) {
    // --- 👇 CÓDIGO RESTAURADO 👇 ---
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ), // Padding restaurado
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 28),
            const SizedBox(width: 20),
            Expanded(
              // Para que el texto no se desborde si es largo
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            // const Spacer(), // Ya no es necesario con Expanded
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
    // --- FIN RESTAURACIÓN ---
  }
  // --- Fin Widgets Helpers ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Perfil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 2,
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture, // Espera a que los datos del usuario carguen
        builder: (context, snapshot) {
          // --- Estados de Carga y Error ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            print(
              "Error en FutureBuilder de ProfileScreen: ${snapshot.error}",
            ); // Log de error
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Error al cargar el perfil. Por favor, reinicia la aplicación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // --- Estado Exitoso ---
          final userData = snapshot.data!; // Tenemos los datos
          // Extrae la información necesaria
          final userName = userData['nombre_completo'] ?? 'Usuario';
          final userEmail =
              FirebaseAuth.instance.currentUser?.email ?? 'No disponible';
          final userStatusName =
              userData['tipo_usuario_nombre'] ?? 'No especificado';
          final userStatusId =
              userData['tipo_usuario_id'] ??
              1; // Default a 1 (Paciente) si falta
          // Imprime para depurar
          print('--- DEBUG ProfileScreen Build ---');
          print('   Raw userData received: $userData');
          print('   Extracted userStatusId: $userStatusId');

          final isVerified = userStatusId == 3; // ¿Es Kine Verificado?
          final isPending = userStatusId == 2; // ¿Es Kine Pendiente?
          final isNormal = userStatusId == 1; // ¿Es Paciente?

          // Datos específicos del Kine
          final String currentSpecialization = userData['specialization'] ?? '';
          final String currentExperience =
              userData['experience']?.toString() ?? '';
          final String currentPresentation =
              userData['carta_presentacion'] ?? '';
          final userImageUrl =
              userData['imagen_perfil'] ??
              'https://via.placeholder.com/120'; // Placeholder

          // Construye la lista del perfil
          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 30),
              // --- Sección Superior: Foto, Nombre, Email, Rol ---
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors
                          .grey
                          .shade300, // Color de fondo si la imagen tarda
                      backgroundImage: NetworkImage(userImageUrl),
                    ),
                    Positioned(
                      bottom: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? Colors.blue.shade600
                              : (isPending
                                    ? Colors.orange.shade700
                                    : Colors.teal.shade400),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          userStatusName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25), // Más espacio después del badge
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (isVerified)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.verified,
                          color: Colors.blue.shade400,
                          size: 24,
                        ),
                      ),
                  ],
                ),
              ),
              Center(
                child: Text(
                  userEmail,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              // --- Sección de Estadísticas ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Citas', '23'), // Datos de ejemplo
                    _buildStatItem('Seguidores', '1.2k'),
                    _buildStatItem('Siguiendo', '345'),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // --- Elementos del Menú ---
              _buildProfileMenuItem(
                icon: Icons.person_outline,
                text: 'Editar Perfil',
                onTap: () {},
              ),

              // Opciones para Paciente (isNormal)
              if (isNormal)
                _buildProfileMenuItem(
                  icon: Icons.calendar_month_outlined,
                  text: 'Mis Citas Solicitadas',
                  onTap: _navigateToMyAppointments,
                ),
              if (isNormal)
                _buildProfileMenuItem(
                  icon: Icons.search_outlined,
                  text: 'Buscar Kinesiólogos',
                  onTap: _navigateToServices,
                ),

              // Opciones para Kine Verificado (isVerified)
              if (isVerified)
                _buildProfileMenuItem(
                  icon: Icons.schedule,
                  text: 'Gestionar Disponibilidad',
                  onTap: _navigateToManageAvailability,
                ),
              if (isVerified)
                _buildProfileMenuItem(
                  icon: Icons.article_outlined,
                  text: 'Carta de Presentación',
                  onTap: () => _showEditPresentationModal(
                    specialization: currentSpecialization,
                    experience: currentExperience,
                    presentation: currentPresentation,
                  ),
                ),

              // Opciones Comunes
              _buildProfileMenuItem(
                icon: Icons.settings_outlined,
                text: 'Configuración',
                onTap: () {},
              ),
              _buildProfileMenuItem(
                icon: Icons.notifications_outlined,
                text: 'Notificaciones',
                onTap: () {},
              ),

              // Lógica de Activación de Cuenta (si no está verificado)
              // --- 👇 CÓDIGO RESTAURADO 👇 ---
              if (!isVerified)
                if (isNormal)
                  _buildProfileMenuItem(
                    icon: Icons.school_outlined,
                    text: 'Activar cuenta de profesional',
                    onTap: _showActivationModal,
                  )
                else if (isPending)
                  _buildProfileMenuItem(
                    icon: Icons.access_time_filled,
                    text: 'Revisión en curso (Pendiente)',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Tu solicitud ya fue enviada y está siendo revisada.',
                          ),
                        ),
                      );
                    },
                    textColor: Colors.orange.shade800,
                  ),

              // --- FIN RESTAURACIÓN ---
              const Divider(height: 40, indent: 20, endIndent: 20),

              // Opciones Comunes: Ayuda y Cerrar Sesión
              _buildProfileMenuItem(
                icon: Icons.help_outline,
                text: 'Ayuda y Soporte',
                onTap: () {},
              ),
              _buildProfileMenuItem(
                icon: Icons.logout,
                text: 'Cerrar Sesión',
                textColor: Colors.red,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 20), // Espacio al final
            ],
          );
        },
      ),
    );
  }
}
