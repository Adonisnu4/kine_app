// lib/screens/booking_screen.dart
import 'package:flutter/material.dart';
// ⚠️ Rutas corregidas para tu estructura:
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
import 'package:kine_app/features/Appointments/services/availability_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 🚀 AÑADIR ESTE IMPORT: Para navegar directamente a la pantalla de chat
import 'package:kine_app/features/Chat/screens/chat_screen.dart';

// 💡 --- IMPORTAMOS LOS DIÁLOGOS ---
import 'package:kine_app/shared/widgets/app_dialog.dart';

/// Pantalla para agendar una nueva cita con un kinesiólogo específico.
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
  // Instancias de servicios para interactuar con la base de datos
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();
  // ID del usuario actual logueado para registrar la cita
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // --- Estados de la Pantalla ---
  DateTime _selectedDate = DateTime.now(); // Día seleccionado para la cita
  int? _selectedTimeSlot; // Índice del horario seleccionado en la lista
  bool _isCheckingPending =
      true; // Indica si se está verificando historial (carga inicial)
  bool _isLoadingSlots =
      true; // Indica si se están cargando los horarios para el día
  bool _isBooking = false; // Indica si se está enviando la solicitud de reserva

  // --- Estados para Restricciones de Citas (para evitar doble reserva) ---
  bool _hasPending =
      false; // True si tiene una cita PENDIENTE de aprobación con este Kine
  bool _hasConfirmed =
      false; // True si tiene una cita CONFIRMADA FUTURA con este Kine
  // --- Fin Estados de Restricciones ---

  // Lista de horarios disponibles (TimeOfDay) para el día seleccionado
  List<TimeOfDay> _availableSlotsForDay = [];

  // 🚀 --- NUEVO ESTADO PARA SLOTS OCUPADOS ---
  // Almacena los slots ocupados (ej: "09:00", "10:00") para O(1) lookup
  Set<String> _takenSlots = {};

  @override
  void initState() {
    super.initState();
    // Inicializa con el próximo día hábil disponible, sin fines de semana o pasado el corte
    _selectedDate = _findNextAvailableWorkDay(DateTime.now());
    // Inicia la verificación de restricciones (pendiente/confirmada)
    _checkExistingAppointments();
    // Carga los horarios del día hábil inicial
    _loadSlotsForSelectedDay();
  }

  /// Muestra un Popup de ERROR (rojo)
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
    if (!mounted) return; // 🛡️ Protección de estado
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
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
      }
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

  /// Verifica si el paciente ya tiene citas pendientes O confirmadas con este Kine.
  Future<void> _checkExistingAppointments() async {
    if (!mounted) return; // 🛡️ Protección de estado
    setState(() {
      _isCheckingPending = true;
    });
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
      if (!mounted) return; // 🛡️ Doble verificación
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
      if (mounted) {
        setState(() {
          _isCheckingPending = false; // Finaliza la carga inicial
        });
      }
    }
  }

  /// Muestra el selector de fechas y actualiza el estado.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime day) =>
          day.weekday != DateTime.saturday && day.weekday != DateTime.sunday,
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
      final slotTime = _availableSlotsForDay[_selectedTimeSlot!];
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        slotTime.hour,
        slotTime.minute,
      );

      // --- Re-verificación de restricciones ANTES de guardar ---
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
      final hasPendingNow = results[0];
      final hasConfirmedNow = results[1];

      if (!mounted) return;

      setState(() {
        _hasPending = hasPendingNow;
        _hasConfirmed = hasConfirmedNow;
      });

      if (hasPendingNow) {
        throw Exception('Ya tienes una cita pendiente con este kinesiólogo.');
      }
      if (hasConfirmedNow) {
        throw Exception(
          'Ya tienes una cita confirmada activa con este kinesiólogo.',
        );
      }

      // Doble check final (ya no usa la DB, usa el estado local)
      final slotString = DateFormat('HH:mm').format(fullDateTime);
      if (_takenSlots.contains(slotString)) {
        _loadSlotsForSelectedDay(); // Recarga los slots para reflejar el cambio
        throw Exception(
          'Este horario acaba de ser reservado por otra persona.',
        );
      }

      // Procede con la solicitud de cita
      await _appointmentService.requestAppointment(
        kineId: widget.kineId,
        kineNombre: widget.kineNombre,
        fechaCita: fullDateTime,
      );

      if (!mounted) return;

      await showAppInfoDialog(
        context: context,
        icon: Icons.check_circle_outline_rounded,
        title: '¡Solicitud Enviada!',
        content:
            'Tu solicitud fue enviada con éxito. Espera la confirmación del profesional.',
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
    // 1. Pantalla de Carga Inicial
    if (_isCheckingPending) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
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
    // --- Fin Bloques de Restricción ---

    // 3. Pantalla Principal de Agendamiento
    return Scaffold(
      appBar: AppBar(
        title: Text('Agendar con ${widget.kineNombre}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección 1: Selector de Fecha
            Text(
              '1. Selecciona el día',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Cambiar'),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const Divider(height: 30),

            // Sección 2: Selector de Hora (Grilla)
            Text(
              '2. Selecciona la hora',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            // Muestra indicador de carga o la grilla de horarios
            _isLoadingSlots
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0),
                      child: CircularProgressIndicator(color: Colors.teal),
                    ),
                  )
                : _buildTimeSlotGrid(),

            const SizedBox(height: 25),
            const Divider(),
            const SizedBox(height: 15),

            // Botón de Chat (AHORA FUNCIONAL)
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: Text('¿Dudas? Enviar Mensaje a ${widget.kineNombre}'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
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
    // Mensaje si no hay horarios
    if (_availableSlotsForDay.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'El kinesiólogo no tiene horarios disponibles para este día.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      physics:
          const NeverScrollableScrollPhysics(), // Deshabilita scroll interno
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _availableSlotsForDay.length,
      itemBuilder: (context, index) {
        final slot = _availableSlotsForDay[index];
        final isSelected = _selectedTimeSlot == index;

        // Combina fecha y hora para una comparación precisa
        final fullDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          slot.hour,
          slot.minute,
        );

        // Bloquea slots pasados (Esta lógica está bien)
        if (fullDateTime.isBefore(DateTime.now())) {
          return ChoiceChip(
            label: Text(slot.format(context)),
            selected: false,
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: Colors.grey.shade400,
              decoration: TextDecoration.lineThrough, // Tachado visual
            ),
            onSelected: null, // No seleccionable
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
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
} // Fin clase _BookingScreenState
