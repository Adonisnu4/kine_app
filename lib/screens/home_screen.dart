// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/screens/kine_panel_screen.dart';
import 'package:kine_app/services/get_user_data.dart';
import 'package:kine_app/screens/contacts_screen.dart';
import 'package:kine_app/screens/ejercicios/plan_ejercicios_screen.dart'; // Paciente ve esto
import 'package:kine_app/screens/index.dart';
import 'package:kine_app/screens/profile_screen.dart'; // Ambos
import 'package:kine_app/screens/kine_directory_screen.dart'; // Paciente
import 'package:kine_app/screens/my_patients_screen.dart'; // Kine (Lista Pacientes)

// GlobalKey can remain if used elsewhere
final GlobalKey<_HomeScreenState> homeScreenKey = GlobalKey<_HomeScreenState>();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  // Static method to navigate tabs (optional, keep if used)
  static void navigateToTabIndex(BuildContext context, int index) {
    final TabController? controller = DefaultTabController.of(context);
    if (controller != null) {
      controller.animateTo(index);
    }
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// Uses SingleTickerProviderStateMixin for the TabController animation
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // TabController manages the state of the tabs
  late TabController _tabController;
  // Flags to track user role and loading state
  bool _isKineVerified = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Start loading user data and setting up tabs when the screen initializes
    _loadUserStateAndSetupTabs();
  }

  /// Fetches user data asynchronously and configures the TabController.
  Future<void> _loadUserStateAndSetupTabs() async {
    // Get user data (including role ID) from the service
    final userData = await getUserData();
    // Default to role 1 (Patient) if data is missing or incomplete
    final userStatusId = userData?['tipo_usuario_id'] ?? 1;

    // Determine if the user is a verified Kinesiologist (ID 3)
    _isKineVerified = (userStatusId == 3);

    // Set the number of tabs based on the user role
    // Kine now has 5 tabs (Inicio, Citas, Pacientes, Mensajes, Perfil accessed via Header)
    // Patient has 4 tabs (Inicio, Ejercicios, Servicios, Mensajes)
    final tabLength = _isKineVerified
        ? 4
        : 4; // Adjusted to 4 visible tabs for Kine footer

    _tabController =
        TabController(length: tabLength, vsync: this, initialIndex: 0)
          ..addListener(() {
            if (mounted)
              setState(() {}); // refrescar título del header al cambiar de tab
          });

    // Update the state to indicate loading is complete
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up the TabController when the screen is removed
    if (!_isLoading) {
      _tabController.dispose();
    }
    super.dispose();
  }

  /// Navigates to the ProfileScreen when the profile icon in the header is tapped.
  Future<void> _onProfileTap() async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  List<Widget> _getTabViews() {
    if (_isKineVerified) {
      //Pestañas para el kinesiologo
      return const [
        Index(), // 0: Inicio
        PlanEjercicioScreen(), // 1: Ejercicios
        KinePanelScreen(), // 2: Citas
        ContactsScreen(), // 3: Mensajes
      ];
    } else {
      //Pestañas para el usuario
      return const [
        Index(), // 0: Inicio
        PlanEjercicioScreen(), // 1: Ejercicios
        KineDirectoryScreen(), // 2: Servicios/Directorio
        ContactsScreen(), // 3: Mensajes
      ];
    }
  }

  /// Helper to create Tab icons with a consistent size.
  Widget _navIcon(IconData data) =>
      Icon(data, size: 24); // Slightly larger icon size

  /// Returns the list of Tab widgets for the BottomNavigationBar based on user role.
  List<Tab> _getBottomNavBarTabs() {
    if (_isKineVerified) {
      // Tabs para el kinesiologo
      return [
        Tab(icon: _navIcon(Icons.home_rounded), text: 'Inicio'),
        Tab(icon: _navIcon(Icons.fitness_center), text: 'Ejercicios'),
        Tab(icon: _navIcon(Icons.assignment_rounded), text: 'Citas'),
        Tab(
          icon: _navIcon(Icons.chat_bubble_outline_rounded),
          text: 'Mensajes',
        ),
      ];
    } else {
      // Tabs para el paciente
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

  List<String> _tabLabels() {
    //Para kine
    if (_isKineVerified) {
      return ['Inicio', 'Ejercicios', 'Citas', 'Mis Pacientes', 'Mensajes'];
    } else {
      //Para paciente
      return ['Inicio', 'Ejercicios', 'Servicios', 'Mensajes'];
    }
  }

  /// Builds the custom AppBar (Header).
  PreferredSizeWidget _buildHeader() {
    final labels = _tabLabels();
    // Get the title based on the current tab, show 'Cargando...' if not ready
    final title = _isLoading ? 'Cargando...' : labels[_tabController.index];

    // --- 👇 RESTORED PreferredSize CODE 👇 ---
    return PreferredSize(
      preferredSize: const Size.fromHeight(56), // Standard AppBar height
      child: Container(
        // Styling for the header (white background, shadow, bottom border)
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
            bottom: BorderSide(
              color: Color(0x14000000),
              width: 1,
            ), // línea finita
          ),
        ),
        child: SafeArea(
          // Ensures content is below status bar
          bottom: false, // No padding at the bottom
          child: SizedBox(
            height: 56, // Enforce height
            child: Row(
              // Layout: Icon - Title - Spacer
              children: [
                const SizedBox(width: 12),
                // Left Icon Button -> Navigates to Profile
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
                    fontWeight: FontWeight.w600, // Semi-bold
                  ),
                ),
                const Spacer(), // Pushes content to the left
                // Optional: Add icons on the right if needed
                const SizedBox(width: 12), // Right padding
              ],
            ),
          ),
        ),
      ),
    );
    // --- FIN RESTAURACIÓN ---
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator until user data and tabs are ready
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final views = _getTabViews();
    final tabs = _getBottomNavBarTabs();

    return DefaultTabController(
      length: _tabController.length,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          appBar: _buildHeader(),

          body: TabBarView(
            // controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: views,
          ),

          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.black, // Background color
              boxShadow: [
                // Shadow above the bar
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, -4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
              border: Border(
                top: BorderSide(color: Color(0x1FFFFFFF), width: 1),
              ), // Subtle top border
            ),
            child: TabBar(
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
