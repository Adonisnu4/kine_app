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
  // paleta centralizada
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

  // ---------- helpers de diálogos elegantes ----------
  Future<bool?> _showConfirmDialog({
    required IconData icon,
    required String title,
    required String message,
    bool destructive = false,
    String confirmText = 'Aceptar',
    String cancelText = 'Cancelar',
    Color? accentColor,
  }) {
    final color = accentColor ?? (destructive ? Colors.red : _orange);
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
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
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                          minimumSize: const Size(0, 42),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
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
                    color: accent.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 22),
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
                      backgroundColor: accent,
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
        );
      },
    );
  }
  // ---------------------------------------------------

  List<Appointment> _getEventsForDay(DateTime day) {
    return _allAppointments.where((appointment) {
      if (appointment.estado == 'confirmada' ||
          appointment.estado == 'pendiente') {
        return isSameDay(appointment.fechaCitaDT, day);
      }
      return false;
    }).toList();
  }

  Future<void> _handleUpdateStatus(
    Appointment appointment,
    String newStatus,
  ) async {
    // confirmaciones con estilo
    if (newStatus == 'confirmada') {
      final ok = await _showConfirmDialog(
        icon: Icons.check_circle_outline_rounded,
        title: 'Confirmar cita',
        message:
            '¿Confirmas la cita con ${appointment.pacienteNombre} a las ${DateFormat('HH:mm').format(appointment.fechaCitaDT)}?',
        confirmText: 'Confirmar',
      );
      if (ok != true) return;
    }

    if (newStatus == 'denegada') {
      final ok = await _showConfirmDialog(
        icon: Icons.block_rounded,
        title: 'Rechazar cita',
        message:
            '¿Seguro que quieres rechazar la solicitud de ${appointment.pacienteNombre}?',
        confirmText: 'Rechazar',
        destructive: true,
        accentColor: Colors.red.shade500,
      );
      if (ok != true) return;
    }

    if (newStatus == 'cancelada') {
      final ok = await _showConfirmDialog(
        icon: Icons.warning_amber_rounded,
        title: 'Cancelar cita',
        message:
            'Esto notificará al paciente. ¿Deseas cancelar la cita confirmada?',
        confirmText: 'Cancelar cita',
        destructive: true,
        accentColor: Colors.red.shade500,
      );
      if (ok != true) return;
    }

    // actualizar
    try {
      await _appointmentService.updateAppointmentStatus(appointment, newStatus);

      if (!mounted) return;

      if (newStatus == 'confirmada') {
        await _showInfoDialog(
          icon: Icons.check_circle_outline_rounded,
          title: '¡Cita confirmada!',
          message: 'El paciente será notificado.',
          color: _blue,
        );
      } else if (newStatus == 'denegada') {
        await _showInfoDialog(
          icon: Icons.block_rounded,
          title: 'Cita rechazada',
          message: 'La solicitud ha sido rechazada.',
          color: Colors.red.shade500,
        );
      } else if (newStatus == 'cancelada') {
        await _showInfoDialog(
          icon: Icons.cancel_outlined,
          title: 'Cita cancelada',
          message: 'La cita ha sido cancelada y el paciente fue informado.',
          color: Colors.red.shade500,
        );
      }
    } catch (e) {
      if (!mounted) return;
      await _showInfoDialog(
        icon: Icons.error_outline_rounded,
        title: 'Error',
        message: 'No se pudo actualizar la cita: $e',
        color: Colors.red.shade500,
      );
    }
  }

  void _showPatientDetailsModal(BuildContext context, Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            top: 18,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _blue.withOpacity(.15),
                    child: Text(
                      appointment.pacienteNombre.isNotEmpty
                          ? appointment.pacienteNombre[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      appointment.pacienteNombre,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    Icon(Icons.email_outlined, color: Colors.grey.shade600),
                title: Text(appointment.pacienteEmail ?? 'No disponible'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.calendar_today_outlined,
                    color: Colors.grey.shade600),
                title: Text(
                  DateFormat('EEE d MMMM, HH:mm', 'es_ES')
                      .format(appointment.fechaCitaDT),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline, color: Colors.grey.shade600),
                title: Text('Estado: ${appointment.estado.toUpperCase()}'),
              ),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        receiverId: appointment.pacienteId,
                        receiverName: appointment.pacienteNombre,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Enviar mensaje'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Panel de citas',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          _allAppointments = snapshot.data ?? [];
          return _buildCalendarAndList();
        },
      ),
    );
  }

  Widget _buildCalendarAndList() {
    final selectedDayAppointments = _allAppointments.where((appointment) {
      final citaDate = appointment.fechaCitaDT;
      return isSameDay(citaDate, _selectedDay!);
    }).toList()
      ..sort((a, b) => a.fechaCita.compareTo(b.fechaCita));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // barrita naranja
        Container(
          width: 48,
          height: 3.5,
          margin: const EdgeInsets.fromLTRB(16, 10, 0, 12),
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        // calendario dentro de card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.only(top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: TableCalendar<Appointment>(
            locale: 'es_ES',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(999),
              ),
              formatButtonTextStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: _blue.withOpacity(.15),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Color(0xFF047857),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 3,
              outsideDaysVisible: false,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Citas para: ${DateFormat('EEE, dd MMMM', 'es_ES').format(_selectedDay!)}',
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: _buildAppointmentList(selectedDayAppointments)),
      ],
    );
  }

  Widget _buildAppointmentList(List<Appointment> appointmentsForDay) {
    if (_allAppointments.isEmpty) {
      return const Center(
        child: Text(
          'Aún no tienes ninguna cita.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    if (appointmentsForDay.isEmpty) {
      return const Center(
        child: Text(
          'No hay citas programadas para este día.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final pendientes =
        appointmentsForDay.where((a) => a.estado == 'pendiente').toList();
    final otras =
        appointmentsForDay.where((a) => a.estado != 'pendiente').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      children: [
        if (pendientes.isNotEmpty) ...[
          Text(
            'Pendientes de confirmación',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 6),
          ...pendientes.map(_buildAppointmentCard),
          if (otras.isNotEmpty)
            const SizedBox(height: 14),
        ],
        if (otras.isNotEmpty) ...[
          Text(
            'Citas programadas',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          ...otras.map(_buildAppointmentCard),
        ],
      ],
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final hora = DateFormat('HH:mm').format(appointment.fechaCitaDT);
    final bool isPastAppointment =
        appointment.fechaCitaDT.isBefore(DateTime.now());

    // colores por estado
    Color estadoColor;
    IconData estadoIcon;
    switch (appointment.estado) {
      case 'confirmada':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'denegada':
        estadoColor = Colors.red.shade500;
        estadoIcon = Icons.cancel;
        break;
      case 'cancelada':
        estadoColor = Colors.red.shade500;
        estadoIcon = Icons.close;
        break;
      case 'completada':
        estadoColor = Colors.blueGrey;
        estadoIcon = Icons.check_box;
        break;
      case 'pendiente':
      default:
        estadoColor = Colors.orange.shade800;
        estadoIcon = Icons.hourglass_top_rounded;
    }

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
      child: Column(
        children: [
          ListTile(
            onTap: () => _showPatientDetailsModal(context, appointment),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: _blue.withOpacity(.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                hora,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  height: 1.05,
                ),
              ),
            ),
            title: Text(
              appointment.pacienteNombre,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Row(
              children: [
                Icon(estadoIcon, color: estadoColor, size: 17),
                const SizedBox(width: 4),
                Text(
                  appointment.estado.toUpperCase(),
                  style: TextStyle(
                    color: estadoColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.info_outline, color: _blue.withOpacity(.9)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // para pendientes
                if (appointment.estado == 'pendiente') ...[
                  TextButton.icon(
                    onPressed: () =>
                        _handleUpdateStatus(appointment, 'denegada'),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Denegar',
                      style: TextStyle(color: Colors.red),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _handleUpdateStatus(appointment, 'confirmada'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],

                // para confirmadas (futuras) -> cancelar
                if (appointment.estado == 'confirmada' && !isPastAppointment)
                  TextButton.icon(
                    onPressed: () =>
                        _handleUpdateStatus(appointment, 'cancelada'),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text(
                      'Cancelar cita',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),

                // para confirmadas pasadas
                if (appointment.estado == 'confirmada' && isPastAppointment)
                  Text(
                    'Cita finalizada',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
