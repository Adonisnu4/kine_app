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

// si ya tienes esta clase en otro lado, importa y borra esto
class AppColors {
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F5F5);

  static const blue = Color(0xFF47A5D6);     // del logo
  static const orange = Color(0xFFE28825);   // acento
  static const text = Color(0xFF101010);
  static const greyText = Color(0xFF6D6D6D);
  static const border = Color(0xFFE3E6E8);
}

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

  // ---------- datos de los tabs para el footer ----------
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

  // ---------- header PRO ----------
  PreferredSizeWidget _buildHeader() {
    final labels = _tabLabels();
    final title = _isLoading ? 'Cargando…' : labels[_tabController.index];

    return PreferredSize(
      preferredSize: const Size.fromHeight(62),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              offset: Offset(0, 1),
              blurRadius: 6,
            ),
          ],
          border: Border(
            bottom: BorderSide(color: Color(0x08000000), width: 1),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                // avatar botón
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _onProfileTap,
                  child: Container(
                    height: 34,
                    width: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2F4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: AppColors.blue,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // titulo + subtitulo
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        letterSpacing: -0.12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tu espacio de kinesiología',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.greyText,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
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
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
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
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                height: 54,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.blue.withOpacity(0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: selected ? 27 : 23,
                      color: selected ? AppColors.blue : AppColors.greyText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppColors.blue : AppColors.greyText,
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
          backgroundColor: AppColors.background,
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
