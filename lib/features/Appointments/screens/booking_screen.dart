// lib/screens/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
import 'package:kine_app/features/Appointments/services/availability_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kine_app/features/Chat/screens/chat_screen.dart';

// diálogos base reutilizables (errores)
import 'package:kine_app/shared/widgets/app_dialog.dart';

class BookingScreen extends StatefulWidget {
  final String kineId;
  final String kineNombre;
  const BookingScreen({
    super.key,
    required this.kineId,
    required this.kineNombre,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Paleta central
  static const _bg = Color(0xFFF6F6F7);
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  DateTime _selectedDate = DateTime.now();
  int? _selectedTimeSlot;

  bool _isCheckingPending = true;
  bool _isLoadingSlots = true;
  bool _isBooking = false;

  bool _hasPending = false;
  bool _hasConfirmed = false;

  List<TimeOfDay> _availableSlotsForDay = [];

  // 🚀 --- NUEVO ESTADO PARA SLOTS OCUPADOS ---
  // Almacena los slots ocupados (ej: "09:00", "10:00") para O(1) lookup
  Set<String> _takenSlots = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = _findNextAvailableWorkDay(DateTime.now());
    _checkExistingAppointments();
    _loadSlotsForSelectedDay();
  }

  /* ---------------- Popups rápidos ---------------- */
  Future<void> _showErrorPopup(String title, String content) async {
    if (!mounted) return;
    await showAppErrorDialog(
      context: context,
      icon: Icons.error_outline_rounded,
      title: title,
      content: content,
    );
  }

  // 🚀 --- FUNCIÓN DE CARGA MODIFICADA (MÁS EFICIENTE) ---
  /// Carga los horarios disponibles Y los ocupados para la fecha actual.
  Future<void> _loadSlotsForSelectedDay() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSlots = true; // Activa el indicador de carga
      _selectedTimeSlot = null; // Reinicia el slot seleccionado
      _availableSlotsForDay = []; // Limpia los slots anteriores
      _takenSlots = {}; // Limpia los slots ocupados
    });

    try {
      // Usamos Future.wait para cargar ambas cosas en paralelo
      final results = await Future.wait([
        // 1. Carga los horarios que el Kine DEFINIÓ (ej: 8:00, 9:00, 10:00)
        _availabilityService.getAvailableSlotsForDay(
          widget.kineId,
          _selectedDate,
        ),
        // 2. Carga los horarios que ya están OCUPADOS (ej: "09:00")
        _appointmentService.getTakenSlotsForDay(widget.kineId, _selectedDate),
      ]);

      if (!mounted) return; // 🛡️ Doble verificación

      // Asigna los resultados
      final slots = results[0] as List<TimeOfDay>;
      final taken = results[1] as Set<String>;

      setState(() {
        _availableSlotsForDay = slots;
        _takenSlots = taken; // Guarda los slots ocupados
      });
    } catch (e) {
      if (!mounted) return; // 🛡️ Protección de estado
      _showErrorPopup(
        'Error al Cargar',
        'No se pudieron cargar los horarios: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }
  // 🚀 --- FIN DE LA FUNCIÓN MODIFICADA ---

  /// Calcula el próximo día hábil
  DateTime _findNextAvailableWorkDay(DateTime date) {
    DateTime tempDate = date;
    if (date.isAfter(DateTime(date.year, date.month, date.day, 16, 0))) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    while (tempDate.weekday == DateTime.saturday ||
        tempDate.weekday == DateTime.sunday) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return DateTime(tempDate.year, tempDate.month, tempDate.day);
  }

  Future<void> _checkExistingAppointments() async {
    if (!mounted) return;
    setState(() => _isCheckingPending = true);
    try {
      final results = await Future.wait([
        _appointmentService.hasPendingAppointment(
          _currentUserId,
          widget.kineId,
        ),
        _appointmentService.hasConfirmedAppointmentWithKine(
          _currentUserId,
          widget.kineId,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _hasPending = results[0];
        _hasConfirmed = results[1];
      });
    } catch (e) {
      print('Error al verificar citas existentes: $e');
      if (!mounted) return; // 🛡️ Protección de estado
      setState(() {
        _hasPending = false;
        _hasConfirmed = false;
      });
      _showErrorPopup(
        'Error de Verificación',
        'Error al verificar historial: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isCheckingPending = false);
    }
  }

  /* ---------------- UI helpers ---------------- */

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime day) =>
          day.weekday != DateTime.saturday && day.weekday != DateTime.sunday,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _blue,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return; // 🛡️ Protección después del await
      setState(() {
        _selectedDate = picked;
      });
      _loadSlotsForSelectedDay(); // Recarga horarios al cambiar de día
    }
  }

  /// Procesa la solicitud de cita al profesional.
  void _handleBooking() async {
    if (_selectedTimeSlot == null) return;
    if (!mounted) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final slot = _availableSlotsForDay[_selectedTimeSlot!];
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        slot.hour,
        slot.minute,
      );

      final recheck = await Future.wait([
        _appointmentService.hasPendingAppointment(
          _currentUserId,
          widget.kineId,
        ),
        _appointmentService.hasConfirmedAppointmentWithKine(
          _currentUserId,
          widget.kineId,
        ),
      ]);
      if (!mounted) return;
      final hasPendingNow = recheck[0];
      final hasConfirmedNow = recheck[1];

      if (!mounted) return;

      setState(() {
        _hasPending = hasPendingNow;
        _hasConfirmed = hasConfirmedNow;
      });

      if (hasPendingNow) {
        throw Exception('Ya tienes una cita pendiente con este profesional.');
      }
      if (hasConfirmedNow) {
        throw Exception(
            'Ya tienes una cita confirmada activa con este profesional.');
      }

      // Doble check final (ya no usa la DB, usa el estado local)
      final slotString = DateFormat('HH:mm').format(fullDateTime);
      if (_takenSlots.contains(slotString)) {
        _loadSlotsForSelectedDay(); // Recarga los slots para reflejar el cambio
        throw Exception(
          'Este horario acaba de ser reservado por otra persona.',
        );
      }

      await _appointmentService.requestAppointment(
        kineId: widget.kineId,
        kineNombre: widget.kineNombre,
        fechaCita: fullDateTime,
      );

      if (!mounted) return;

      await showAppInfoDialog(
        context: context,
        icon: Icons.check_circle_outline_rounded,
        title: '¡Solicitud enviada!',
        message: 'Te avisaremos cuando ${widget.kineNombre} confirme tu hora.',
        color: _blue,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorPopup(
        'Error al Solicitar',
        'No se pudo agendar la cita: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  /// Navega al chat con el kinesiólogo (AHORA IMPLEMENTADO).
  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: widget.kineId,
          receiverName: widget.kineNombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPending) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    // --- 2. Bloques de Restricción ---
    if (_hasPending) {
      return _buildRestrictionScreen(
        icon: Icons.info_outline,
        iconColor: Colors.blue.shade700,
        title: 'Ya tienes una cita pendiente',
        message:
            'Espera a que esta solicitud sea confirmada o rechazada antes de agendar una nueva con el/la mismo(a) profesional.',
      );
    }
    if (_hasConfirmed) {
      return _buildRestrictionScreen(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green.shade700,
        title: 'Cita ya Confirmada',
        message:
            'Ya tienes una cita confirmada activa con ${widget.kineNombre}. No puedes tomar otra hora.',
      );
    }

    // Pantalla principal
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          'Agendar con ${widget.kineNombre}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Acento naranja
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 48,
                height: 3.5,
                margin: const EdgeInsets.fromLTRB(2, 6, 0, 12),
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  DateFormat(
                    'EEE, dd MMMM yyyy',
                    'es_ES',
                  ).format(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 6),
                  Container(height: 1, color: Colors.black12),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Card: Selecciona la hora
            _SectionCard(
              title: '2. Selecciona la hora',
              child: _isLoadingSlots
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: CircularProgressIndicator(color: _blue),
                      ),
                    )
                  : _buildTimeSlotGrid(),
            ),

            const SizedBox(height: 16),

            // Chat
            Center(
              child: TextButton.icon(
                onPressed: _navigateToChat,
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text('¿Dudas? Enviar Mensaje a ${widget.kineNombre}'),
                style: TextButton.styleFrom(
                  foregroundColor: _blue,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: _navigateToChat,
              ),
            ),
            const SizedBox(height: 25),

            // Botón Solicitar Cita
            ElevatedButton.icon(
              icon: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isBooking ? 'Solicitando...' : 'Solicitar Cita'),
              onPressed: (_selectedTimeSlot == null || _isBooking)
                  ? null // Deshabilita
                  : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de utilidad para mostrar las pantallas de restricción
  Widget _buildRestrictionScreen({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar Cita')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 60),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 --- GRILLA DE HORARIOS MODIFICADA (SIN FUTUREBUILDER) ---
  /// Widget que construye la grilla de horarios disponibles (ChoiceChip).
  Widget _buildTimeSlotGrid() {
    if (_availableSlotsForDay.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: const Text(
          'No hay horarios disponibles para este día.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black87),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _availableSlotsForDay.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final slot = _availableSlotsForDay[index];
        final isSelected = _selectedTimeSlot == index;

        final fullDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          slot.hour,
          slot.minute,
        );

        // Bloquea slots pasados (Esta lógica está bien)
        if (fullDateTime.isBefore(DateTime.now())) {
          return _TimeChip(
            label: slot.format(context),
            selected: false,
            onTap: null,
            border: Colors.grey.shade300,
            bg: Colors.grey.shade200,
            fg: Colors.grey.shade500,
            striked: true,
          );
        }

        // --- INICIO DE LA MODIFICACIÓN (ELIMINAMOS FUTUREBUILDER) ---

        // Formatea el slot actual a "HH:mm" para comparar
        final slotString = DateFormat('HH:mm').format(fullDateTime);

        // Comprueba contra el Set que ya cargamos (búsqueda O(1))
        final isTaken = _takenSlots.contains(slotString);

        // Muestra el chip del horario
        return ChoiceChip(
          label: Text(slot.format(context)),
          selected: isSelected,
          backgroundColor: isTaken ? Colors.red.shade100 : Colors.white,
          selectedColor: Colors.blue.shade700,
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : (isTaken ? Colors.grey.shade500 : Colors.black87),
            decoration: isTaken ? TextDecoration.lineThrough : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          onSelected: isTaken
              ? null // No seleccionable si está tomado
              : (selected) {
                  setState(() {
                    _selectedTimeSlot = selected ? index : null;
                  });
                },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected
                  ? Colors.blue.shade700
                  : (isTaken ? Colors.red.shade200 : Colors.grey.shade300),
            ),
          ),
          showCheckmark: false, // Oculta el checkmark predeterminado
        );
        // --- FIN DE LA MODIFICACIÓN ---
      },
    );
  }
}

/* ---------------- Subwidgets ---------------- */

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _BookingScreenState._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -.1,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color border;
  final Color bg;
  final Color fg;
  final bool striked;

  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.border,
    required this.bg,
    required this.fg,
    this.striked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              decoration: striked ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}
