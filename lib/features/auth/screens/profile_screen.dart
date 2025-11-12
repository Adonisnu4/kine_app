// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kine_app/features/Patients_and_Kine/screens/kine_directory_screen.dart';
import 'package:kine_app/features/auth/services/get_user_data.dart';
import 'package:kine_app/features/auth/screens/login_screen.dart';
import 'package:kine_app/features/auth/services/user_service.dart';
import 'package:kine_app/features/Patients_and_Kine/models/edit_presentation_modal.dart';
import 'package:kine_app/features/auth/screens/kine_activation_screen.dart';
import 'package:kine_app/features/Stripe/services/stripe_service.dart';
import 'package:kine_app/features/Stripe/screens/subscription_screen.dart';
import 'package:kine_app/features/Appointments/screens/my_appointments_screen.dart';
import 'package:kine_app/features/Appointments/screens/manage_availability_screen.dart';
import 'package:kine_app/shared/widgets/app_dialog.dart';

class AppColors {
  static const blue = Color(0xFF47A5D6);
  static const orange = Color(0xFFE28825);
  static const grey = Color(0xFF7A8285);
  static const bg = Color(0xFFF3F3F3);
  static const white = Colors.white;
  static const text = Color(0xFF111111);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>?> _userDataFuture;
  Map<String, dynamic>? _currentUserData;

  final StripeService _stripeService = StripeService();
  bool _isPro = false;
  bool _isLoadingProStatus = true;

  final supabase = Supabase.instance.client;
  final firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
    _checkSubscriptionStatus();
  }

  Future<Map<String, dynamic>?> _loadUserData() async {
    final data = await getUserData();
    if (mounted) _currentUserData = data;
    return data;
  }

  void _refreshProfile() {
    setState(() {
      _userDataFuture = _loadUserData();
    });
    _checkSubscriptionStatus();
  }

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

  void _navigateToSubscriptions(String userType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SubscriptionScreen(userType: userType),
      ),
    );
    _checkSubscriptionStatus();
  }

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

  void _navigateToKineActivation() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const KineActivationScreen(),
      ),
    );
    _refreshProfile();
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

  void _navigateToMyAppointments() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
    );
  }

  void _navigateToManageAvailability() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ManageAvailabilityScreen()),
    );
  }

  // ---------- helpers de UI ----------
  Widget _statChip(String label, String value, {Color? valueColor}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: valueColor ?? AppColors.blue,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9AA0A5),
          ),
        ),
      ],
    );
  }

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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg ?? AppColors.blue.withOpacity(.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.text,
            size: 19,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoadingProStatus) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Error al cargar el perfil.'));
          }

          final userData = snapshot.data!;
          final userName = userData['nombre_completo'] ?? 'Usuario';
          final userEmail =
              FirebaseAuth.instance.currentUser?.email ?? 'Sin correo';
          final userStatusName =
              userData['tipo_usuario_nombre'] ?? 'normal';
          final userStatusId = userData['tipo_usuario_id'] ?? 1;

          final isKine = userStatusId == 3;
          final isPending = userStatusId == 2;
          final isNormal = userStatusId == 1;
          final userTypeString = isKine ? "kine" : "patient";

          final currentSpecialization = userData['specialization'] ?? '';
          final currentExperience = userData['experience']?.toString() ?? '';
          final currentPresentation =
              userData['carta_presentacion'] ?? '';
          final userImageUrl =
              userData['imagen_perfil'] ?? 'https://via.placeholder.com/120';

          return RefreshIndicator(
            onRefresh: () async => _refreshProfile(),
            child: CustomScrollView(
              slivers: [
                // header
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              )
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
                        // barra naranja
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 10, 0, 14),
                          width: 44,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        // card perfil
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
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 36,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: NetworkImage(userImageUrl),
                                  ),
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
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // card PRO
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
                        // título opciones
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
                // lista de opciones
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _menuCard(
                        icon: Icons.person_outline,
                        label: 'Editar perfil',
                        onTap: () {},
                      ),
                      if (isNormal)
                        _menuCard(
                          icon: Icons.calendar_month_outlined,
                          label: 'Mis citas solicitadas',
                          onTap: _navigateToMyAppointments,
                          iconBg: AppColors.orange.withOpacity(.12),
                          iconColor: AppColors.orange,
                        ),
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
                        else if (isPending)
                          _menuCard(
                            icon: Icons.access_time_filled_rounded,
                            label: 'Revisión en curso',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Tu solicitud está siendo revisada.'),
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
                      // cerrar sesión
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 28),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x0F000000)),
                        ),
                        child: ListTile(
                          onTap: () async {
                            final bool? confirm =
                                await showAppConfirmationDialog(
                              context: context,
                              icon: Icons.logout_rounded,
                              title: 'Cerrar sesión',
                              content:
                                  '¿Estás seguro de que quieres cerrar tu sesión?',
                              confirmText: 'Sí, salir',
                              cancelText: 'Cancelar',
                              isDestructive: true,
                            );
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
