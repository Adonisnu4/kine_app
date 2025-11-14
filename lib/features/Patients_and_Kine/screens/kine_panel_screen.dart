// lib/screens/kine_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'package:kine_app/features/Appointments/models/appointment.dart';
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
import 'package:kine_app/features/Chat/screens/chat_screen.dart';

// 💡 IMPORTAMOS LOS DIÁLOGOS
import 'package:kine_app/shared/widgets/app_dialog.dart';

class KinePanelScreen extends StatefulWidget {
  const KinePanelScreen({super.key});

  @override
  State<KinePanelScreen> createState() => _KinePanelScreenState();
}

class _KinePanelScreenState extends State<KinePanelScreen> {
  // Paleta centralizada
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

  // ===== Helpers de diálogos elegantes =====
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                    // Cancelar con borde naranjo
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.2),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(0, 42),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
  // ================================================

  List<Appointment> _getEventsForDay(DateTime day) {
    return _allAppointments.where((appointment) {
      // 🚀 --- CORRECCIÓN A MAYÚSCULAS ---
      if (appointment.estado == 'CONFIRMADA' ||
          appointment.estado == 'PENDIENTE') {
        // 🚀 --- FIN DE CORRECCIÓN ---
        return isSameDay(appointment.fechaCitaDT, day);
      }
      return false;
    }).toList();
  }

  /// Maneja la acción de Aceptar, Denegar o CANCELAR una cita.
  Future<void> _handleUpdateStatus(
    Appointment appointment,
    String newStatus, // 🚀 Recibirá "CONFIRMADA", "DENEGADA", etc.
  ) async {
    // 1. CONFIRMACIÓN para ACEPTAR
    // 🚀 --- CORRECCIÓN A MAYÚSCULAS ---
    if (newStatus == 'CONFIRMADA') {
      // 🚀 --- FIN DE CORRECCIÓN ---
      final bool? confirm = await showAppConfirmationDialog(
        context: context,
        icon: Icons.check_circle_outline_rounded,
        title: 'Confirmar Cita',
        content:
            '¿Estás seguro de confirmar esta cita con ${appointment.pacienteNombre}?',
        confirmText: 'Sí, Confirmar',
        cancelText: 'Cancelar',
        isDestructive: false,
      );
      if (confirm != true) return;
    }

    // 2. CONFIRMACIÓN para RECHAZAR (Denegar)
    // 🚀 --- CORRECCIÓN A MAYÚSCULAS ---
    if (newStatus == 'DENEGADA') {
      // 🚀 --- FIN DE CORRECCIÓN ---
      final bool? confirm = await showAppConfirmationDialog(
        context: context,
        icon: Icons.block_rounded,
        title: 'Rechazar Cita',
        content:
            '¿Estás seguro de rechazar esta solicitud de ${appointment.pacienteNombre}?',
        confirmText: 'Sí, Rechazar',
        cancelText: 'Cancelar',
        isDestructive: true,
      );
      if (confirm != true) return;
    }

    // 3. CONFIRMACIÓN para CANCELAR
    // 🚀 --- CORRECCIÓN A MAYÚSCULAS ---
    if (newStatus == 'CANCELADA') {
      // 🚀 --- FIN DE CORRECCIÓN ---
      final bool? confirm = await showAppConfirmationDialog(
        context: context,
        icon: Icons.warning_amber_rounded,
        title: 'Cancelar cita',
        message:
            'Esto notificará al paciente. ¿Deseas cancelar la cita confirmada?',
        confirmText: 'Cancelar cita',
        destructive: true,
        accentColor: Colors.red.shade500,
      );
      if (confirm != true) return;
    }

    // 4. ACTUALIZACIÓN DEL ESTADO
    try {
      // 🚀 Se envía el estado en MAYÚSCULAS al servicio
      await _appointmentService.updateAppointmentStatus(appointment, newStatus);

      if (!mounted) return;

      // Muestra el POPUP de RESULTADO
      // 🚀 --- CORRECCIÓN A MAYÚSCULAS ---
      if (newStatus == 'CONFIRMADA') {
        // 🚀 --- FIN DE CORRECCIÓN ---
        await showAppInfoDialog(
          context: context,
          icon: Icons.check_circle_outline_rounded,
          title: '¡Cita confirmada!',
          message: 'El paciente será notificado.',
          color: _blue,
        );
        // 🚀 --- CORRECCIÓN A MAYÚSCULAS ---
      } else if (newStatus == 'DENEGADA') {
        // 🚀 --- FIN DE CORRECCIÓN ---
        await showAppWarningDialog(
          context: context,
          icon: Icons.block_rounded,
          title: 'Cita rechazada',
          message: 'La solicitud ha sido rechazada.',
          color: Colors.red.shade500,
        );
        // 🚀 --- CORRECCIÓN A MAYÚSCULAS ---
      } else if (newStatus == 'CANCELADA') {
        // 🚀 --- FIN DE CORRECCIÓN ---
        await showAppErrorDialog(
          context: context,
          icon: Icons.cancel_outlined,
          title: 'Cita cancelada',
          message: 'La cita ha sido cancelada y el paciente fue informado.',
          color: Colors.red.shade500,
        );
      }
    } catch (e) {
      if (!mounted) return;

      await showAppErrorDialog(
        context: context,
        icon: Icons.error_outline_rounded,
        title: 'Error',
        message: 'No se pudo actualizar la cita: $e',
        color: Colors.red.shade500,
      );
    }
  }

  // ===== Estilo para “status pill” del pop-up =====
  ({Color bg, Color fg, IconData icon, String label}) _estadoStyle(String estado) {
    switch (estado) {
      case 'confirmada':
        return (bg: const Color(0xFFE6F7F0), fg: const Color(0xFF0F9D58), icon: Icons.check_circle, label: 'CONFIRMADA');
      case 'denegada':
        return (bg: const Color(0xFFFFEBEE), fg: const Color(0xFFD32F2F), icon: Icons.cancel, label: 'DENEGADA');
      case 'cancelada':
        return (bg: const Color(0xFFFFEBEE), fg: const Color(0xFFD32F2F), icon: Icons.close, label: 'CANCELADA');
      case 'completada':
        return (bg: const Color(0xFFE8F0FE), fg: const Color(0xFF1E88E5), icon: Icons.check_box, label: 'COMPLETADA');
      default: // pendiente
        return (bg: const Color(0xFFFFF7ED), fg: _orange, icon: Icons.hourglass_top_rounded, label: 'PENDIENTE');
    }
  }

  // ===== Bottom-sheet (pegado abajo) con estética iOS =====
  void _showPatientDetailsModal(BuildContext context, Appointment appointment) {
    final estilo = _estadoStyle(appointment.estado);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      // pegado abajo: dejamos el background del sheet y redondeamos arriba
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.pacienteNombre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.email_outlined, color: Colors.grey[600]),
                title: Text(appointment.pacienteEmail ?? 'No disponible'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey[600],
                ),

                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _blue.withOpacity(.14),
                      child: Text(
                        (appointment.pacienteNombre.isNotEmpty
                                ? appointment.pacienteNombre[0]
                                : '?')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.pacienteNombre,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            appointment.pacienteEmail ?? 'Sin email',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Estado
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: estilo.bg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: estilo.fg.withOpacity(.18)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(estilo.icon, size: 16, color: estilo.fg),
                          const SizedBox(width: 6),
                          Text(
                            estilo.label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: estilo.fg,
                              letterSpacing: .3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline, color: Colors.grey[600]),
                title: Text('Estado: ${appointment.estado.toUpperCase()}'),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Enviar Mensaje'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),

                const SizedBox(height: 16),

                // Acciones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cerrar'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _orange,
                          side: const BorderSide(color: _orange, width: 1.2),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
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
                        icon: const Icon(Icons.chat_bubble_outline_rounded),
                        label: const Text('Enviar mensaje'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
        // calendario en card
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

    final pendientes = appointmentsForDay
        // 🚀 --- CORRECCIÓN A MAYÚSCULAS ---
        .where((a) => a.estado == 'PENDIENTE')
        // 🚀 --- FIN DE CORRECCIÓN ---
        .toList();
    final otras = appointmentsForDay
        // 🚀 --- CORRECCIÓN A MAYÚSCULAS ---
        .where((a) => a.estado != 'PENDIENTE')
        // 🚀 --- FIN DE CORRECCIÓN ---
        .toList();

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
    IconData estadoIcon;
    Color estadoColor;

    // 🚀 --- ¡ESTA ES LA LÓGICA PRINCIPAL DEL BUG! ---
    final bool isPastAppointment = appointment.fechaCitaDT.isBefore(
      DateTime.now(),
    );
    // 🚀 --- FIN DE LA LÓGICA ---

    // 🚀 --- CORRECCIÓN A MAYÚSCULAS (Switch) ---
    switch (appointment.estado) {
      case 'CONFIRMADA':
        estadoIcon = Icons.check_circle;
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        break;
      case 'DENEGADA':
        estadoIcon = Icons.cancel;
        estadoColor = Colors.red;
        break;
      case 'COMPLETADA':
        estadoIcon = Icons.check_box;
        estadoColor = Colors.blueGrey;
        break;
      case 'CANCELADA':
        estadoIcon = Icons.close;
        break;
      case 'completada':
        estadoColor = Colors.blueGrey;
        estadoIcon = Icons.check_box;
        break;
      case 'PENDIENTE':
      default:
        estadoColor = Colors.orange.shade800;
        estadoIcon = Icons.hourglass_top_rounded;
    }
    // 🚀 --- FIN DE CORRECCIÓN ---

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
                // 🚀 --- LÓGICA DE BOTONES CORREGIDA ---

                // 1. Botones para citas PENDIENTES (Solo si NO han pasado)
                if (appointment.estado == 'PENDIENTE' &&
                    !isPastAppointment) ...[
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Denegar',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () =>
                        // 🚀 Envía MAYÚSCULAS
                        _handleUpdateStatus(appointment, 'DENEGADA'),
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
                    onPressed: () =>
                        // 🚀 Envía MAYÚSCULAS
                        _handleUpdateStatus(appointment, 'CONFIRMADA'),
                  ),
                ],

                // 2. Indicador para citas PENDIENTES (Que SÍ han pasado)
                if (appointment.estado == 'PENDIENTE' && isPastAppointment)
                  Text(
                    'Expirada (no confirmada)',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                // 3. Botón para citas CONFIRMADAS (Solo si NO han pasado)
                if (appointment.estado == 'CONFIRMADA' && !isPastAppointment)
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text(
                      'Cancelar Cita',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () =>
                        // 🚀 Envía MAYÚSCULAS
                        _handleUpdateStatus(appointment, 'CANCELADA'),
                  ),

                // 4. INDICADOR para citas CONFIRMADAS PASADAS
                if (appointment.estado == 'CONFIRMADA' && isPastAppointment)
                  Text(
                    'Cita finalizada',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                // 🚀 --- FIN DE LA LÓGICA DE BOTONES ---
              ],
            ),
          ),
        ],
      ),
    );
  }
}
