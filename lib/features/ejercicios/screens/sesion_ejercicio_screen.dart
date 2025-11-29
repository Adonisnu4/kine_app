import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:video_player/video_player.dart';

import 'dart:async';

// Pantalla que ejecuta una sesión de ejercicios
class SesionEjercicioScreen extends StatefulWidget {
  final String ejecucionId; // ID del documento en “plan_tomados_por_usuarios”

  const SesionEjercicioScreen({super.key, required this.ejecucionId});

  @override
  State<SesionEjercicioScreen> createState() => _SesionEjercicioScreenState();
}

class _SesionEjercicioScreenState extends State<SesionEjercicioScreen> {
  // Controlador del video actual
  VideoPlayerController? _videoController;

  // Indica si se está cargando la información
  bool _isLoading = true;

  // Información del ejercicio actual
  String _nombre = '';
  String _videoUrl = '';
  String _sesionNombre = '';

  // Estado que indica si toda la sesión está completada
  bool _isSessionCompletedAndFinished = false;

  // Timer para contar reproducción total del video
  late Timer _durationTimer;

  // Tiempo total reproducido en el ejercicio actual
  Duration _totalPlayed = Duration.zero;

  // Meta de tiempo que el usuario debe completar
  Duration _targetDuration = Duration.zero;

  // Identificador del ejercicio actual (clave dentro de la sesión)
  String? _currentExerciseKey;

  // Índice de la sesión dentro del arreglo "sesiones"
  int _currentSessionIndex = -1;

  // Colores internos (solo visual)
  static const _bg = Color(0xFFF6F6F7);
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

  @override
  void initState() {
    super.initState();

    // Cargar el primer ejercicio al crear el widget
    _loadExercise();
  }

  @override
  void dispose() {
    // Cancela el timer si está activo y se destruye la vista
    if (mounted) _durationTimer.cancel();

    // Libera el controlador de video
    _videoController?.dispose();

    super.dispose();
  }

  // CARGA DEL EJERCICIO

