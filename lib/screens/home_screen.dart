import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/screens/kine_panel_screen.dart';
import 'package:kine_app/services/get_user_data.dart';
import 'package:kine_app/screens/contacts_screen.dart';
import 'package:kine_app/screens/plan_ejercicios_screen.dart'; // Paciente
import 'package:kine_app/screens/index.dart';
import 'package:kine_app/screens/profile_screen.dart'; // Ambos
import 'package:kine_app/screens/kine_directory_screen.dart'; // Paciente

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

    _isKineVerified = userStatusId == 3;
    final tabLength = _isKineVerified ? 4 : 5; // Kine: 4 tabs, Paciente: 5 tabs

    _tabController = TabController(
      length: tabLength,
      vsync: this,
      initialIndex: 0,
    )..addListener(() {
        if (mounted) setState(() {}); // refrescar título del header al cambiar de tab
      });

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (!_isLoading) {
      _tabController.dispose();
    }
    super.dispose();
  }

  // ---------- VISTAS (sin cambios funcionales) ----------
  List<Widget> _getTabViews() {
    if (_isKineVerified) {
      // KINESIÓLOGO
      return [
        const Index(),             // 0: Inicio
        const KinePanelScreen(),   // 1: Citas
        const ContactsScreen(),    // 2: Mensajes
        const ProfileScreen(),     // 3: Perfil
      ];
    } else {
      // PACIENTE
      return [
        const Index(),                // 0: Inicio
        const PlanEjercicioScreen(),  // 1: Ejercicios
        const KineDirectoryScreen(),  // 2: Servicios/Directorio
        const ContactsScreen(),       // 3: Mensajes
        const ProfileScreen(),        // 4: Perfil
      ];
    }
  }

  // ---------- ICONO helper (tamaño unificado) ----------
  Widget _navIcon(IconData data) => Icon(data, size: 22);

  // ---------- TABS (solo estética) ----------
  List<Tab> _getBottomNavBarTabs() {
    if (_isKineVerified) {
      // Kine
      return [
        Tab(icon: _navIcon(Icons.home_rounded), text: 'Inicio'),
        Tab(icon: _navIcon(Icons.assignment_rounded), text: 'Citas'),
        Tab(icon: _navIcon(Icons.chat_bubble_outline_rounded), text: 'Mensajes'),
        Tab(icon: _navIcon(Icons.person_rounded), text: 'Perfil'),
      ];
    } else {
      // Paciente
      return [
        Tab(icon: _navIcon(Icons.home_rounded), text: 'Inicio'),
        Tab(icon: _navIcon(Icons.fitness_center), text: 'Ejercicios'),
        Tab(icon: _navIcon(Icons.medical_services_rounded), text: 'Servicios'),
        Tab(icon: _navIcon(Icons.chat_bubble_outline_rounded), text: 'Mensajes'),
        Tab(icon: _navIcon(Icons.person_rounded), text: 'Perfil'),
      ];
    }
  }

  // ---------- Labels para el título del header ----------
  List<String> _tabLabels() {
    if (_isKineVerified) {
      return ['Inicio', 'Citas', 'Mensajes', 'Perfil'];
    } else {
      return ['Inicio', 'Ejercicios', 'Servicios', 'Mensajes', 'Perfil'];
    }
  }

  // ---------- Header blanco estilo mockup ----------
  PreferredSizeWidget _buildHeader() {
    final labels = _tabLabels();
    final title = labels[_tabController.index];

    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // sombra sutil
              offset: Offset(0, 1),
              blurRadius: 6,
            ),
          ],
          border: Border(
            bottom: BorderSide(color: Color(0x14000000), width: 1), // línea finita
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.person_outline, color: Colors.black87, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: _tabController.length,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark, // status bar con iconos oscuros
        child: Scaffold(
          // Header agregado (estético)
          appBar: _buildHeader(),

          // Contenido sin swipe lateral
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: _getTabViews(),
          ),

          // Footer negro con sombra superior y labels más legibles
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, -4), // sombra hacia arriba
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
              border: Border(
                top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.transparent,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              tabs: _getBottomNavBarTabs(),
            ),
          ),
        ),
      ),
    );
  }
}
