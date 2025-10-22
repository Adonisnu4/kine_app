// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/screens/kine_directory_screen.dart';
import 'package:kine_app/services/get_user_data.dart';
import 'package:kine_app/screens/login_screen.dart';
import '../models/edit_presentation_modal.dart';
import '../models/edit_presentation_modal.dart' show PresentationData;
import 'package:kine_app/services/user_service.dart';

// 👈 1. IMPORTAR la nueva pantalla de "Mis Citas"
import 'my_appointments_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _userDataFuture;
  Map<String, dynamic>? _currentUserData; // Estado local

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  // Carga los datos y actualiza el estado local
  Future<Map<String, dynamic>?> _loadUserData() async {
    final data = await getUserData();
    if (mounted) {
      setState(() {
        _currentUserData = data;
      });
    }
    return data;
  }

  void _refreshProfile() {
    setState(() {
      _userDataFuture = _loadUserData();
    });
  }

  // FUNCIÓN DE GUARDADO (NO CAMBIA)
  Future<void> _savePresentation(PresentationData data) async {
    try {
      await updateKinePresentation(
        specialization: data.specialization,
        experience: data.experience,
        presentation: data.presentation,
      );
      if (_currentUserData != null && mounted) {
        setState(() {
          _currentUserData!['specialization'] = data.specialization;
          _currentUserData!['experience'] = data.experience;
          _currentUserData!['carta_presentacion'] = data.presentation;
        });
      }
      _refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos profesionales guardados y publicados.'),
          ),
        );
      }
    } catch (e) {
      print("Error al guardar en Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar los datos: ${e.toString()}'),
          ),
        );
      }
      rethrow;
    }
  }

  // FUNCIONES EXISTENTES (NO CAMBIAN)
  void _showActivationModal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mostrando modal de activación de cuenta...'),
      ),
    );
  }

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
      builder: (BuildContext context) {
        return EditPresentationModal(
          initialData: initialData,
          onSave: _savePresentation,
        );
      },
    );
  }

  void _navigateToServices() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KineDirectoryScreen()),
    );
  }

  //
  // --- 👈 2. AÑADIR NUEVA FUNCIÓN DE NAVEGACIÓN ---
  //
  void _navigateToMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MyAppointmentsScreen()),
    );
  }
  // --- FIN DE NUEVA FUNCIÓN ---
  //

  // WIDGETS HELPERS (NO CAMBIAN)
  Widget _buildStatItem(String label, String value) {
    return Column(
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
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 28),
            const SizedBox(width: 20),
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

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
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Error al cargar el perfil. Por favor, reinicia la aplicación.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final userData = snapshot.data!;
          final userName = userData['nombre_completo'] ?? 'Usuario';
          final userEmail =
              FirebaseAuth.instance.currentUser?.email ?? 'No disponible';
          final userStatusName =
              userData['tipo_usuario_nombre'] ?? 'No especificado';
          final userStatusId = userData['tipo_usuario_id'] ?? 1;

          final isVerified = userStatusId == 3; // Kinesiólogo Verificado
          final isPending = userStatusId == 2; // Kine Pendiente
          final isNormal = userStatusId == 1; // Usuario Normal

          final String currentSpecialization = userData['specialization'] ?? '';
          final String currentExperience =
              userData['experience']?.toString() ?? '';
          final String currentPresentation =
              userData['carta_presentacion'] ?? '';
          final userImageUrl =
              userData['imagen_perfil'] ??
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=120&h=120&q=80';

          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 30),
              // --- Sección de Foto y Título (NO CAMBIA) ---
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: NetworkImage(userImageUrl),
                    ),
                    Positioned(
                      bottom: -10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? Colors.blue.shade600
                                : Colors.teal.shade400,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [/*...*/],
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
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
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
              // --- Sección de Estadísticas (NO CAMBIA) ---
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

              // --- Elementos de Menú: Comunes y Específicos ---
              _buildProfileMenuItem(
                icon: Icons.person_outline,
                text: 'Editar Perfil',
                onTap: () {},
              ),

              //
              // --- 👈 3. AÑADIR NUEVO ELEMENTO DE MENÚ AQUÍ ---
              //
              // Visible solo para Usuarios Normales (Pacientes)
              if (isNormal)
                _buildProfileMenuItem(
                  icon: Icons.calendar_month_outlined, // Ícono de calendario
                  text: 'Mis Citas Solicitadas',
                  onTap: _navigateToMyAppointments, // Llama a la nueva función
                ),
              // --- FIN DE NUEVO ELEMENTO ---
              //

              // Visible solo para Usuarios Normales
              if (isNormal)
                _buildProfileMenuItem(
                  icon: Icons.search_outlined,
                  text: 'Buscar Servicios de Kinesiólogos',
                  onTap: _navigateToServices,
                ),

              // Kinesiólogo Verificado puede editar sus datos
              if (isVerified)
                _buildProfileMenuItem(
                  icon: Icons.article_outlined,
                  text: 'Carta de presentacion y Especialidad',
                  onTap: () => _showEditPresentationModal(
                    specialization: currentSpecialization,
                    experience: currentExperience,
                    presentation: currentPresentation,
                  ),
                ),

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

              // --- Lógica de Activación de Cuenta (NO CAMBIA) ---
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
                      /*...*/
                    },
                    textColor: Colors.orange.shade800,
                  ),

              const Divider(height: 40, indent: 20, endIndent: 20),

              // --- Elementos de Menú: Soporte y Logout (NO CAMBIAN) ---
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
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
