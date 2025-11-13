// lib/screens/patient_appointment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/models/appointment.dart';
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientAppointmentHistoryScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientAppointmentHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientAppointmentHistoryScreen> createState() =>
      _PatientAppointmentHistoryScreenState();
}

class _PatientAppointmentHistoryScreenState
    extends State<PatientAppointmentHistoryScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final String _currentKineId = FirebaseAuth.instance.currentUser!.uid;

  late Stream<List<Appointment>> _historyStream;

  // Paleta coherente
  static const _bg = Color(0xFFF6F7FB);
  static const _card = Colors.white;
  static const _text = Color(0xFF111111);
  static const _muted = Color(0xFF7A8285);
  static const _blue = Color(0xFF47A5D6);
  static const _teal = Color(0xFF00897B);
  static const _green = Color(0xFF2E7D32);
  static const _orange = Color(0xFFE28825);
  static const _red = Color(0xFFD32F2F);
  static const _blueGrey = Color(0xFF546E7A);

  @override
  void initState() {
    super.initState();
    _historyStream = _appointmentService.getAppointmentHistory(
      _currentKineId,
      widget.patientId,
    );
  }

  // ---------- Header (igual estilo que otras pantallas) ----------
  Widget _buildHeader() {
    return Column(
      children: [
        // Barra superior blanca con sombra leve
        SafeArea(
          bottom: false,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  offset: Offset(0, 1),
                  blurRadius: 6,
                )
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20,
                    color: _text,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Historial de ${widget.patientName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: _text,
                        ),
                      ),
                      const Text(
                        'Citas del paciente',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF9AA0A5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Barrita naranja
        Container(
          margin: const EdgeInsets.fromLTRB(16, 10, 0, 12),
          width: 44,
          height: 3,
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }

  // ---------- Estilos por estado ----------
  ({IconData icon, Color color, String label}) _statusStyle(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'confirmada') {
      return (icon: Icons.check_circle, color: _green, label: 'CONFIRMADA');
    }
    if (s == 'completada') {
      return (icon: Icons.task_alt_rounded, color: _blueGrey, label: 'COMPLETADA');
    }
    if (s == 'denegada' || s == 'rechazada' || s == 'cancelada') {
      return (
        icon: Icons.cancel_rounded,
        color: _red,
        label: (s == 'denegada') ? 'RECHAZADA' : s.toUpperCase()
      );
    }
    if (s == 'pendiente') {
      return (icon: Icons.hourglass_top_rounded, color: _orange, label: 'PENDIENTE');
    }
    return (icon: Icons.help_outline_rounded, color: Colors.grey, label: s.toUpperCase());
  }

  String _formatDate(DateTime dt) {
    final locale = 'es_ES';
    final day = DateFormat('EEEE d MMM yyyy', locale).format(dt);
    final hour = DateFormat('HH:mm', locale).format(dt);
    return '${_capitalize(day)} – $hour hrs';
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: _historyStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _errorState('Error al cargar historial: ${snapshot.error}');
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _emptyState();
                }

                final appointments = snapshot.data!;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: appointments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final ap = appointments[i];
                    final style = _statusStyle(ap.estado);

                    return Container(
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0x0F000000)),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar de estado
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: style.color.withOpacity(.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(style.icon, color: style.color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          // Texto + chip
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _formatDate(ap.fechaCitaDT),
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w600,
                                    color: _text,
                                    letterSpacing: -.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: style.color.withOpacity(.10),
                                        border: Border.all(
                                          color: style.color.withOpacity(.50),
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        style.label,
                                        style: TextStyle(
                                          color: style.color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          letterSpacing: .2,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- States vacíos / error con header ya puesto arriba ----------
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _teal.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_rounded, color: _teal, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Sin registros de citas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Cuando se agenden o completen citas, aparecerán aquí.',
              style: TextStyle(color: _muted, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _red.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, color: _red, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'No pudimos cargar el historial',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              msg,
              style: const TextStyle(color: _muted, height: 1.35),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
