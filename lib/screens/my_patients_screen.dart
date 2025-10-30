import 'package:flutter/material.dart';
import 'package:kine_app/services/user_service.dart';
import 'package:kine_app/screens/chat_screen.dart';
import 'package:kine_app/screens/patient_appointment_history_screen.dart';
import 'package:kine_app/services/stripe_service.dart';
import 'package:kine_app/screens/subscription_screen.dart';

class MyPatientsScreen extends StatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  final StripeService _stripeService = StripeService();
  late Future<List<Map<String, dynamic>>> _patientsFuture;

  bool _isPro = false;
  int _patientLimit = 50;
  bool _isLoadingProStatus = true;

  @override
  void initState() {
    super.initState();
    _checkPlanAndLoadPatients();
  }

  Future<void> _checkPlanAndLoadPatients() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProStatus = true;
    });

    Map<String, dynamic> planStatus;
    try {
      planStatus = await _stripeService.getUserPlanStatus();
    } catch (e) {
      print("Error al comprobar estado Pro: $e");
      planStatus = {'isPro': false, 'limit': 50};
    }

    if (mounted) {
      setState(() {
        _isPro = planStatus['isPro'] as bool;
        _patientLimit = planStatus['limit'] as int;
        _isLoadingProStatus = false;
        _patientsFuture = getKinePatients();
      });
    }
  }

  void _refreshData() {
    setState(() {
      _isLoadingProStatus = true;
    });
    _checkPlanAndLoadPatients();
  }

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

  void _navigateToChat(String patientId, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(receiverId: patientId, receiverName: patientName),
      ),
    );
  }

  void _navigateToSubscriptions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const SubscriptionScreen(userType: "kine"),
      ),
    );
    _checkPlanAndLoadPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pacientes'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar lista',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoadingProStatus
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _patientsFuture,
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
                List<Map<String, dynamic>> patientsToShow;
                bool limitReached = false;

                if (!_isPro && allPatients.length > _patientLimit) {
                  patientsToShow = allPatients.take(_patientLimit).toList();
                  limitReached = true;
                } else {
                  patientsToShow = allPatients;
                }

                return Column(
                  children: [
                    if (limitReached) _buildPaywallBanner(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        itemCount: patientsToShow.length,
                        itemBuilder: (context, index) {
                          final patientData = patientsToShow[index];
                          final patientId =
                              patientData['id'] ?? 'ID_Desconocido';
                          final name =
                              patientData['nombre_completo'] ??
                              'Nombre Desconocido';
                          final age = patientData['edad']?.toString() ?? '?';
                          final sex = patientData['sexo'] ?? 'N/E';
                          final photoUrl = patientData['imagen_perfil'];

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
                                            true &&
                                        !photoUrl.contains(
                                          'via.placeholder.com',
                                        ))
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child:
                                    (photoUrl == null ||
                                        photoUrl.isEmpty ||
                                        Uri.tryParse(
                                              photoUrl,
                                            )?.hasAbsolutePath !=
                                            true ||
                                        photoUrl.contains(
                                          'via.placeholder.com',
                                        ))
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

  Widget _buildPaywallBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
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
            'Estás viendo los primeros $_patientLimit pacientes. Actualiza a Kine Pro para ver pacientes ilimitados.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            child: const Text('Actualizar a Kine Pro'),
            onPressed: _navigateToSubscriptions,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
