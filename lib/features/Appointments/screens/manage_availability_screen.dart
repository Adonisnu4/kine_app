// lib/screens/manage_availability_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/services/availability_service.dart'; // Importa el servicio
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // Necesitas este paquete

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() =>
      _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();
  // Se usa el operador null-aware '!' ya que esta pantalla solo debe ser accesible por un usuario autenticado
  final String _currentKineId = FirebaseAuth.instance.currentUser!.uid;

  DateTime _focusedDay = DateTime.now(); // Día/Mes visible en el calendario
  DateTime _selectedDay = DateTime.now(); // Día seleccionado por el Kine

  // Horarios base (9-12 y 14-17)
  final List<TimeOfDay> _baseTimeSlots = List.generate(9, (index) {
    int hour = index < 4
        ? 9 +
              index // 9, 10, 11, 12
        : 14 + (index - 4); // 14, 15, 16, 17
    return TimeOfDay(hour: hour, minute: 0);
  });

  // Almacena los horarios seleccionados ("HH:mm") para el día _selectedDay
  Set<String> _selectedSlots = {};
  bool _isLoading =
      false; // Indica si se está cargando la disponibilidad del día
  bool _isSaving =
      false; // Indica si se está guardando la disponibilidad del día
  bool _isSavingWeek =
      false; // Indica si se está guardando la disponibilidad de la semana

  @override
  void initState() {
    super.initState();
    // Asegura que el día inicial sea Lunes a Viernes
    _selectedDay = _findNextAvailableWorkDay(DateTime.now());
    _focusedDay = _selectedDay; // Enfoca el calendario en el día seleccionado
    _loadAvailabilityForSelectedDay(); // Carga los horarios para ese día
  }

  // Encuentra el próximo día laboral (Lunes a Viernes) a partir de una fecha
  DateTime _findNextAvailableWorkDay(DateTime date) {
    DateTime tempDate = date;
    // Avanza día a día hasta que no sea Sábado (6) ni Domingo (7)
    while (tempDate.weekday == DateTime.saturday ||
        tempDate.weekday == DateTime.sunday) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return tempDate;
  }

  // Carga la disponibilidad guardada en Firestore para el _selectedDay
  Future<void> _loadAvailabilityForSelectedDay() async {
    if (!mounted) return; // Si el widget se desmontó, salir inmediatamente

    setState(() {
      _isLoading = true;
      _selectedSlots = {}; // Limpiar slots antes de cargar
    }); // Muestra indicador de carga

    try {
      // Llama al servicio para obtener la lista de strings "HH:mm" guardados
      final savedSlots = await _availabilityService.getSavedAvailability(
        _currentKineId,
        _selectedDay,
      );

      if (!mounted) return; // Doble verificación antes de setState

      // Actualiza el estado con los slots encontrados
      setState(() {
        _selectedSlots = Set.from(savedSlots); // Convierte la lista a Set
      });
    } catch (e) {
      print("Error cargando disponibilidad: $e");
      if (!mounted) return; // Doble verificación
      // Muestra error si falla la carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Muestra mensaje de error
          content: Text('Error al cargar disponibilidad: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Oculta indicador
        });
      }
    }
  }

  // Guarda los _selectedSlots actuales para el _selectedDay en Firestore
  Future<void> _saveAvailabilityForSelectedDay() async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    }); // Activa indicador en botón AppBar

    try {
      // Convierte el Set a List y ordena antes de guardar
      final List<String> slotsToSave = _selectedSlots.toList()..sort();

      // Llama al servicio para guardar
      await _availabilityService.setAvailability(
        kineId: _currentKineId,
        date: _selectedDay,
        availableSlots: slotsToSave,
      );

      if (!mounted) return; // Doble verificación antes de interactuar con UI

      // Muestra mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disponibilidad guardada para este día.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error guardando disponibilidad del día: $e");
      if (!mounted) return; // Verificar antes de manipular el UI
      // Muestra mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false; // Desactiva indicador
        });
      }
    }
  }

  /// Guarda los slots actualmente seleccionados para Lunes a Viernes de la semana de _selectedDay
  Future<void> _saveAvailabilityForWeek() async {
    if (!mounted) return; // Verificar antes de manipular el UI

    // 1. Verifica si hay horarios seleccionados para aplicar
    if (_selectedSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona al menos un horario antes de aplicar a la semana.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 2. Pide confirmación al Kine
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aplicar a la Semana'),
        content: Text(
          'Esto aplicará los ${_selectedSlots.length} horarios seleccionados actualmente a todos los días de Lunes a Viernes de esta semana (empezando el ${DateFormat('dd/MM', 'es_ES').format(_getMonday(_selectedDay))}). ¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Aplicar a Semana'), // Texto del botón
            style: TextButton.styleFrom(foregroundColor: Colors.teal),
          ),
        ],
      ),
    );

    if (confirm != true) return; // Si el Kine cancela
    if (!mounted) return; // Verificar si el dialog tardó en responder

    setState(() {
      _isSavingWeek = true;
    }); // Activa indicador en el botón "Aplicar Semana"

    try {
      // Prepara la lista ordenada de slots a guardar
      final List<String> slotsToSave = _selectedSlots.toList()..sort();
      // Calcula el Lunes correspondiente al _selectedDay
      DateTime monday = _getMonday(_selectedDay);

      // Crea una lista para guardar todas las operaciones de escritura a Firestore
      List<Future> saveFutures = [];
      // Itera de Lunes (i=0) a Viernes (i=4)
      for (int i = 0; i < 5; i++) {
        DateTime currentWeekday = monday.add(Duration(days: i));
        // Añade la operación de guardado para cada día hábil a la lista de Futuros
        saveFutures.add(
          _availabilityService.setAvailability(
            kineId: _currentKineId,
            date: currentWeekday,
            availableSlots: slotsToSave, // Usa los mismos slots seleccionados
          ),
        );
      }
      // Espera a que TODAS las operaciones de guardado terminen
      await Future.wait(saveFutures);

      if (!mounted) return; // Verificar después de la operación await

      // Muestra mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Disponibilidad aplicada a Lunes-Viernes de esta semana.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error guardando disponibilidad semanal: $e");
      if (!mounted) return; // Verificar antes de manipular el UI
      // Muestra mensaje de error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aplicar a la semana: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Siempre desactiva el indicador del botón "Aplicar Semana"
      if (mounted) {
        setState(() {
          _isSavingWeek = false;
        });
      }
    }
  }

  // Helper para obtener el Lunes de la semana de una fecha dada
  DateTime _getMonday(DateTime date) {
    // weekday devuelve 1 para Lunes, 7 para Domingo
    int daysToSubtract = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: daysToSubtract));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Disponibilidad'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          // Botón para guardar SOLO EL DÍA SELECCIONADO
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              // Deshabilitado si está cargando, guardando día o semana
              onPressed: (_isLoading || _isSaving || _isSavingWeek)
                  ? null
                  : _saveAvailabilityForSelectedDay,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'GUARDAR DÍA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ), // Texto clarificado
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Calendario Semanal ---
          TableCalendar(
            locale: 'es_ES', // Español
            firstDay: DateTime.now().subtract(
              const Duration(days: 30),
            ), // Rango hacia atrás
            lastDay: DateTime.now().add(
              const Duration(days: 90),
            ), // Rango hacia adelante
            focusedDay: _focusedDay, // Día/Semana visible
            selectedDayPredicate: (day) =>
                isSameDay(_selectedDay, day), // Marca el día seleccionado
            calendarFormat:
                CalendarFormat.week, // Muestra solo una semana a la vez
            startingDayOfWeek:
                StartingDayOfWeek.monday, // Semana empieza en Lunes
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ), // Estilo cabecera
            calendarStyle: const CalendarStyle(
              // Estilos de los días
              todayDecoration: BoxDecoration(
                color: Colors.tealAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
            ),
            // Filtro para no poder seleccionar fines de semana
            enabledDayPredicate: (day) =>
                day.weekday != DateTime.saturday &&
                day.weekday != DateTime.sunday,
            // Callback cuando se selecciona un día diferente
            onDaySelected: (selectedDay, focusedDay) {
              // Ignora si se intenta seleccionar Sábado o Domingo
              if (selectedDay.weekday == DateTime.saturday ||
                  selectedDay.weekday == DateTime.sunday)
                return;

              // Si se selecciona un día válido y diferente al actual
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  // Actualiza el estado
                  _selectedDay = selectedDay;
                  _focusedDay =
                      focusedDay; // Enfoca el calendario en el nuevo día/semana
                  // No limpiamos _selectedSlots aquí, se limpiará en _loadAvailabilityForSelectedDay
                });
                _loadAvailabilityForSelectedDay(); // Carga la disponibilidad del nuevo día
              }
            },
            // Callback cuando cambia la semana visible
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay; // Actualiza el foco
            },
          ),
          const Divider(height: 1), // Línea divisoria
          Padding(
            // Texto indicando el día seleccionado
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: Text(
              'Selecciona los horarios para:\n${DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(_selectedDay)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
          // --- Lista de Horarios (Checkboxes) ---
          Expanded(
            // Ocupa el espacio restante
            child:
                _isLoading // Muestra indicador si está cargando los horarios del día
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : ListView.builder(
                    // Lista de horarios seleccionables
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount:
                        _baseTimeSlots.length, // Usa la lista base de horarios
                    itemBuilder: (context, index) {
                      final timeSlot = _baseTimeSlots[index];
                      // Convierte TimeOfDay a formato "HH:mm" para compararlo con el Set
                      final slotString =
                          '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}';
                      // Revisa si este horario está en el Set de seleccionados
                      final bool isSelected = _selectedSlots.contains(
                        slotString,
                      );

                      // Crea un Checkbox para cada horario
                      return CheckboxListTile(
                        title: Text(
                          // Muestra la hora
                          timeSlot.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                        value:
                            isSelected, // Estado del checkbox (marcado/desmarcado)
                        onChanged: (bool? newValue) {
                          // Callback al cambiar el estado
                          setState(() {
                            // Actualiza el Set _selectedSlots
                            if (newValue == true) {
                              _selectedSlots.add(slotString);
                            } // Añade si se marca
                            else {
                              _selectedSlots.remove(slotString);
                            } // Quita si se desmarca
                          });
                        },
                        activeColor:
                            Colors.teal, // Color del check cuando está marcado
                      );
                    },
                  ),
          ),
          // --- Botón para Aplicar a la Semana ---
          if (!_isLoading) // No mostrar si está cargando los slots iniciales
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                16,
              ), // Padding alrededor del botón
              child: ElevatedButton.icon(
                icon:
                    _isSavingWeek // Muestra indicador si está guardando la semana
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calendar_view_week, size: 20),
                label: Text(
                  _isSavingWeek
                      ? 'Aplicando...'
                      : 'Aplicar Horarios a L-V de esta Semana',
                ),
                // Deshabilitado si carga, guarda día o guarda semana
                onPressed: (_isLoading || _isSaving || _isSavingWeek)
                    ? null
                    : _saveAvailabilityForWeek,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700, // Color naranja
                  foregroundColor: Colors.white,
                  minimumSize: const Size(
                    double.infinity,
                    45,
                  ), // Ancho completo
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
