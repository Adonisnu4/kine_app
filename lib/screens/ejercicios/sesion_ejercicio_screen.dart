import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class SesionEjercicioScreen extends StatefulWidget {
  final String ejecucionId;
  const SesionEjercicioScreen({super.key, required this.ejecucionId});

  @override
  State<SesionEjercicioScreen> createState() => _SesionEjercicioScreenState();
}

class _SesionEjercicioScreenState extends State<SesionEjercicioScreen> {
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  String _nombre = '';
  String _videoUrl = '';
  String _sesionNombre = '';

  // Nuevo estado para la finalización de la SESIÓN (no del plan completo)
  bool _isSessionCompletedAndFinished = false;

  /// ⏱️ Control del tiempo total de reproducción
  late Timer _durationTimer;
  Duration _totalPlayed = Duration.zero;
  Duration _targetDuration = Duration.zero;

  // Variables para mantener la posición actual y poder actualizar Firestore
  String? _currentExerciseKey;
  int _currentSessionIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void dispose() {
    if (mounted) _durationTimer.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  /// Obtiene el ejercicio actual y prepara el video
  Future<void> _loadExercise() async {
    setState(() {
      _isLoading = true;
      _videoController?.dispose();
      _videoController = null;
      _totalPlayed = Duration.zero;
      _isSessionCompletedAndFinished =
          false; // Resetear el estado de completado
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final ejecucionRef = firestore
          .collection('plan_tomados_por_usuarios')
          .doc(widget.ejecucionId);

      final ejecucionDoc = await ejecucionRef.get();

      if (!ejecucionDoc.exists) throw Exception('Ejecución no encontrada');

      final data = ejecucionDoc.data()!;
      final sesionActual = data['sesion_actual'] ?? 0;
      final sesiones = List<Map<String, dynamic>>.from(data['sesiones'] ?? []);

      // 1. Verificar si el plan ya terminó (por si acaso)
      if (sesionActual >= sesiones.length) {
        // En este punto, podríamos asumir que el plan anterior ya terminó
        // O simplemente cargar el último estado si es un plan multi-sesión y la app debe parar aquí.
        // Como el requerimiento es terminar la PANTALLA, solo cargamos la sesión actual.
      }

      final sesion = sesiones[sesionActual];
      final ejercicios = Map<String, dynamic>.from(sesion['ejercicios'] ?? {});
      final keys = ejercicios.keys.toList()..sort();

      // 2. Encontrar el primer ejercicio no completado en la sesión actual
      final currentKey = keys.firstWhere(
        (k) => !(ejercicios[k]?['completado'] ?? false),
        orElse: () => '', // Si todo está completado, orElse devuelve ''
      );

      // 3. Si todo en la sesión actual está completado, llama a _endSessionSuccess()
      if (currentKey.isEmpty) {
        // La sesión actual ha terminado.
        _endSessionSuccess(sesion['nombre'] ?? 'Sesión ${sesionActual + 1}');
        return;
      }

      final currentData = ejercicios[currentKey];
      if (currentData == null || currentData['ejercicio'] == null) {
        throw Exception('No hay referencia de ejercicio');
      }

      // 4. Cargar datos del ejercicio
      final DocumentReference ref = currentData['ejercicio'];
      final doc = await ref.get();
      if (!doc.exists) throw Exception('Ejercicio no encontrado');

      final ejercicioData = doc.data() as Map<String, dynamic>;
      final videoUrl = ejercicioData['video'] ?? '';
      final nombre = ejercicioData['nombre'] ?? 'Ejercicio sin nombre';

      // Corregido: Usando 'tiempo_segundos'
      final targetSeconds =
          currentData['tiempo_segundos'] as int? ?? 30; // Leer el tiempo

      if (videoUrl.isEmpty || !videoUrl.startsWith('http')) {
        throw Exception('URL de video no válida');
      }

      final sesionNombre =
          (sesion['nombre'] != null && (sesion['nombre'] as String).isNotEmpty)
          ? sesion['nombre']
          : 'Sesión ${sesionActual + 1}';

      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();

      /// 🔁 Escucha cuando el video termina (looping)
      controller.addListener(() {
        if (controller.value.position >= controller.value.duration) {
          if (_totalPlayed < _targetDuration) {
            controller.seekTo(Duration.zero);
            controller.play();
          }
        }
      });

      setState(() {
        _videoController = controller;
        _videoUrl = videoUrl;
        _nombre = nombre;
        _sesionNombre = sesionNombre;
        _targetDuration = Duration(seconds: targetSeconds);
        _isLoading = false;

        // Guardar la posición actual para el avance
        _currentExerciseKey = currentKey;
        _currentSessionIndex = sesionActual;
      });

      // Inicia la reproducción y el temporizador
      _videoController!.play();
      _startDurationTimer();
    } catch (e) {
      debugPrint('❌ Error cargando ejercicio: $e');
      setState(() {
        _isLoading = false;
        _nombre = 'Error al cargar ejercicio: ${e.toString()}';
      });
    }
  }

  /// Determina si todos los ejercicios en la sesión han sido completados.
  bool _isSessionCompleted(Map<String, dynamic> session) {
    final ejercicios = Map<String, dynamic>.from(session['ejercicios'] ?? {});
    return ejercicios.values.every((e) => e['completado'] == true);
  }

  /// 🚀 Marca el ejercicio actual como completado y avanza al siguiente o finaliza la sesión.
  Future<void> _completeExerciseAndAdvance() async {
    // Cancelar el temporizador
    if (_durationTimer.isActive) _durationTimer.cancel();
    _videoController?.pause();

    if (_currentExerciseKey == null || _currentSessionIndex == -1) {
      debugPrint(
        'Error: Clave de ejercicio o índice de sesión no establecido.',
      );
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore
          .collection('plan_tomados_por_usuarios')
          .doc(widget.ejecucionId);

      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('Documento no encontrado para actualizar.');
      }

      final data = doc.data()!;
      final sesiones = List<Map<String, dynamic>>.from(data['sesiones'] ?? []);
      final sesionActual = data['sesion_actual'] ?? 0;

      if (sesionActual != _currentSessionIndex) {
        // Protección: Si el índice actual no coincide con la base de datos, recargar
        return _loadExercise();
      }

      // 1. Marcar el ejercicio actual como completado (Localmente)
      final sesion = sesiones[sesionActual];
      final ejercicios = Map<String, dynamic>.from(sesion['ejercicios'] ?? {});

      if (ejercicios.containsKey(_currentExerciseKey)) {
        ejercicios[_currentExerciseKey]!['completado'] = true;
      }

      // 2. Verificar si la sesión actual ha finalizado
      final bool currentSessionCompleted = _isSessionCompleted(sesion);

      // 3. Preparar actualizaciones para Firestore
      final Map<String, dynamic> updates = {'sesiones': sesiones};

      // 4. Decidir el siguiente paso y aplicar la lógica de avance de sesión
      if (currentSessionCompleted) {
        sesiones[sesionActual]['completada'] = true;
        final nextSessionIndex = sesionActual + 1;
        final isPlanCompleted = nextSessionIndex >= sesiones.length;

        if (isPlanCompleted) {
          // ⭐ LÓGICA AGREGADA: El plan está 100% terminado
          updates['estado'] = 'terminado';
          updates['fecha_finalizacion'] = FieldValue.serverTimestamp();
        } else {
          // 🔑 ¡ACTUALIZACIÓN CLAVE! Avanzar al siguiente índice de sesión
          updates['sesion_actual'] = nextSessionIndex;
        }
      }

      // 5. Escribir TODOS los cambios en Firestore
      await docRef.update(updates);

      // 6. Realizar acciones posteriores a la actualización
      if (currentSessionCompleted) {
        _endSessionSuccess(sesion['nombre'] ?? 'Sesión ${sesionActual + 1}');
      } else {
        // Cargar el siguiente ejercicio dentro de la misma sesión
        _loadExercise();
      }
    } catch (e) {
      debugPrint('❌ Error al completar ejercicio y avanzar: $e');
    }
  }

  //Controla el tiempo total reproducido
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_videoController != null && _videoController!.value.isPlaying) {
        setState(() {
          _totalPlayed += const Duration(milliseconds: 500);
        });

        if (_totalPlayed >= _targetDuration && _targetDuration.inSeconds > 0) {
          _videoController!.pause();
          timer.cancel(); // Detener el temporizador de conteo

          _completeExerciseAndAdvance();
        }
      }
    });
  }

  /// 🏁 Lógica para el fin de la SESIÓN actual
  void _endSessionSuccess(String sessionName) {
    setState(() {
      _isLoading = false;
      _isSessionCompletedAndFinished = true;
      _sesionNombre = '¡Éxito! 🎉';
      _nombre = '$sessionName terminada.';
    });
    // La pantalla permanecerá en este estado hasta que el usuario decida salir.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_sesionNombre.isEmpty ? 'Ejercicio Actual' : _sesionNombre),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isSessionCompletedAndFinished
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _sesionNombre,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        // Cierra la pantalla de ejercicios al terminar la sesión
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'Volver',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _videoController == null || !_videoController!.value.isInitialized
          ? Center(
              child: Text(
                'No se pudo cargar el video: $_nombre',
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Ejercicio:  $_nombre", //Nombre del ejercicio
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple, width: 3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Controles de reproducción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_fill,
                            size: 60,
                            color: Colors.deepPurple,
                          ),
                          onPressed: () {
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
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(
                            Icons.stop_circle,
                            size: 50,
                            color: Colors.redAccent,
                          ),
                          onPressed: () {
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Indicador de progreso
                    LinearProgressIndicator(
                      value: _targetDuration.inSeconds > 0
                          ? _totalPlayed.inMilliseconds /
                                _targetDuration.inMilliseconds
                          : 0,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Texto de tiempo y duración objetivo
                    Text(
                      'Tiempo ejercitado: ${_totalPlayed.inSeconds}s / ${_targetDuration.inSeconds}s',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    // Mensaje de completado
                    if (_totalPlayed >= _targetDuration &&
                        _targetDuration.inSeconds > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Text(
                          '¡Objetivo alcanzado! Avanzando...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
