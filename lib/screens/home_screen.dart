import 'package:flutter/material.dart';
import 'package:kine_app/screens/kine_panel_screen.dart';
import 'package:kine_app/services/get_user_data.dart';
import 'package:kine_app/screens/contacts_screen.dart';
import 'package:kine_app/screens/plan_ejercicios_screen.dart'; // Paciente ve esto
import 'package:kine_app/screens/index.dart';
import 'package:kine_app/screens/profile_screen.dart'; // Ambos ven esto
import 'package:kine_app/screens/kine_directory_screen.dart'; // Paciente ve esto
import 'package:kine_app/screens/kine_panel_screen.dart'; // Kine ve esto

final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static void navigateToTabIndex(BuildContext context, int index) {
    final TabController? controller = DefaultTabController.of(context);
    if (controller != null) {
      controller.animateTo(index);
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isKineVerified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStateAndSetupTabs();
  }

  Future<void> _loadUserStateAndSetupTabs() async {
    final userData = await getUserData();
    final userStatusId = userData?['tipo_usuario_id'] ?? 1;

    // Ya no necesitamos _isLoading aquí si el builder lo maneja
    _isKineVerified = userStatusId == 3;
    final tabLength = _isKineVerified ? 4 : 5; // Kine: 4 tabs, Paciente: 5 tabs

    _tabController = TabController(
      length: tabLength,
      vsync: this,
      initialIndex: 0,
    );
    // Forzamos rebuild ahora que tenemos el controller
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Solo disponer si fue inicializado
    if (!_isLoading) {
      _tabController.dispose();
    }
    super.dispose();
  }

  // 🔥 FUNCIÓN _getTabViews() MODIFICADA
  List<Widget> _getTabViews() {
    if (_isKineVerified) {
      // Vistas para KINESIÓLOGO (tipo_usuario/3)
      // La segunda pestaña es el Panel de Citas
      return [
        const Index(), // Tab 0
        const KinePanelScreen(), // Tab 1:  Panel de Citas
        const ContactsScreen(), // Tab 2: Mensajes
        const ProfileScreen(), // Tab 3: Perfil (el tuyo)
      ];
    } else {
      // Vistas para PACIENTE (tipo_usuario/1)
      return [
        const Index(), // Tab 0
        const PlanEjercicioScreen(), // Tab 1: Ejercicios
        const KineDirectoryScreen(), // Tab 2: Servicios/Directorio
        const ContactsScreen(), // Tab 3: Mensajes
        const ProfileScreen(), // Tab 4: Perfil (el tuyo)
      ];
    }
  }

  // 🔥 FUNCIÓN _getBottomNavBarTabs() MODIFICADA
  List<Tab> _getBottomNavBarTabs() {
    if (_isKineVerified) {
      // Pestañas para KINESIÓLOGO
      return [
        const Tab(icon: Icon(Icons.home), text: 'Inicio'),
        const Tab(
          icon: Icon(Icons.assignment),
          text: 'Citas',
        ), // 🔥 Texto cambiado
        const Tab(icon: Icon(Icons.chat_bubble), text: 'Mensajes'),
        const Tab(icon: Icon(Icons.person), text: 'Perfil'),
      ];
    } else {
      // Pestañas para PACIENTE
      return [
        const Tab(icon: Icon(Icons.home), text: 'Inicio'),
        const Tab(icon: Icon(Icons.search), text: 'Ejercicios'),
        const Tab(icon: Icon(Icons.badge), text: 'Servicios'),
        const Tab(icon: Icon(Icons.chat_bubble), text: 'Mensajes'),
        const Tab(icon: Icon(Icons.person), text: 'Perfil'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Muestra carga hasta que sepamos el rol y tengamos el TabController
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: _tabController.length,
      child: Scaffold(
        // Sin AppBar global aquí
        body: TabBarView(
          controller: _tabController,
          physics:
              const NeverScrollableScrollPhysics(), // Evita deslizar entre tabs
          children: _getTabViews(), // 🔥 Usa las vistas correctas según el rol
        ),
        bottomNavigationBar: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: Colors.purple, // Tu color
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.transparent,
          tabs:
              _getBottomNavBarTabs(), // 🔥 Usa las pestañas correctas según el rol
        ),
      ),
    );
  }
}
