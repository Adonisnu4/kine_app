// Importa estilos y componentes visuales
import 'package:flutter/material.dart';

// Autenticación para obtener el ID del kinesiólogo actual
import 'package:firebase_auth/firebase_auth.dart';

// Calendario interactivo
import 'package:table_calendar/table_calendar.dart';

// Para formatear horas y fechas en formato humano
import 'package:intl/intl.dart';

// Modelo de Cita
import 'package:kine_app/features/Appointments/models/appointment.dart';

// Servicio de citas
import 'package:kine_app/features/Appointments/services/appointment_service.dart';

/// Pantalla que permite a un kinesiólogo administrar sus citas:
/// verlas, confirmarlas, denegarlas y revisar su agenda diaria.
class KinePanelScreen extends StatefulWidget {
  const KinePanelScreen({super.key});

  @override
  State<KinePanelScreen> createState() => _KinePanelScreenState();
}

class _KinePanelScreenState extends State<KinePanelScreen> {
  // Paleta local
  static const _bg = Color(0xFFF3F3F3);
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

  // Servicio de citas
  final AppointmentService _appointmentService = AppointmentService();

  // Identificador del kinesiólogo actual
  final String _currentKineId = FirebaseAuth.instance.currentUser!.uid;

  // Stream que escucha en tiempo real todas las citas del kine
  late Stream<List<Appointment>> _appointmentsStream;

  // Lista interna de citas cargadas
  List<Appointment> _allAppointments = [];

  // Estado visual del calendario
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();

    // Día seleccionado inicial = hoy
    _selectedDay = _focusedDay;

    // Carga en tiempo real todas las citas asociadas al kine actual
    _appointmentsStream = _appointmentService.getKineAppointments(
      _currentKineId,
    );
  }

  /// Muestra un cuadro de diálogo informativo con un ícono y un mensaje.
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

  /// Maneja la actualización del estado de una cita (confirmar/denegar)
  Future<void> _handleUpdateStatus(
    Appointment appointment,
    String newStatus,
  ) async {
    try {
      // Marca la cita con el nuevo estado
      await _appointmentService.updateAppointmentStatus(appointment, newStatus);

      // Confirmación visual
      await _showInfoDialog(
        icon: Icons.check_circle_outline_rounded,
        title: "Estado actualizado",
        message: "La cita fue marcada como $newStatus",
        color: _blue,
      );
    } catch (e) {
      // Notifica error
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

      // Construcción reactiva: escucha citas en tiempo real
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          // Mostrar indicador mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si hay datos, los guardamos internamente
          _allAppointments = snapshot.data ?? [];

          return _buildCalendarAndList();
        },
      ),
    );
  }

  /// Construye la vista principal:
  /// parte superior (acento) + calendario + lista del día
  Widget _buildCalendarAndList() {
    // Filtra todas las citas del kine para el día seleccionado
    final selectedDayAppointments = _allAppointments.where((appointment) {
      return isSameDay(appointment.fechaCitaDT, _selectedDay!);
    }).toList()..sort((a, b) => a.fechaCita.compareTo(b.fechaCita));

    return Column(
      children: [
        // Barra naranja superior decorativa
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

  /// Construye el calendario interactivo
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

        focusedDay: _focusedDay, // Día central visible
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

        // Cuando el usuario selecciona un día
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

        // Cuando se cambia de mes
        onPageChanged: (day) => _focusedDay = day,
      ),
    );
  }

  /// Lista las citas del día seleccionado
  Widget _appointmentList(List<Appointment> list) {
    if (list.isEmpty) {
      return const Center(child: Text("No hay citas para este día."));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: list.map((e) => _appointmentCard(e)).toList(),
    );
  }

  /// Construye la tarjeta de cada cita del día
  Widget _appointmentCard(Appointment a) {
    // Determina si ya pasó la hora de la cita
    final isPast = a.fechaCitaDT.isBefore(DateTime.now());

    // Auto-cancelación simple (el cron job también lo hace en Functions)
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

          // Texto de advertencia si la cita expiró
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

          // Botones para confirmarla o rechazarla
          // Solo si la cita aún no pasó en el tiempo real
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
