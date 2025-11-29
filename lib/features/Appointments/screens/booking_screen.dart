// Pantalla donde el paciente agenda una cita con un kinesiólogo
// Se encarga de: seleccionar día, cargar horarios disponibles,
// validar si ya tiene citas pendientes/confirmadas y enviar la solicitud.

import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
import 'package:kine_app/features/Appointments/services/availability_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kine_app/features/Chat/screens/chat_screen.dart';
import 'package:kine_app/shared/widgets/app_dialog.dart'; // *Diálogo de errores reutilizable

class BookingScreen extends StatefulWidget {
  final String kineId; // ID del profesional
  final String kineNombre; // Nombre del profesional

  const BookingScreen({
    super.key,
    required this.kineId,
    required this.kineNombre,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // Paleta de colores / constantes
  static const _bg = Color(0xFFF6F6F7);
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

  // Servicios principales/
  final AppointmentService _appointmentService =
      AppointmentService(); // Lógica de citas
  final AvailabilityService _availabilityService =
      AvailabilityService(); // Lógica de horarios

  final String _currentUserId =
      FirebaseAuth.instance.currentUser!.uid; // Usuario actual

  //Estado UI
  DateTime _selectedDate = DateTime.now(); // Día elegido
  int? _selectedTimeSlot; // Índice del horario elegido

  bool _isCheckingPending = true; // Está verificando si ya tiene citas
  bool _isLoadingSlots = true; // Está cargando los horarios disponibles
  bool _isBooking = false; // Aún no está enviando la solicitud

  bool _hasPending = false; // Aún no se sabe existe cita pendiente
  bool _hasConfirmed = false; // Aún no se sabe cita confirmada

  List<TimeOfDay> _availableSlotsForDay =
      []; // Lista de horarios disponibles para ese día

  //Inicialización
  @override
  void initState() {
    super.initState();

    // Selecciona el próximo día hábil
    _selectedDate = _findNextAvailableWorkDay(DateTime.now());

    // Verifica si el usuario ya tiene una cita
    _checkExistingAppointments();

    // Carga horarios disponibles para el día inicial
    _loadSlotsForSelectedDay();
  }

  // POPUPS

  // Popup de error simple
  Future<void> _showErrorPopup(String title, String content) async {
    if (!mounted) return;
    await showAppErrorDialog(
      context: context,
      icon: Icons.error_outline_rounded,
      title: title,
      content: content,
    );
  }

  // Popup informativo
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
                // Icono
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

                // Título
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

                // Mensaje
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

                // Botón OK
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

  // Carga de horarios

  // Obtiene horarios disponibles para el día seleccionado
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
      _showErrorPopup(
        'Error al Cargar',
        'No se pudieron cargar los horarios: ${e.toString()}',
      );
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  // Reglas / lógica
  // Encuentra el próximo día hábil (no fin de semana)
  DateTime _findNextAvailableWorkDay(DateTime date) {
    DateTime tempDate = date;

    // Si ya pasó la hora laboral, mueve al siguiente día
    if (date.isAfter(DateTime(date.year, date.month, date.day, 16, 0))) {
      tempDate = tempDate.add(const Duration(days: 1));
    }

    // Evita los sábados y domingos
    while (tempDate.weekday == DateTime.saturday ||
        tempDate.weekday == DateTime.sunday) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    //Devolver el dia limpio sin citas
    return DateTime(tempDate.year, tempDate.month, tempDate.day);
  }

  // Verifica si el usuario ya tiene una cita pendiente o confirmada con este kinesiólogo
  Future<void> _checkExistingAppointments() async {
    if (!mounted) return; // Evita continuar si la pantalla ya no está activa

    setState(
      () => _isCheckingPending = true,
    ); // Activa el estado de "verificando"

    try {
      // Ejecuta ambas consultas a Firebase al mismo tiempo
      // results[0] → tiene cita pendiente?
      // results[1] → tiene cita confirmada?
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

      // Si el widget ya no está montado, detén aquí
      if (!mounted) return;

      // Actualiza los resultados en la UI
      setState(() {
        _hasPending = results[0];
        _hasConfirmed = results[1];
      });
    } catch (e) {
      // Muestra un mensaje en caso de error
      _showErrorPopup(
        'Error de Verificación',
        'No se pudo verificar tu historial: ${e.toString()}',
      );
    } finally {
      // Apaga el estado de "verificando" siempre, funcione o falle
      if (mounted) setState(() => _isCheckingPending = false);
    }
  }

  //Seleccionar día
  // Abre el calendario para seleccionar un día hábil (lunes a viernes)
  Future<void> _selectDate(BuildContext context) async {
    // Muestra el selector de fechas y espera la respuesta del usuario
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Día actualmente seleccionado
      firstDate: DateTime.now(), // No permite días pasados
      lastDate: DateTime.now().add(
        Duration(days: 90),
      ), // Máximo 90 días hacia adelante
      // Solo permite días que NO sean sábado ni domingo
      selectableDayPredicate: (day) =>
          day.weekday != DateTime.saturday && day.weekday != DateTime.sunday,
    );

    // Si el usuario seleccionó un día distinto al actual
    if (picked != null && picked != _selectedDate) {
      if (!mounted) return;

      // Actualiza el día seleccionado
      setState(() => _selectedDate = picked);

      // Carga los horarios disponibles para ese día
      _loadSlotsForSelectedDay();
    }
  }

  // Navega a la pantalla de chat con el kinesiólogo seleccionado
  void _navigateToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Construye la pantalla del chat y le pasa los datos del receptor
        builder: (_) => ChatScreen(
          receiverId: widget.kineId, // ID del kinesiólogo
          receiverName: widget.kineNombre, // Nombre del kinesiólogo
        ),
      ),
    );
  }

  //Enviar cita
  // Maneja todo el proceso de solicitud de una nueva cita
  Future<void> _handleBooking() async {
    // Si no hay horario seleccionado, no hace nada
    if (_selectedTimeSlot == null) return;

    // Evita errores si la pantalla ya no está activa
    if (!mounted) return;

    // Activa estado de "enviando cita" (muestra loader en botón)
    setState(() => _isBooking = true);

    try {
      // Obtiene el TimeOfDay elegido por el usuario
      final slot = _availableSlotsForDay[_selectedTimeSlot!];

      // Combina fecha seleccionada con la hora seleccionada
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        slot.hour,
        slot.minute,
      );

      // Revalidación final: se consulta a Firestore si el usuario
      // ya tiene una cita pendiente o confirmada
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

      // Resultados: si tiene cita pendiente o confirmada
      final hasPendingNow = recheck[0];
      final hasConfirmedNow = recheck[1];

      // Actualiza el estado con esos datos
      setState(() {
        _hasPending = hasPendingNow;
        _hasConfirmed = hasConfirmedNow;
      });

      //No permitir enviar una nueva cita si ya tiene una pendiente
      if (hasPendingNow) {
        throw Exception('Ya tienes una cita pendiente con este profesional.');
      }

      // No permitir si ya hay una confirmada activa
      if (hasConfirmedNow) {
        throw Exception(
          'Ya tienes una cita confirmada activa con este profesional.',
        );
      }

      //Revisa en tiempo real si el horario fue tomado por otra persona recién
      final taken = await _appointmentService.isSlotTaken(
        widget.kineId,
        fullDateTime,
      );

      //Si el horario ya no está disponible, recarga los horarios
      if (taken) {
        _loadSlotsForSelectedDay();
        throw Exception('Ese horario acaba de ser tomado por otra persona.');
      }

      //Enviar solicitud de cita a Firestore
      await _appointmentService.requestAppointment(
        kineId: widget.kineId,
        kineNombre: widget.kineNombre,
        fechaCita: fullDateTime,
      );

      //Mostrar popup de éxito
      await _showNiceInfoDialog(
        icon: Icons.check_circle_outline_rounded,
        title: '¡Solicitud enviada!',
        message: 'Te avisaremos cuando ${widget.kineNombre} confirme tu hora.',
      );

      //Volver atrás después de solicitar la cita
      Navigator.pop(context);
    } catch (e) {
      // Si ocurre cualquier error en el proceso, mostrar popup de error
      _showErrorPopup('Error al Solicitar', e.toString());
    } finally {
      // Siempre desactiva el estado "enviando"
      if (mounted) setState(() => _isBooking = false);
    }
  }

  // BUILD (UI)

  @override
  Widget build(BuildContext context) {
    //Mientras se verifica en Firebase si el usuario tiene citas previas,
    //mostramos un loader ocupando toda la pantalla.
    if (_isCheckingPending) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: CircularProgressIndicator(color: _blue)),
      );
    }

    //Si el usuario TIENE una cita pendiente o confirmada,
    //se bloquea el proceso de agendar y se muestra una advertencia.
    if (_hasPending || _hasConfirmed) {
      final isPending = _hasPending; // Para distinguir qué mensaje mostrar

      return Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          title: const Text('Agendar cita'),
        ),

        //Contenedor blanco con mensaje de advertencia
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
                // Icono informativo (azul si es pendiente, verde si está confirmada)
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: (isPending ? _blue : Colors.green).withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPending ? Icons.info_outline : Icons.check_circle_outline,
                    color: isPending ? _blue : Colors.green,
                  ),
                ),
                const SizedBox(height: 12),

                //Título del mensaje
                Text(
                  isPending
                      ? 'Ya tienes una cita pendiente'
                      : 'Cita ya confirmada',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),

                //Explicación según el tipo de cita
                Text(
                  isPending
                      ? 'Espera a que ${widget.kineNombre} confirme o rechace antes de agendar una nueva.'
                      : 'Ya tienes una hora confirmada con ${widget.kineNombre}.',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                //Botón para volver atrás
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Entendido'),
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
      backgroundColor: _bg, // Color de fondo de toda la pantalla

      appBar: AppBar(
        backgroundColor: Colors.white, // Color del AppBar
        elevation: 0, // Sin sombra
        foregroundColor: Colors.black87, // Color del texto/íconos
        title: Text(
          'Agendar con ${widget.kineNombre}', // Título dinámico con nombre del kine
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Cuerpo de la pantalla: Scroll para evitar overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Línea decorativa naranja bajo título
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

            // === PASO 1: Selección de día ===
            _SectionCard(
              title: '1. Selecciona el día',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Muestra la fecha seleccionada + botón "Cambiar"
                  Row(
                    children: [
                      Text(
                        DateFormat(
                          'EEE, dd MMMM yyyy',
                          'es_ES',
                        ).format(_selectedDate), // Día formateado
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.1,
                        ),
                      ),

                      const Spacer(), // Empuja el botón hacia la derecha
                      // Botón cambiar fecha (abre date picker)
                      OutlinedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                        ),
                        label: const Text('Cambiar'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _blue),
                          foregroundColor: _blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Línea divisoria
                  Container(height: 1, color: Colors.black12),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Selección de hora
            _SectionCard(
              title: '2. Selecciona la hora',

              // Muestra loader o la grilla de horarios
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

            // Botón para escribirle al kine (Chat)
            Center(
              child: TextButton.icon(
                onPressed: _navigateToChat, // Ir al chat
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text(
                  '¿Dudas? Enviar Mensaje a ${widget.kineNombre}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(foregroundColor: _blue),
              ),
            ),

            const SizedBox(height: 10),

            // BOTÓN ENVIAR SOLICITUD DE CITA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                // Solo permite presionar si hay horario seleccionado y no está enviando
                onPressed: (_selectedTimeSlot == null || _isBooking)
                    ? null
                    : _handleBooking,

                // Ícono: loader o check según estado
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

                // Texto dinámico
                label: Text(_isBooking ? 'Solicitando...' : 'Solicitar Cita'),

                // Estilo del botón
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size(0, 52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Grid de horarios disponibles

  Widget _buildTimeSlotGrid() {
    // Si no hay horarios disponibles para este día, muestra un mensaje
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
        ),
      );
    }

    // Si sí hay horarios, muestra la grilla con horas disponibles
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
        final slot = _availableSlotsForDay[index]; // Hora actual del listado
        final isSelected = _selectedTimeSlot == index; // ¿Está seleccionada?

        // Genera la fecha completa combinando el día y la hora seleccionada
        final fullDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          slot.hour,
          slot.minute,
        );

        // Si el horario ya pasó (hora anterior al momento actual), se bloquea
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

        // Valida si el horario está tomado consultando Firestore
        return FutureBuilder<bool>(
          future: _appointmentService.isSlotTaken(widget.kineId, fullDateTime),
          builder: (context, snap) {
            final loading = snap.connectionState == ConnectionState.waiting;
            final taken = snap.data == true;
            // Mientras carga la validación de disponibilidad, muestra chip gris
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

            // Si el horario está tomado, lo muestra bloqueado y en rojo
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

            // Si el horario está disponible, permite seleccionarlo
            return _TimeChip(
              label: slot.format(context),
              selected: isSelected,
              onTap: () {
                setState(
                  () => _selectedTimeSlot = isSelected ? null : index,
                ); // Selecciona o deselecciona el horario
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

// Sub-Widgets
// Tarjeta básica para cada sección
class _SectionCard extends StatelessWidget {
  final String title; // Título de la sección (ej: "1. Selecciona el día")
  final Widget child; // Contenido que estará dentro de la tarjeta

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
          // Título de la sección (texto en negrita)
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -.1,
            ),
          ),
          const SizedBox(height: 10),
          child, // Contenido dinámico de la tarjeta (fecha, horarios, etc.)
        ],
      ),
    );
  }
}

//omponente visual que representa un horario individual
class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected; // Indica si está seleccionado por el usuario
  final VoidCallback? onTap; // Acción al tocarlo (o null si no se puede tocar)
  final Color border;
  final Color bg;
  final Color fg;
  final bool
  striked; //¿El texto va tachado? (usado para horarios no disponibles)

  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.border,
    required this.bg,
    required this.fg,
    this.striked = false, // Por defecto no está tachado
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
              // Si striked == true → texto tachado (usado para horarios tomados o pasados)
            ),
          ),
        ),
      ),
    );
  }
}
