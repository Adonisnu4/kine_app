// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/features/Patients_and_Kine/screens/kine_directory_screen.dart';
import 'package:kine_app/features/auth/services/get_user_data.dart';
import 'package:kine_app/features/auth/screens/login_screen.dart';
import '../../Patients_and_Kine/models/edit_presentation_modal.dart';
import '../../Patients_and_Kine/models/edit_presentation_modal.dart'
    show PresentationData;
import 'package:kine_app/features/auth/services/user_service.dart';
import '../../Appointments/screens/my_appointments_screen.dart'; // Para Pacientes
import '../../Appointments/screens/manage_availability_screen.dart'; // Para Kinesiólogos
// --- Importaciones de Pago ---
import 'package:kine_app/features/Stripe/services/stripe_service.dart';
import 'package:kine_app/features/Stripe/screens/subscription_screen.dart';
// 💡 IMPORT AÑADIDO (Ajusta la ruta si es necesario)
import 'package:kine_app/shared/widgets/app_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _userDataFuture;
  Map<String, dynamic>? _currentUserData;

  // --- Estado "Pro" ---
  final StripeService _stripeService = StripeService();
  bool _isPro = false;
  bool _isLoadingProStatus = true;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
    _checkSubscriptionStatus();
  }

  // Carga los datos del usuario desde Firestore
  Future<Map<String, dynamic>?> _loadUserData() async {
    final data = await getUserData();
    if (mounted) {
      setState(() {
        _currentUserData = data;
      });
    }
    return data;
  }

  // Recarga el perfil
  void _refreshProfile() {
    setState(() {
      _userDataFuture = _loadUserData();
    });
    _checkSubscriptionStatus(); // Refresca también el estado "Pro"
  }

  /// ✅ Comprueba el estado de la suscripción Pro
  Future<void> _checkSubscriptionStatus() async {
    if (mounted) {
      setState(() {
        _isLoadingProStatus = true;
      });
    }
    try {
      final isPro = await _stripeService.checkProSubscriptionStatus();
      if (mounted) {
        setState(() {
          _isPro = isPro;
          _isLoadingProStatus = false;
          _userDataFuture =
              _loadUserData(); // 🔄 NUEVO: recarga los datos del usuario
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProStatus = false;
        });
      }
      print("Error al comprobar estado Pro: $e");
    }
  }

  /// Navega a la pantalla de suscripción
  void _navigateToSubscriptions(String userType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SubscriptionScreen(userType: userType),
      ),
    );
    // Al volver, revisa el estado de nuevo
    _checkSubscriptionStatus();
  }

  // --- Funciones de Navegación y Modales ---
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
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error al guardar presentación en Firestore: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar los datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  void _showActivationModal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mostrando modal de activación de cuenta... (Función no implementada)',
        ),
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
      builder: (ctx) => EditPresentationModal(
        initialData: initialData,
        onSave: _savePresentation,
      ),
    );
  }

  void _navigateToServices() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const KineDirectoryScreen()),
    );
  }

  void _navigateToMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const MyAppointmentsScreen()),
    );
  }

  void _navigateToManageAvailability() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const ManageAvailabilityScreen()),
    );
  }

  // --- Widgets Helpers ---
  Widget _buildStatItem(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
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
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoadingProStatus) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
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

          final userData = snapshot.data!;
          final userName = userData['nombre_completo'] ?? 'Usuario';
          final userEmail =
              FirebaseAuth.instance.currentUser?.email ?? 'No disponible';
          final userStatusName =
              userData['tipo_usuario_nombre'] ?? 'No especificado';
          final userStatusId = userData['tipo_usuario_id'] ?? 1;

          final isVerified = userStatusId == 3;
          final isPending = userStatusId == 2;
          final isNormal = userStatusId == 1;
          final userTypeString = isVerified ? "kine" : "patient";

          final String currentSpecialization = userData['specialization'] ?? '';
          final String currentExperience =
              userData['experience']?.toString() ?? '';
          final String currentPresentation =
              userData['carta_presentacion'] ?? '';
          final userImageUrl =
              userData['imagen_perfil'] ?? 'https://via.placeholder.com/120';

          // --- Construcción del ListView ---
          return RefreshIndicator(
            onRefresh: () async => _refreshProfile(),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 30),
                // --- Cabecera de Perfil ---
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
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

                // --- Stats ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Citas', '23'),
                      _buildStatItem('Seguidores', '1.2k'),
                      _buildStatItem('Siguiendo', '345'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // --- Botón "Pro" ---
                if (!_isPro)
                  _buildProfileMenuItem(
                    icon: Icons.star_purple500_outlined,
                    text: 'Actualizar a Plan Pro',
                    onTap: () => _navigateToSubscriptions(userTypeString),
                    textColor: Colors.blue.shade700,
                  ),
                if (_isPro)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 20),
                        Text(
                          'Plan Pro Activo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- Menú General ---
                _buildProfileMenuItem(
                  icon: Icons.person_outline,
                  text: 'Editar Perfil',
                  onTap: () {},
                ),

                // Opciones según tipo de usuario
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

                const Divider(height: 40, indent: 20, endIndent: 20),

                _buildProfileMenuItem(
                  icon: Icons.help_outline,
                  text: 'Ayuda y Soporte',
                  onTap: () {},
                ),

                // 💡 --- CÓDIGO MODIFICADO AQUÍ ---
                _buildProfileMenuItem(
                  icon: Icons.logout,
                  text: 'Cerrar Sesión',
                  textColor: Colors.red,
                  onTap: () async {
                    // 💡 Mostrar diálogo de confirmación
                    final bool? confirm = await showAppConfirmationDialog(
                      context: context,
                      icon: Icons.logout_rounded,
                      title: 'Cerrar Sesión',
                      content: '¿Estás seguro de que quieres cerrar tu sesión?',
                      confirmText: 'Sí, Salir',
                      cancelText: 'Cancelar',
                      isDestructive: true,
                    );

                    // Si el usuario confirma, proceder a cerrar sesión
                    if (confirm == true) {
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
                    }
                  },
                ),

                // 💡 --- FIN DE CÓDIGO MODIFICADO ---
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
