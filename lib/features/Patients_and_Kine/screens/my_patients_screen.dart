// lib/screens/my_patients_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/features/Chat/screens/chat_screen.dart';
import 'package:kine_app/features/Patients_and_Kine/screens/patient_appointment_history_screen.dart';
import 'package:kine_app/features/Stripe/services/stripe_service.dart';
import 'package:kine_app/features/Stripe/screens/subscription_screen.dart';
import 'package:kine_app/features/auth/services/user_service.dart';
import 'package:kine_app/features/Patients_and_Kine/screens/kine_patient_progress_screen.dart';

class MyPatientsScreen extends StatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  // Paleta
  static const _bg = Color(0xFFF3F3F3);
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

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
    setState(() => _isLoadingProStatus = true);

    Map<String, dynamic> planStatus;
    try {
      planStatus = await _stripeService.getUserPlanStatus();
    } catch (e) {
      planStatus = {'isPro': false, 'limit': 50};
    }

    if (!mounted) return;
    setState(() {
      _isPro = planStatus['isPro'] as bool;
      _patientLimit = planStatus['limit'] as int;
      _isLoadingProStatus = false;
      _patientsFuture = getKinePatients();
    });
  }

  void _refreshData() => _checkPlanAndLoadPatients();

  // Navegaciones
  void _navigateToHistory(String patientId, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAppointmentHistoryScreen(
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
        builder: (_) => ChatScreen(
          receiverId: patientId,
          receiverName: patientName,
        ),
      ),
    );
  }

  void _navigateToProgress(String patientId, String patientName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KinePatientProgressScreen(
          patientId: patientId,
          patientName: patientName,
        ),
      ),
    );
  }

  Future<void> _navigateToSubscriptions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SubscriptionScreen(userType: "kine"),
      ),
    );
    _checkPlanAndLoadPatients();
  }

  // ---------- Diálogo elegante tipo iOS (refinado) ----------
  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required String title,
    required String message,
    String confirmText = 'Aceptar',
    String cancelText = 'Cancelar',
    Color? accent,
  }) {
    final color = accent ?? _orange;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(.35),
      builder: (ctx) => Dialog(
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.1,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  // Cancelar con contorno y mismo color del texto
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        side: const BorderSide(color: _blue, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        cancelText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: .1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Confirmar sólido
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        confirmText,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          letterSpacing: .1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInfoDialog({
    required IconData icon,
    required String title,
    required String message,
    Color? accent,
  }) async {
    final color = accent ?? _blue;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    minimumSize: const Size(0, 42),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ---------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // 🔵 FAB circular de refresco
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.refresh_rounded),
      ),

      // ❌ Sin AppBar
      body: _isLoadingProStatus
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: _patientsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _blue),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
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

                return SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título interno
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Text(
                          'Listado de pacientes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111111),
                            letterSpacing: -.2,
                          ),
                        ),
                      ),
                      // barrita naranja
                      Container(
                        width: 48,
                        height: 3.5,
                        margin: const EdgeInsets.fromLTRB(16, 8, 0, 12),
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      if (limitReached) _buildPaywallBanner(),
                      Expanded(
                        child: RefreshIndicator(
                          color: _blue,
                          onRefresh: () async => _refreshData(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                            itemCount: patientsToShow.length,
                            itemBuilder: (context, index) {
                              final data = patientsToShow[index];
                              final id = data['id'] ?? 'ID_Desconocido';
                              final name =
                                  data['nombre_completo'] ?? 'Nombre desconocido';
                              final age = data['edad']?.toString() ?? '?';
                              final sex = data['sexo'] ?? 'N/E';
                              final photoUrl = data['imagen_perfil'];

                              return _patientCard(
                                id: id,
                                name: name,
                                age: age,
                                sex: sex,
                                photoUrl: photoUrl,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ---------- states ----------
  Widget _buildEmptyState() {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mis pacientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 3.5,
            margin: const EdgeInsets.fromLTRB(16, 8, 0, 12),
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(.12),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.groups_rounded, color: _blue, size: 28),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Aún no tienes pacientes asignados',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Los pacientes aparecerán aquí automáticamente después de que confirmes su primera cita.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _refreshData,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Recargar',
                        style: TextStyle(
                          color: _blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mis pacientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
            ),
          ),
          Container(
            width: 48,
            height: 3.5,
            margin: const EdgeInsets.fromLTRB(16, 8, 0, 12),
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.error_outline_rounded,
                          color: Colors.red.shade500, size: 28),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'No pudimos cargar tus pacientes',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.black54, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- widgets ----------
  Widget _patientCard({
    required String id,
    required String name,
    required String age,
    required String sex,
    required String? photoUrl,
  }) {
    final hasImage = photoUrl != null &&
        photoUrl.isNotEmpty &&
        Uri.tryParse(photoUrl)?.hasAbsolutePath == true &&
        !photoUrl.contains('via.placeholder.com');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: _blue.withOpacity(.12),
          backgroundImage: hasImage ? NetworkImage(photoUrl!) : null,
          child: !hasImage
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                )
              : null,
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15.5),
        ),
        subtitle: Text(
          'Edad: $age   •   Sexo: $sex',
          style: const TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Ver progreso',
              onPressed: () => _navigateToProgress(id, name),
              icon: const Icon(Icons.fitness_center_rounded, color: _blue),
            ),
            IconButton(
              tooltip: 'Historial de citas',
              onPressed: () => _navigateToHistory(id, name),
              icon: Icon(Icons.history_rounded, color: Colors.grey.shade700),
            ),
            IconButton(
              tooltip: 'Enviar mensaje',
              onPressed: () => _navigateToChat(id, name),
              icon:
                  const Icon(Icons.chat_bubble_outline_rounded, color: _orange),
            ),
          ],
        ),
        onTap: () async {
          final ok = await _showConfirmDialog(
            icon: Icons.person_rounded,
            title: name,
            message: '¿Qué deseas hacer?',
            confirmText: 'Abrir historial',
            accent: _blue,
          );
          if (ok == true) _navigateToHistory(id, name);
        },
      ),
    );
  }

  // Paywall / Límite de pacientes
  Widget _buildPaywallBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _orange.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _orange.withOpacity(.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: _orange.withOpacity(.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: _orange, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Límite del Plan Básico alcanzado',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Estás viendo los primeros $_patientLimit pacientes. Actualiza a Kine Pro para ver pacientes ilimitados.',
            style: const TextStyle(fontSize: 13.5, height: 1.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: _refreshData,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _orange.withOpacity(.6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  'Actualizar lista',
                  style:
                      TextStyle(color: _orange, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _navigateToSubscriptions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Pasar a Kine Pro'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
