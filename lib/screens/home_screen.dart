import 'package:flutter/material.dart';
import 'package:kine_app/services/get_user_data.dart';

import 'package:kine_app/screens/contacts_screen.dart';
import 'package:kine_app/screens/plan_ejercicios_screen.dart';
import 'package:kine_app/screens/index.dart';
import 'package:kine_app/screens/profile_screen.dart';
import 'package:kine_app/screens/kine_directory_screen.dart';

// Clave global (sin cambios)
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Navegación directa por índice (sin cambios)
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

  // Índices fijos (sin uso directo, los dejo por si los ocupas)
  static const int indexInicio = 0;
  static const int indexEjercicios = 1;
  static const int indexMensajes = 2;
  static const int indexPerfil = 3;
  static const int indexServiciosNormal = 2; // solo no verificado

  @override
  void initState() {
    super.initState();
    _loadUserStateAndSetupTabs();
  }

  Future<void> _loadUserStateAndSetupTabs() async {
    final userData = await getUserData();
    final userStatusId = userData?['tipo_usuario_id'] ?? 1;

    setState(() {
      _isKineVerified = (userStatusId == 3);
      _isLoading = false;

      final tabLength = _isKineVerified ? 4 : 5;
      _tabController = TabController(
        length: tabLength,
        vsync: this,
        initialIndex: 0, // <- corregido: usamos initialIndex (no initialPosition)
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Vistas (sin cambios lógicos)
  List<Widget> _getTabViews() {
    final List<Widget> views = [const Index(), const PlanEjercicioScreen()];

    if (!_isKineVerified) {
      // Index 2 para usuario normal (Servicios/Directorio)
      views.add(const KineDirectoryScreen());
    }

    views.addAll([const ContactsScreen(), const ProfileScreen()]);
    return views;
  }

  // Helper: icono de tamaño unificado para tabs
  Widget _navIcon(IconData data) => Icon(data, size: 22);

  // Tabs del footer (solo estética + mapping de “Servicios”)
  List<Tab> _getBottomNavBarTabs() {
    final List<Tab> base = [
      Tab(icon: _navIcon(Icons.home_rounded), text: 'Inicio'),
      // Ícono más representativo de ejercicios
      Tab(icon: _navIcon(Icons.fitness_center), text: 'Ejercicios'),
    ];

    if (_isKineVerified) {
      // 4 tabs: Inicio, Ejercicios, Mensajes, Servicios (reemplaza Perfil)
      return [
        ...base,
        Tab(icon: _navIcon(Icons.chat_bubble_outline_rounded), text: 'Mensajes'),
        Tab(icon: _navIcon(Icons.design_services_rounded),          text: 'Servicios'),
      ];
    } else {
      // 5 tabs: Servicios (índice 2), Mensajes, Perfil (se mantiene)
      return [
        ...base,
        Tab(icon: _navIcon(Icons.front_hand_rounded),          text: 'Servicios'),
        Tab(icon: _navIcon(Icons.chat_bubble_outline_rounded), text: 'Mensajes'),
        Tab(icon: _navIcon(Icons.person_rounded),              text: 'Perfil'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return DefaultTabController(
      length: _tabController.length,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(0.0),
          child: AppBar(automaticallyImplyLeading: false),
        ),

        // Contenido (sin scroll lateral)
        body: TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: _getTabViews(),
        ),

        // Footer con fondo negro + SOMBRA SUPERIOR para separar del contenido
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            boxShadow: [
              // Sombra hacia arriba (offset negativo en Y) para separar el footer
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, -4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            // Línea sutil por si el dispositivo no muestra bien la sombra
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
            // tipografías un poco más grandes
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: _getBottomNavBarTabs(),
          ),
        ),
      ),
    );
  }
}
