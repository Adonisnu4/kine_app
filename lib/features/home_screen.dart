// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/features/Patients_and_Kine/screens/kine_panel_screen.dart';
import 'package:kine_app/features/auth/services/get_user_data.dart';
import 'package:kine_app/features/chat/screens/contacts_screen.dart';
import 'package:kine_app/features/ejercicios/screens/plan_ejercicios_screen.dart';
import 'package:kine_app/features/index.dart';
import 'package:kine_app/features/auth/screens/profile_screen.dart';
import 'package:kine_app/features/Patients_and_Kine/screens/kine_directory_screen.dart';
import 'package:kine_app/features/Patients_and_Kine/screens/my_patients_screen.dart';

final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static void navigateToTabIndex(BuildContext context, int index) {
    final TabController controller = DefaultTabController.of(context);
    controller.animateTo(index);
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

    _isKineVerified = (userStatusId == 3);
    final tabLength = _isKineVerified ? 5 : 4;

    _tabController =
        TabController(length: tabLength, vsync: this, initialIndex: 0)
          ..addListener(() {
            if (mounted) setState(() {});
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

  Future<void> _onProfileTap() async {
    if (!mounted) return;
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  // ---------- vistas ----------
  List<Widget> _getTabViews() {
    if (_isKineVerified) {
      return const [
        Index(),
        PlanEjercicioScreen(),
        KinePanelScreen(),
        ContactsScreen(),
        MyPatientsScreen(),
      ];
    } else {
      return const [
        Index(),
        PlanEjercicioScreen(),
        KineDirectoryScreen(),
        ContactsScreen(),
      ];
    }
  }

  // ---------- datos de los tabs para el footer custom ----------
  List<_BottomItem> _bottomItems() {
    if (_isKineVerified) {
      return const [
        _BottomItem(Icons.home_rounded, 'Inicio'),
        _BottomItem(Icons.self_improvement_rounded, 'Ejercicios'),
        _BottomItem(Icons.event_available_rounded, 'Citas'),
        _BottomItem(Icons.forum_rounded, 'Mensajes'),
        _BottomItem(Icons.groups_rounded, 'Pacientes'),
      ];
    } else {
      return const [
        _BottomItem(Icons.home_rounded, 'Inicio'),
        _BottomItem(Icons.self_improvement_rounded, 'Ejercicios'),
        _BottomItem(Icons.health_and_safety_rounded, 'Servicios'),
        _BottomItem(Icons.forum_rounded, 'Mensajes'),
      ];
    }
  }

  // ---------- labels para el header ----------
  List<String> _tabLabels() {
    if (_isKineVerified) {
      return [
        'Inicio',
        'Ejercicios',
        'Citas',
        'Mensajes',
        'Mis Pacientes',
      ];
    } else {
      return ['Inicio', 'Ejercicios', 'Servicios', 'Mensajes'];
    }
  }

  // ---------- header ----------
  PreferredSizeWidget _buildHeader() {
    final labels = _tabLabels();
    final title = _isLoading ? 'Cargando...' : labels[_tabController.index];

    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 1),
              blurRadius: 6,
            ),
          ],
          border: Border(
            bottom: BorderSide(color: Color(0x14000000), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _onProfileTap,
                  icon: const Icon(
                    Icons.person_outline,
                    color: Colors.black87,
                    size: 22,
                  ),
                  tooltip: 'Mi perfil',
                ),
                const SizedBox(width: 14),
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

  // ---------- footer custom ----------
  Widget _buildBottomBar() {
    final items = _bottomItems();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),  // <- puntas redondeadas arriba
          topRight: Radius.circular(20),
        ),
        boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              offset: Offset(0, -2),
              blurRadius: 10,
            ),
          ],
      ),
      height: 58,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (index) {
          final selected = _tabController.index == index;
          final item = items[index];
          return Expanded(
            child: InkWell(
              onTap: () => _tabController.animateTo(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: selected ? 56 : 50,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  // ahora el seleccionado es negro MUY suave
                  color: selected ? Colors.black.withOpacity(0.06) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: selected ? 27 : 23,
                      color: selected ? Colors.black : const Color(0xFF6B7280),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: selected ? 12 : 11,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? Colors.black : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final views = _getTabViews();

    return DefaultTabController(
      length: _tabController.length,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          appBar: _buildHeader(),
          body: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: views,
          ),
          bottomNavigationBar: _buildBottomBar(),
        ),
      ),
    );
  }
}

// modelo para el footer
class _BottomItem {
  final IconData icon;
  final String label;
  const _BottomItem(this.icon, this.label);
}
