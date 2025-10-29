import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/screens/kine_panel_screen.dart';
import 'package:kine_app/services/get_user_data.dart';
import 'package:kine_app/screens/contacts_screen.dart';
import 'package:kine_app/screens/ejercicios/plan_ejercicios_screen.dart'; // Paciente ve esto
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

    // Kine: 3 tabs visibles (sin Perfil en footer)
    // Paciente: 4 tabs visibles (sin Perfil en footer)
    final tabLength = _isKineVerified ? 3 : 4;

    _tabController =
        TabController(length: tabLength, vsync: this, initialIndex: 0)
          ..addListener(() {
            if (mounted)
              setState(() {}); // refrescar título del header al cambiar de tab
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

  /* ---------- Acción del botón de perfil (ícono IZQUIERDA del header) ---------- */
  Future<void> _onProfileTap() async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  // ---------- VISTAS ----------
  List<Widget> _getTabViews() {
    if (_isKineVerified) {
      // KINESIÓLOGO (3 tabs visibles)
      return const [
        Index(), // 0: Inicio
        KinePanelScreen(), // 1: Citas
        ContactsScreen(), // 2: Mensajes
        // Perfil se abre por header (push)
      ];
    } else {
      // PACIENTE (4 tabs visibles; Perfil se abre por otras rutas cuando corresponda)
      return const [
        Index(), // 0: Inicio
        PlanEjercicioScreen(), // 1: Ejercicios
        KineDirectoryScreen(), // 2: Servicios/Directorio
        ContactsScreen(), // 3: Mensajes
      ];
    }
  }

  // ---------- ICONO helper (tamaño unificado) ----------
  Widget _navIcon(IconData data) => Icon(data, size: 22);

  // ---------- TABS (footer) ----------
  List<Tab> _getBottomNavBarTabs() {
    if (_isKineVerified) {
      // Kine (sin Perfil en footer)
      return [
        Tab(icon: _navIcon(Icons.home_rounded), text: 'Inicio'),
        Tab(icon: _navIcon(Icons.assignment_rounded), text: 'Citas'),
        Tab(
          icon: _navIcon(Icons.chat_bubble_outline_rounded),
          text: 'Mensajes',
        ),
      ];
    } else {
      // Paciente (sin Perfil en footer)
      return [
        Tab(icon: _navIcon(Icons.home_rounded), text: 'Inicio'),
        Tab(icon: _navIcon(Icons.fitness_center), text: 'Ejercicios'),
        Tab(icon: _navIcon(Icons.medical_services_rounded), text: 'Servicios'),
        Tab(
          icon: _navIcon(Icons.chat_bubble_outline_rounded),
          text: 'Mensajes',
        ),
      ];
    }
  }

  // ---------- Labels para el título del header ----------
  List<String> _tabLabels() {
    if (_isKineVerified) {
      return ['Inicio', 'Citas', 'Mensajes'];
    } else {
      return ['Inicio', 'Ejercicios', 'Servicios', 'Mensajes'];
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
            bottom: BorderSide(
              color: Color(0x14000000),
              width: 1,
            ), // línea finita
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 12),
                // Ícono IZQUIERDA -> botón de PERFIL
                IconButton(
                  onPressed: _onProfileTap,
                  icon: const Icon(
                    Icons.person_outline,
                    color: Colors.black87,
                    size: 22,
                  ),
                  tooltip: 'Mi perfil',
                ),
                // Mover un poco más a la derecha el texto:
                const SizedBox(
                  width: 14,
                ), // antes 8 → ahora un poco más separado
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

    final views = _getTabViews();
    final tabs = _getBottomNavBarTabs();

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
            children: views.take(_tabController.length).toList(),
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
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              tabs: tabs,
            ),
          ),
        ),
      ),
    );
  }
}
