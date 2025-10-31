// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kine_app/screens/Patients_and_Kine/screens/kine_panel_screen.dart';
import 'package:kine_app/screens/auth/services/get_user_data.dart';
import 'package:kine_app/screens/chat/screens/contacts_screen.dart'; // Asegúrate de tener una pantalla de login para el caso de no estar autenticado
import 'package:kine_app/screens/ejercicios/plan_ejercicios_screen.dart'; // Paciente ve esto
import 'package:kine_app/screens/index.dart';
import 'package:kine_app/screens/auth/screens/profile_screen.dart'; // Ambos
import 'package:kine_app/screens/Patients_and_Kine/screens/kine_directory_screen.dart'; // Paciente
import 'package:kine_app/screens/Patients_and_Kine/screens/my_patients_screen.dart'; // Kine (Lista Pacientes)

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
    // Kine now has 4 tabs (Inicio, Citas, Mensajes, Pacientes)
    // Patient has 4 tabs (Inicio, Ejercicios, Servicios, Mensajes)
    const tabLength = 4; // Ambos tienen 4 pestañas

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

  /// Returns the list of screen Widgets for the TabBarView based on user role.
  List<Widget> _getTabViews() {
    if (_isKineVerified) {
      // Screens for KINESIOLOGIST (4 tabs shown in footer)
      return const [
        Index(), // 0: Inicio
        KinePanelScreen(), // 1: Citas
        ContactsScreen(), // 2: Mensajes
        MyPatientsScreen(), // 3: Mis Pacientes,
      ];
    } else {
      // Screens for PATIENT (4 tabs shown in footer)
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
      // Tabs for KINESIOLOGIST (4 tabs)
      // --- 👇 CORREGIDO: AHORA SON 4 TABS 👇 ---
      return [
        Tab(icon: _navIcon(Icons.home_rounded), text: 'Inicio'),
        Tab(icon: _navIcon(Icons.assignment_rounded), text: 'Citas'),
        Tab(
          icon: _navIcon(Icons.chat_bubble_outline_rounded),
          text: 'Mensajes',
        ),
        Tab(
          icon: _navIcon(Icons.people_alt_rounded), // (Icono de pacientes)
          text: 'Pacientes',
        ),
      ];
      // --- FIN CORRECCIÓN ---
    } else {
      // Tabs for PATIENT (4 tabs)
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

  /// Returns the list of titles corresponding to each tab for the AppBar.
  List<String> _tabLabels() {
    if (_isKineVerified) {
      // Titles for KINESIOLOGIST
      // --- 👇 CORREGIDO: ORDEN SINCRONIZADO CON _getTabViews 👇 ---
      return [
        'Inicio', // 0: Index
        'Citas', // 1: KinePanelScreen
        'Mensajes', // 2: ContactsScreen
        'Mis Pacientes', // 3: MyPatientsScreen
      ];
      // --- FIN CORRECCIÓN ---
    } else {
      // Titles for PATIENT
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

    // Get the list of screens and tabs based on the determined role
    final views = _getTabViews();
    final tabs = _getBottomNavBarTabs();

    // Use DefaultTabController if navigating tabs programmatically elsewhere,
    // otherwise TabController managed by the state (_tabController) is sufficient.
    // Using DefaultTabController here for consistency with the static method.
    return DefaultTabController(
      length: _tabController.length, // Ensure length matches the controller
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle
            .dark, // Dark icons for the status bar (time, battery)
        child: Scaffold(
          appBar: _buildHeader(), // Use the custom header
          // Main content area displaying the selected tab's screen
          body: TabBarView(
            controller: _tabController, // Connect to the state's controller
            physics:
                const NeverScrollableScrollPhysics(), // Disable swiping between tabs
            children: views, // Use the correct list of screen widgets
          ),

          // Bottom navigation bar
          bottomNavigationBar: Container(
            // Styling for the bottom bar (black background, top shadow/border)
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
