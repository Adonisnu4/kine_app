// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Imports de tu proyecto
import 'package:kine_app/features/auth/services/get_user_data.dart';
import 'package:kine_app/features/auth/screens/login_screen.dart';
import 'package:kine_app/features/auth/services/user_service.dart';
import 'package:kine_app/features/Patients_and_Kine/models/edit_presentation_modal.dart';
import 'package:kine_app/features/auth/screens/kine_activation_screen.dart';
import 'package:kine_app/features/Stripe/services/stripe_service.dart';
import 'package:kine_app/features/Stripe/screens/subscription_screen.dart';
import 'package:kine_app/features/Appointments/screens/my_appointments_screen.dart';
import 'package:kine_app/features/Appointments/screens/manage_availability_screen.dart';

//paleta de colores para el perfil
class AppColors {
  static const blue = Color(0xFF47A5D6);
  static const orange = Color(0xFFE28825);
  static const grey = Color(0xFF7A8285);
  static const bg = Color(0xFFF3F3F3);
  static const white = Colors.white;
  static const text = Color(0xFF111111);
}

//Pantalla de Perfil
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Future para cargar datos del usuario una vez al iniciar
  late Future<Map<String, dynamic>?> _userDataFuture;

  // Almacena temporalmente los datos del usuario
  Map<String, dynamic>? _currentUserData;

  // Servicio de Stripe para ver si el usuario es Pro
  final StripeService _stripeService = StripeService();

  bool _isPro = false; // Estado Pro del usuario
  bool _isLoadingProStatus = true; // Para mostrar loading mientras consulta

  // Clientes de Supabase y Firestore
  final supabase = Supabase.instance.client;
  final firestore = FirebaseFirestore.instance;

  //carga datos de usuario + estado de suscripción
  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData(); // Carga los datos del perfil
    _checkSubscriptionStatus(); // Consulta si el usuario es PRO
  }

  // Carga datos desde getUserData()
  Future<Map<String, dynamic>?> _loadUserData() async {
    final data = await getUserData();
    if (mounted) _currentUserData = data;
    return data;
  }

  // Refresca el perfil completo
  void _refreshProfile() {
    setState(() {
      _userDataFuture = _loadUserData(); // Recarga datos
    });
    _checkSubscriptionStatus(); // Revisa nuevamente PRO
  }

  // Consulta el estado de suscripción PRO del usuario
  Future<void> _checkSubscriptionStatus() async {
    if (mounted) setState(() => _isLoadingProStatus = true);
    try {
      final isPro = await _stripeService.checkProSubscriptionStatus();
      if (mounted) {
        setState(() {
          _isPro = isPro;
          _isLoadingProStatus = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProStatus = false);
    }
  }

  // Navega a la pantalla de suscripción PRO
  void _navigateToSubscriptions(String userType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SubscriptionScreen(userType: userType),
      ),
    );

    // Al volver, recarga estado PRO
    _checkSubscriptionStatus();
  }

  // Guarda una carta de presentación del kinesiólogo
  Future<void> _savePresentation(PresentationData data) async {
    try {
      await updateKinePresentation(
        specialization: data.specialization,
        experience: data.experience,
        presentation: data.presentation,
      );

      // Actualiza estado interno del usuario
      if (_currentUserData != null && mounted) {
        setState(() {
          _currentUserData!['specialization'] = data.specialization;
          _currentUserData!['experience'] = data.experience;
          _currentUserData!['carta_presentacion'] = data.presentation;
        });
      }

      _refreshProfile();

      // Mensaje éxito
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Datos profesionales guardados.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Navega a pantalla para activar cuenta profesional (kine)
  void _navigateToKineActivation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const KineActivationScreen()),
    );
    _refreshProfile();
  }

  // Muestra el modal para editar presentación
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

  // Navega a mis citas como paciente
  void _navigateToMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
    );
  }

  // Navega a la gestión de disponibilidad (si es KINE)
  void _navigateToManageAvailability() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageAvailabilityScreen()),
    );
  }

  // TARJETA DE OPCIONES
  Widget _menuCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconBg,
    Color? iconColor,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x0F000000)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg ?? AppColors.blue.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.text, size: 19),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor ?? AppColors.text,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black26,
        ),
      ),
    );
  }

  // POPUP de cierre de sesión
  Future<bool?> _showLogoutDialog() {
    final destructive = const Color(0xFFE11D48);
    final cancelColor = const Color(0xFF6B7280);

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono decorativo
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: destructive.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: destructive,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),

                // Título
                Text(
                  'Cerrar sesión',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.2,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtítulo
                const Text(
                  '¿Estás seguro de que quieres cerrar tu sesión?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    // Botón cancelar
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: cancelColor, width: 1.2),
                          foregroundColor: cancelColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Botón confirmar cerrar sesión
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: destructive,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(0, 44),
                        ),
                        child: const Text('Sí, salir'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Cuerpo principal del perfil
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          // Mientras carga datos o estado PRO
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoadingProStatus) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error cargando perfil
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Error al cargar el perfil.'));
          }

          // Datos del usuario
          final userData = snapshot.data!;
          final userName = userData['nombre_completo'] ?? 'Usuario';

          final userEmail =
              FirebaseAuth.instance.currentUser?.email ?? 'Sin correo';

          final userStatusName = userData['tipo_usuario_nombre'] ?? 'normal';
          final userStatusId = userData['tipo_usuario_id'] ?? 1;

          final isKine = userStatusId == 3; // Profesional aprobado
          final isPending = userStatusId == 2; // Profesional pendiente
          final isNormal = userStatusId == 1; // Usuario paciente
          final userTypeString = isKine ? "kine" : "patient";

          // Datos del kine (si aplica)
          final currentSpecialization = userData['specialization'] ?? '';
          final currentExperience = userData['experience']?.toString() ?? '';
          final currentPresentation = userData['carta_presentacion'] ?? '';

          final userImageUrl =
              userData['imagen_perfil'] ?? 'https://via.placeholder.com/120';

          // ENVOLTORIO SCROLL + REFRESH
          return RefreshIndicator(
            onRefresh: () async => _refreshProfile(),
            child: CustomScrollView(
              slivers: [
                // ENCABEZADO
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barra superior con botón de back
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x12000000),
                                offset: Offset(0, 1),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 20,
                                  color: AppColors.text,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Título
                              const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mi Perfil',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  Text(
                                    'Tu espacio de kinesiología',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF9AA0A5),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Línea naranja decorativa
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 10, 0, 14),
                          width: 44,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),

                        // TARJETA PRINCIPAL DEL PERFIL
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0x0F000000)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // FOTO + ETIQUETA DEL ROL
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: NetworkImage(userImageUrl),
                                  ),

                                  // Etiqueta del tipo de usuario (normal/kine/pending)
                                  Positioned(
                                    bottom: -12,
                                    left: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isKine
                                            ? AppColors.blue
                                            : (isPending
                                                  ? AppColors.orange
                                                  : AppColors.grey),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      child: Text(
                                        userStatusName.toLowerCase(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(width: 14),

                              // Nombre y correo del usuario
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            userName,
                                            style: const TextStyle(
                                              fontSize: 16.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.text,
                                            ),
                                          ),
                                        ),
                                        if (isKine)
                                          const Icon(
                                            Icons.verified_rounded,
                                            color: AppColors.blue,
                                            size: 20,
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 3),

                                    Text(
                                      userEmail,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF9AA0A5),
                                      ),
                                    ),

                                    const SizedBox(height: 10),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // TARJETA PLAN PRO (solo si NO es Pro)
                        if (!_isPro)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.blue.withOpacity(.35),
                              ),
                            ),
                            child: ListTile(
                              onTap: () =>
                                  _navigateToSubscriptions(userTypeString),
                              leading: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.blue.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.stars_rounded,
                                  color: AppColors.blue,
                                ),
                              ),
                              title: const Text(
                                'Actualizar a Plan Pro',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                              subtitle: const Text(
                                'Más visibilidad y mejores herramientas.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.black26,
                              ),
                            ),
                          ),

                        const SizedBox(height: 18),

                        // Título categorías de opciones
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Opciones',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.grey,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // LISTA DE OPCIONES DEL PERFIL
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _menuCard(
                        icon: Icons.person_outline,
                        label: 'Editar perfil',
                        onTap: () {},
                      ),

                      // Opción paciente
                      if (isNormal)
                        _menuCard(
                          icon: Icons.calendar_month_outlined,
                          label: 'Mis citas solicitadas',
                          onTap: _navigateToMyAppointments,
                          iconBg: AppColors.orange.withOpacity(.12),
                          iconColor: AppColors.orange,
                        ),

                      // Opción profesional
                      if (isKine)
                        _menuCard(
                          icon: Icons.schedule_rounded,
                          label: 'Gestionar disponibilidad',
                          onTap: _navigateToManageAvailability,
                          iconBg: AppColors.blue.withOpacity(.12),
                          iconColor: AppColors.blue,
                        ),

                      if (isKine)
                        _menuCard(
                          icon: Icons.article_outlined,
                          label: 'Carta de presentación',
                          onTap: () => _showEditPresentationModal(
                            specialization: currentSpecialization,
                            experience: currentExperience,
                            presentation: currentPresentation,
                          ),
                          iconBg: AppColors.grey.withOpacity(.15),
                          iconColor: AppColors.text,
                        ),

                      _menuCard(
                        icon: Icons.settings_outlined,
                        label: 'Configuración',
                        onTap: () {},
                        iconBg: AppColors.grey.withOpacity(.12),
                        iconColor: AppColors.grey,
                      ),

                      _menuCard(
                        icon: Icons.notifications_outlined,
                        label: 'Notificaciones',
                        onTap: () {},
                        iconBg: AppColors.blue.withOpacity(.12),
                        iconColor: AppColors.blue,
                      ),

                      // Activar cuenta profesional
                      if (!isKine)
                        if (isNormal)
                          _menuCard(
                            icon: Icons.school_outlined,
                            label: 'Activar cuenta de profesional',
                            onTap: _navigateToKineActivation,
                            iconBg: AppColors.orange.withOpacity(.14),
                            iconColor: AppColors.orange,
                            textColor: AppColors.text,
                          )
                        // Estado pendiente
                        else if (isPending)
                          _menuCard(
                            icon: Icons.access_time_filled_rounded,
                            label: 'Revisión en curso',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tu solicitud está siendo revisada.',
                                  ),
                                ),
                              );
                            },
                            iconBg: AppColors.orange.withOpacity(.14),
                            iconColor: AppColors.orange,
                            textColor: AppColors.orange,
                          ),

                      _menuCard(
                        icon: Icons.help_outline,
                        label: 'Ayuda y soporte',
                        onTap: () {},
                        iconBg: AppColors.blue.withOpacity(.08),
                        iconColor: AppColors.blue,
                      ),

                      // CERRAR SESIÓN
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 28),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x0F000000)),
                        ),
                        child: ListTile(
                          onTap: () async {
                            // Muestra popup
                            final bool? confirm = await _showLogoutDialog();

                            // Si confirma, cerrar sesión
                            if (confirm == true) {
                              await FirebaseAuth.instance.signOut();

                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (route) => false,
                                );
                              }
                            }
                          },
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                          title: const Text(
                            'Cerrar sesión',
                            style: TextStyle(
                              color: Color(0xFFE11D48),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.black26,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
