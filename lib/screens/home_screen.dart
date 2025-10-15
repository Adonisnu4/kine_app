import 'package:flutter/material.dart';
import 'package:kine_app/services/get_user_data.dart';

import 'package:kine_app/screens/contacts_screen.dart';
import 'package:kine_app/screens/plan_ejercicios_screen.dart';
import 'package:kine_app/screens/index.dart';
import 'package:kine_app/screens/profile_screen.dart';
import 'package:kine_app/screens/kine_directory_screen.dart';

// Definimos una clave global para acceder al estado del HomeScreen desde cualquier lugar
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Método estático para que el ProfileScreen pueda navegar directamente
  static void navigateToTabIndex(BuildContext context, int index) {
    // Busca el TabController del HomeScreen y cambia el índice.
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

  // Definimos los índices fijos para el contenido base
  static const int indexInicio = 0;
  static const int indexEjercicios = 1;
  static const int indexMensajes = 2; // Índice en la lista del Kine
  static const int indexPerfil = 3; // Índice en la lista del Kine

  // El Directorio/Servicios estará en el índice 2 SOLO para usuarios normales.
  static const int indexServiciosNormal = 2;

  @override
  void initState() {
    super.initState();
    _loadUserStateAndSetupTabs();
  }

  Future<void> _loadUserStateAndSetupTabs() async {
    final userData = await getUserData();
    final userStatusId = userData?['tipo_usuario_id'] ?? 1;

    setState(() {
      _isKineVerified = userStatusId == 3;
      _isLoading = false;

      final tabLength = _isKineVerified ? 4 : 5;

      _tabController = TabController(
        length: tabLength,
        vsync: this,
        initialIndex: 0,
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Widget> _getTabViews() {
    final List<Widget> views = [const Index(), const PlanEjercicioScreen()];

    if (!_isKineVerified) {
      views.add(const KineDirectoryScreen()); // Index 2 para usuario normal
    }

    views.addAll([const ContactsScreen(), const ProfileScreen()]);

    return views;
  }

  List<Tab> _getBottomNavBarTabs() {
    final List<Tab> tabs = [
      const Tab(icon: Icon(Icons.home), text: 'Inicio'),
      const Tab(icon: Icon(Icons.search), text: 'Ejercicios'),
    ];

    if (!_isKineVerified) {
      tabs.add(const Tab(icon: Icon(Icons.badge), text: 'Servicios'));
    }

    tabs.addAll([
      const Tab(icon: Icon(Icons.chat_bubble), text: 'Mensajes'),
      const Tab(icon: Icon(Icons.person), text: 'Perfil'),
    ]);

    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Envolvemos el Scaffold con un DefaultTabController para hacerlo accesible
    // a los hijos como ProfileScreen. Usamos el TabController existente para su lógica.
    return DefaultTabController(
      length: _tabController.length,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0.0),
          child: AppBar(automaticallyImplyLeading: false),
        ),

        // Usamos el TabController instanciado en el estado
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: _getTabViews(),
        ),

        // Usamos el TabBar con el controller para la navegación
        bottomNavigationBar: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: Colors.purple,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.transparent,
          tabs: _getBottomNavBarTabs(),
        ),
      ),
    );
  }
}
