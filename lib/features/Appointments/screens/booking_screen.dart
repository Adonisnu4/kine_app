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

  // ✅ Popup “bonito” (mismo estilo iOS elegante que usamos en otras pantallas)
  Future<void> _showNiceInfoDialog({
    required IconData icon,
    required String title,
    required String message,
    Color color = _blue,
  }) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
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
        );
      },
    );
  }

  /* ---------------- Data / Reglas ---------------- */

  Future<void> _loadSlotsForSelectedDay() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
      _availableSlotsForDay = [];
    });
    try {
      final slots = await _availabilityService.getAvailableSlotsForDay(
        widget.kineId,
        _selectedDate,
      );
      if (!mounted) return;
      setState(() => _availableSlotsForDay = slots);
    } catch (e) {
      if (!mounted) return;
      _showErrorPopup('Error al Cargar',
          'No se pudieron cargar los horarios: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

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
      if (!mounted) return;
      setState(() {
        _hasPending = false;
        _hasConfirmed = false;
      });
      _showErrorPopup('Error de Verificación',
          'No se pudo verificar tu historial: ${e.toString()}');
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
      if (!mounted) return;
      setState(() => _selectedDate = picked);
      _loadSlotsForSelectedDay();
    }
  }

  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: widget.kineId,
          receiverName: widget.kineNombre,
        ),
      ),
    );
  }

  /* ---------------- Booking ---------------- */

  Future<void> _handleBooking() async {
    if (_selectedTimeSlot == null) return;
    if (!mounted) return;

    setState(() => _isBooking = true);

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

      final taken =
          await _appointmentService.isSlotTaken(widget.kineId, fullDateTime);
      if (taken) {
        _loadSlotsForSelectedDay();
        throw Exception('Ese horario acaba de ser tomado por otra persona.');
      }

      await _appointmentService.requestAppointment(
        kineId: widget.kineId,
        kineNombre: widget.kineNombre,
        fechaCita: fullDateTime,
      );

      if (!mounted) return;

      // 🔵 Popup de éxito con nuestro estilo
      await _showNiceInfoDialog(
        icon: Icons.check_circle_outline_rounded,
        title: '¡Solicitud enviada!',
        message: 'Te avisaremos cuando ${widget.kineNombre} confirme tu hora.',
        color: _blue,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showErrorPopup('Error al Solicitar', e.toString());
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  /* ---------------- Build ---------------- */

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPending) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    if (_hasPending || _hasConfirmed) {
      final isPending = _hasPending;
      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          title: const Text(
            'Agendar cita',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: (isPending ? _blue : Colors.green).withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPending
                        ? Icons.info_outline
                        : Icons.check_circle_outline,
                    color: isPending ? _blue : Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isPending
                      ? 'Ya tienes una cita pendiente'
                      : 'Cita ya confirmada',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isPending
                      ? 'Espera a que ${widget.kineNombre} confirme o rechace antes de agendar una nueva.'
                      : 'Ya tienes una hora confirmada con ${widget.kineNombre}.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87, height: 1.35),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(0, 44),
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

            // Card: Selecciona el día
            _SectionCard(
              title: '1. Selecciona el día',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('EEE, dd MMMM yyyy', 'es_ES')
                            .format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.1,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: const Text('Cambiar'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _blue, width: 1),
                          foregroundColor: _blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
              ),
            ),

            const SizedBox(height: 10),

            // CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_selectedTimeSlot == null || _isBooking)
                    ? null
                    : _handleBooking,
                icon: _isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(_isBooking ? 'Solicitando...' : 'Solicitar Cita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  disabledBackgroundColor: Colors.black12,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.05,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ---------------- Auxiliares ---------------- */

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

        return FutureBuilder<bool>(
          future: _appointmentService.isSlotTaken(widget.kineId, fullDateTime),
          builder: (context, snap) {
            final loading = snap.connectionState == ConnectionState.waiting;
            final taken = snap.data == true;

            if (loading) {
              return _TimeChip(
                label: slot.format(context),
                selected: false,
                onTap: null,
                border: Colors.grey.shade300,
                bg: Colors.grey.shade200,
                fg: Colors.grey.shade600,
              );
            }

            if (taken) {
              return _TimeChip(
                label: slot.format(context),
                selected: false,
                onTap: null,
                border: Colors.red.shade200,
                bg: Colors.red.shade50,
                fg: Colors.red.shade400,
                striked: true,
              );
            }

            return _TimeChip(
              label: slot.format(context),
              selected: isSelected,
              onTap: () {
                setState(() => _selectedTimeSlot = isSelected ? null : index);
              },
              border: isSelected ? _blue : Colors.grey.shade300,
              bg: isSelected ? _blue : Colors.white,
              fg: isSelected ? Colors.white : Colors.black87,
            );
          },
        );
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
