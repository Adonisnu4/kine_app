// lib/screens/kine_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:kine_app/features/Appointments/models/appointment.dart';
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
import 'package:kine_app/features/Chat/screens/chat_screen.dart';

class KinePanelScreen extends StatefulWidget {
  const KinePanelScreen({super.key});

  @override
  State<KinePanelScreen> createState() => _KinePanelScreenState();
}

class _KinePanelScreenState extends State<KinePanelScreen> {
  static const _bg = Color(0xFFF3F3F3);
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

  final AppointmentService _appointmentService = AppointmentService();
  final String _currentKineId = FirebaseAuth.instance.currentUser!.uid;

  late Stream<List<Appointment>> _appointmentsStream;
  List<Appointment> _allAppointments = [];

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _appointmentsStream = _appointmentService.getKineAppointments(
      _currentKineId,
    );
  }

  Future<void> _showInfoDialog({
    required IconData icon,
    required String title,
    required String message,
    Color? color,
  }) async {
    final accent = color ?? _blue;
    await showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: accent, size: 35),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13.5),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleUpdateStatus(
    Appointment appointment,
    String newStatus,
  ) async {
    try {
      await _appointmentService.updateAppointmentStatus(appointment, newStatus);

      await _showInfoDialog(
        icon: Icons.check_circle_outline_rounded,
        title: "Estado actualizado",
        message: "La cita fue marcada como $newStatus",
        color: _blue,
      );
    } catch (e) {
      await _showInfoDialog(
        icon: Icons.error_outline_rounded,
        title: "Error",
        message: "Error actualizando la cita.",
        color: Colors.red.shade600,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          _allAppointments = snapshot.data ?? [];

          return _buildCalendarAndList();
        },
      ),
    );
  }

  Widget _buildCalendarAndList() {
    final selectedDayAppointments = _allAppointments.where((appointment) {
      return isSameDay(appointment.fechaCitaDT, _selectedDay!);
    }).toList()..sort((a, b) => a.fechaCita.compareTo(b.fechaCita));

    return Column(
      children: [
        Container(
          width: 48,
          height: 3.5,
          margin: const EdgeInsets.fromLTRB(16, 10, 0, 12),
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              _calendar(),
              Expanded(child: _appointmentList(selectedDayAppointments)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _calendar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        locale: 'es_ES',
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) => setState(() {
          _calendarFormat = format;
        }),
        onPageChanged: (day) => _focusedDay = day,
      ),
    );
  }

  Widget _appointmentList(List<Appointment> list) {
    if (list.isEmpty) {
      return const Center(child: Text("No hay citas para este día."));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: list.map((e) => _appointmentCard(e)).toList(),
    );
  }

  Widget _appointmentCard(Appointment a) {
    final isPast = a.fechaCitaDT.isBefore(DateTime.now());

    // 🔥 AUTO-CANCELAR en Firebase
    if (a.estado == 'pendiente' && isPast) {
      _appointmentService.updateAppointmentStatus(a, 'cancelada');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _blue.withOpacity(.15),
              child: Text(DateFormat("HH:mm").format(a.fechaCitaDT)),
            ),
            title: Text(a.pacienteNombre),
            subtitle: Text(a.estado.toUpperCase()),
          ),

          // 🔥 Mostrar mensaje si ya pasó
          if (a.estado == 'pendiente' && isPast)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Cita expirada",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // 🔥 Mostrar botones SOLO si la cita NO ha pasado
          if (a.estado == 'pendiente' && !isPast)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _handleUpdateStatus(a, 'denegada'),
                  child: const Text("Denegar"),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _handleUpdateStatus(a, 'confirmada'),
                  child: const Text("Aceptar"),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