  /// Obtiene el ejercicio actual leyendo Firestore
  Future<void> _loadExercise() async {
    // Estado inicial de carga
    setState(() {
      _isLoading = true;
      _videoController?.dispose();
      _videoController = null;
      _totalPlayed = Duration.zero;
      _isSessionCompletedAndFinished = false;
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // Referencia al documento de ejecución del plan
      final ejecucionRef = firestore
          .collection('plan_tomados_por_usuarios')
          .doc(widget.ejecucionId);

      // Obtiene los datos completos del documento
      final ejecucionDoc = await ejecucionRef.get();

      if (!ejecucionDoc.exists) throw Exception('Ejecución no encontrada');

      final data = ejecucionDoc.data()!;

      // Sesión que se está ejecutando
      final sesionActual = data['sesion_actual'] ?? 0;

      // Lista de sesiones del plan
      final sesiones = List<Map<String, dynamic>>.from(data['sesiones'] ?? []);

      // Extrae la sesión actual
      final sesion = sesiones[sesionActual];

      // Lista de ejercicios de esta sesión
      final ejercicios = Map<String, dynamic>.from(sesion['ejercicios'] ?? {});

      // Ordena las claves de los ejercicios
      final keys = ejercicios.keys.toList()..sort();

      // Busca el primer ejercicio que no esté completado
      final currentKey = keys.firstWhere(
        (k) => !(ejercicios[k]?['completado'] ?? false),
        orElse: () => '',
      );

      // Si todos están completados, terminar la sesión
      if (currentKey.isEmpty) {
        _endSessionSuccess(sesion['nombre'] ?? 'Sesión ${sesionActual + 1}');
        return;
      }

      // Datos del ejercicio seleccionado
      final currentData = ejercicios[currentKey];

      if (currentData == null || currentData['ejercicio'] == null) {
        throw Exception('No hay referencia de ejercicio');
      }

      // Referencia al documento del ejercicio en la colección “ejercicios”
      final DocumentReference ref = currentData['ejercicio'];
      final doc = await ref.get();

      if (!doc.exists) throw Exception('Ejercicio no encontrado');

      final ejercicioData = doc.data() as Map<String, dynamic>;

      // URL del video
      final videoUrl = ejercicioData['video'] ?? '';

      // Nombre del ejercicio
      final nombre = ejercicioData['nombre'] ?? 'Ejercicio sin nombre';

      // Tiempo objetivo
      final targetSeconds = currentData['tiempo_segundos'] as int? ?? 30;

      if (videoUrl.isEmpty || !videoUrl.startsWith('http')) {
        throw Exception('URL de video no válida');
      }

      // Nombre de la sesión (si no tiene, usa Sesión N)
      final sesionNombre =
          (sesion['nombre'] != null && (sesion['nombre'] as String).isNotEmpty)
          ? sesion['nombre']
          : 'Sesión ${sesionActual + 1}';

      // Prepara el controlador de video
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();

      // Listener para detectar cuando el video termina y reiniciarlo si aún falta tiempo
      controller.addListener(() {
        if (controller.value.position >= controller.value.duration) {
          if (_totalPlayed < _targetDuration) {
            controller.seekTo(Duration.zero);
            controller.play();
          }
        }
      });

      // Guarda todo en el estado
      setState(() {
        _videoController = controller;
        _videoUrl = videoUrl;
        _nombre = nombre;
        _sesionNombre = sesionNombre;
        _targetDuration = Duration(seconds: targetSeconds);
        _isLoading = false;

        _currentExerciseKey = currentKey;
        _currentSessionIndex = sesionActual;
      });

      // Reproduce automáticamente y comienza a contar tiempo
      _videoController!.play();
      _startDurationTimer();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _nombre = 'Error al cargar ejercicio: ${e.toString()}';
      });
    }
  }

  // VERIFICACIÓN DE SESIONES

  /// Verifica si una sesión completa ya está finalizada
  bool _isSessionCompleted(Map<String, dynamic> session) {
    final ejercicios = Map<String, dynamic>.from(session['ejercicios'] ?? {});
    return ejercicios.values.every((e) => e['completado'] == true);
  }

  // MARCAR EJERCICIO

  /// Marca el ejercicio actual como completado y avanza
  Future<void> _completeExerciseAndAdvance() async {
    if (_durationTimer.isActive) _durationTimer.cancel();

    _videoController?.pause();

    // Si no hay clave o sesión válida, no continuar
    if (_currentExerciseKey == null || _currentSessionIndex == -1) {
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore
          .collection('plan_tomados_por_usuarios')
          .doc(widget.ejecucionId);

      final doc = await docRef.get();

      if (!doc.exists) throw Exception('Documento no encontrado');

      final data = doc.data()!;
      final sesiones = List<Map<String, dynamic>>.from(data['sesiones'] ?? []);
      final sesionActual = data['sesion_actual'] ?? 0;

      // Si alguien cambió el estado en Firestore, recargar
      if (sesionActual != _currentSessionIndex) {
        return _loadExercise();
      }

      // Marca el ejercicio como completado
      final sesion = sesiones[sesionActual];
      final ejercicios = Map<String, dynamic>.from(sesion['ejercicios'] ?? {});

      if (ejercicios.containsKey(_currentExerciseKey)) {
        ejercicios[_currentExerciseKey]!['completado'] = true;
      }

      // Verificar si la sesión completa está terminada
      final bool currentSessionCompleted = _isSessionCompleted(sesion);

      // Preparar actualizaciones
      final Map<String, dynamic> updates = {'sesiones': sesiones};

      if (currentSessionCompleted) {
        sesiones[sesionActual]['completada'] = true;

        final nextSessionIndex = sesionActual + 1;

        final isPlanCompleted = nextSessionIndex >= sesiones.length;

        if (isPlanCompleted) {
          updates['estado'] = 'terminado';
          updates['fecha_finalizacion'] = FieldValue.serverTimestamp();
        } else {
          updates['sesion_actual'] = nextSessionIndex;
        }
      }

      // Guardar datos actualizados
      await docRef.update(updates);

      // Redirigir según corresponda
      if (currentSessionCompleted) {
        _endSessionSuccess(sesion['nombre'] ?? 'Sesión ${sesionActual + 1}');
      } else {
        _loadExercise();
      }
    } catch (e) {
      debugPrint('Error al avanzar ejercicio: $e');
    }
  }

  //  CONTROL DEL TIEMPO

  /// Inicia el contador de ejecución del ejercicio
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_videoController != null && _videoController!.value.isPlaying) {
        setState(() {
          _totalPlayed += const Duration(milliseconds: 500);
        });

        if (_totalPlayed >= _targetDuration && _targetDuration.inSeconds > 0) {
          _videoController!.pause();
          timer.cancel();
          _completeExerciseAndAdvance();
        }
      }
    });
  }

  // ======================= FIN DE SESIÓN ================================

  /// Marca que la sesión actual se completó correctamente
  void _endSessionSuccess(String sessionName) {
    setState(() {
      _isLoading = false;
      _isSessionCompletedAndFinished = true;
      _sesionNombre = 'Sesión completada';
      _nombre = sessionName;
    });
  }

  // ======================= UI PRINCIPAL ================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        title: Text(_sesionNombre.isEmpty ? 'Sesión' : _sesionNombre),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _isSessionCompletedAndFinished
          ? _buildSessionCompletedUI()
          : _videoController == null || !_videoController!.value.isInitialized
          ? _buildVideoErrorUI()
          : _buildVideoPlayerUI(),
    );
  }

  // ======================= UI: VIDEO ERROR ================================

  Widget _buildVideoErrorUI() {
    return Center(
      child: Text(
        'No se pudo cargar el video: $_nombre',
        style: const TextStyle(color: Colors.red),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ======================= UI: SESIÓN COMPLETADA ==========================

  Widget _buildSessionCompletedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Sesión completada',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(_nombre, textAlign: TextAlign.center),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _blue, width: 1.2),
                        foregroundColor: _blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 46),
                      ),
                      child: const Text('Volver'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadExercise,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(0, 46),
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================= UI: VIDEO Y CONTROLES ==========================

  Widget _buildVideoPlayerUI() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          children: [
            // Línea decorativa
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

            Text(
              "Ejercicio:  $_nombre",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _blue,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 14),

            // Tarjeta del video
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: _videoController!.value.aspectRatio,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Controles del video
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón play/pause
                Material(
                  color: _blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 2,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_videoController!.value.isPlaying) {
                          _videoController!.pause();
                        } else {
                          if (_totalPlayed < _targetDuration) {
                            _videoController!.play();
                          }
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(32),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // Botón stop
                Material(
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                    side: BorderSide(color: Colors.red.shade500, width: 2),
                  ),
                  child: InkWell(
                    onTap: () {
                      _videoController!.seekTo(Duration.zero);
                      _videoController!.pause();

                      if (_durationTimer.isActive) {
                        _durationTimer.cancel();
                        _startDurationTimer();
                      }

                      setState(() {
                        _totalPlayed = Duration.zero;
                      });
                    },
                    borderRadius: BorderRadius.circular(32),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Icon(
                        Icons.stop_rounded,
                        size: 30,
                        color: Colors.red.shade500,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Barra de progreso
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _targetDuration.inSeconds > 0
                    ? _totalPlayed.inMilliseconds /
                          _targetDuration.inMilliseconds
                    : 0,
                minHeight: 8,
                backgroundColor: Colors.black12,
                valueColor: const AlwaysStoppedAnimation<Color>(_blue),
              ),
            ),

            const SizedBox(height: 10),

            // Texto del progreso
            Text(
              'Tiempo ejercitado: ${_totalPlayed.inSeconds}s / ${_targetDuration.inSeconds}s',
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            if (_totalPlayed >= _targetDuration)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Text(
                  'Objetivo alcanzado. Avanzando.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
