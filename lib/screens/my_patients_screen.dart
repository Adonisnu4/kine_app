// lib/screens/my_patients_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/services/user_service.dart'; // Asegúrate que aquí esté getKinePatients
import 'package:kine_app/screens/chat_screen.dart'; // Importa tu pantalla de chat
import 'package:kine_app/screens/patient_appointment_history_screen.dart'; // Importa pantalla historial
// --- Importa el servicio y la pantalla de pago ---
import 'package:kine_app/services/stripe_service.dart';
import 'package:kine_app/screens/subscription_screen.dart';

class MyPatientsScreen extends StatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  // --- Servicio y estados "Pro" ---
  final StripeService _stripeService = StripeService();
  late Future<List<Map<String, dynamic>>> _patientsFuture;
  bool _isPro = false; // Estado de suscripción
  bool _isLoadingProStatus = true; // Cargando estado
  // --- FIN ESTADOS ---

  // Límite de pacientes para el plan Básico/Gratuito
  final int _basicPatientLimit = 5;

  @override
  void initState() {
    super.initState();
    // Primero comprueba el estado de la suscripción
    _checkSubscriptionStatus();
  }

  // --- Función para comprobar la suscripción ---
  /// Comprueba el estado de la suscripción Pro.
  /// Una vez que tiene el estado, carga los pacientes.
  Future<void> _checkSubscriptionStatus() async {
    if (mounted)
      setState(() {
        _isLoadingProStatus = true;
      });
    bool isProStatus = false;
    try {
      isProStatus = await _stripeService.checkProSubscriptionStatus();
    } catch (e) {
      print("Error al comprobar estado Pro en Pacientes: $e");
      // Si falla, asume que no es Pro
      isProStatus = false;
    }

    if (mounted) {
      setState(() {
        _isPro = isProStatus;
        _isLoadingProStatus = false; // Termina la carga del status
        // Lanza la carga de pacientes AHORA que sabe el estado
        _patientsFuture = getKinePatients();
      });
    }
  }
  // --- FIN NUEVA FUNCIÓN ---

  // Refresca tanto el estado pro como la lista de pacientes
  void _refreshData() {
    setState(() {
      _isLoadingProStatus = true; // Muestra carga
    });
    // Vuelve a ejecutar la comprobación de estado, que a su vez recargará los pacientes
    _checkSubscriptionStatus();
  }

  // Navega al historial de citas
  void _navigateToHistory(String patientId, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientAppointmentHistoryScreen(
          patientId: patientId,
          patientName: patientName,
        ),
      ),
    );
  }

  // Navega al chat
  void _navigateToChat(String patientId, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(receiverId: patientId, receiverName: patientName),
      ),
    );
  }

  // Navega a la pantalla de suscripción
  void _navigateToSubscriptions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) =>
            const SubscriptionScreen(userType: "kine"), // Asume que es Kine
      ),
    );
    // Al volver, revisa el estado de nuevo
    _checkSubscriptionStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pacientes'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Botón para recargar
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar lista',
            onPressed: _refreshData, // Llama a la nueva función de recarga
          ),
        ],
      ),
      // --- Maneja el estado de carga "Pro" ---
      body: _isLoadingProStatus
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Muestra carga mientras comprueba el plan
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _patientsFuture, // Ahora espera a los pacientes
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error al cargar pacientes: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(25.0),
                      child: Text(
                        'Aún no tienes pacientes asignados.\nLos pacientes aparecerán aquí automáticamente después de que confirmes su primera cita.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  );
                }

                final allPatients = snapshot.data!;

                // --- LÓGICA DE BLOQUEO (GATING) ---
                List<Map<String, dynamic>> patientsToShow;
                bool limitReached = false;

                if (!_isPro && allPatients.length > _basicPatientLimit) {
                  // Si NO es Pro y superó el límite
                  patientsToShow = allPatients
                      .take(_basicPatientLimit)
                      .toList(); // Muestra solo los primeros 5
                  limitReached = true;
                } else {
                  // Si ES Pro, o si no ha superado el límite
                  patientsToShow = allPatients; // Muestra todos
                }
                // --- FIN LÓGICA DE BLOQUEO ---

                // Construye la UI con la lista (completa o limitada)
                return Column(
                  children: [
                    // Muestra un banner de "Actualizar" si se alcanzó el límite
                    if (limitReached)
                      _buildPaywallBanner(), // Widget del banner
                    // Muestra la lista de pacientes
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: patientsToShow.length,
                        itemBuilder: (context, index) {
                          final patientData = patientsToShow[index];
                          final patientId =
                              patientData['id'] as String? ?? 'ID_Desconocido';
                          final name =
                              patientData['nombre_completo'] as String? ??
                              'Nombre Desconocido';
                          final age = patientData['edad']?.toString() ?? '?';
                          final sex = patientData['sexo'] as String? ?? 'N/E';
                          final photoUrl =
                              patientData['imagen_perfil'] as String?;

                          // Tarjeta de Paciente (sin cambios)
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.teal.shade100,
                                backgroundImage:
                                    (photoUrl != null &&
                                        photoUrl.isNotEmpty &&
                                        Uri.tryParse(
                                              photoUrl,
                                            )?.hasAbsolutePath ==
                                            true)
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child:
                                    (photoUrl == null ||
                                        photoUrl.isEmpty ||
                                        Uri.tryParse(
                                              photoUrl,
                                            )?.hasAbsolutePath !=
                                            true)
                                    ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),
                              subtitle: Text('Edad: $age, Sexo: $sex'),
                              trailing: IconButton(
                                icon: Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.teal.shade600,
                                ),
                                tooltip: 'Enviar Mensaje a $name',
                                onPressed: () =>
                                    _navigateToChat(patientId, name),
                              ),
                              onTap: () => _navigateToHistory(patientId, name),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // --- WIDGET HELPER DEL BANNER ---
  /// Construye un banner que invita a actualizar al plan Pro
  Widget _buildPaywallBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0), // Margen
      decoration: BoxDecoration(
        color: Colors.orange.shade50, // Fondo naranja claro
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        children: [
          Text(
            'Límite del Plan Básico alcanzado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Estás viendo los primeros $_basicPatientLimit pacientes. Actualiza a Kine Pro para ver pacientes ilimitados.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            child: const Text('Actualizar a Kine Pro'),
            onPressed: () =>
                _navigateToSubscriptions(), // Llama a la pantalla de pago
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- FIN HELPER ---
}
