import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// FLUTTER (SUPABASE)
import 'package:supabase_flutter/supabase_flutter.dart';

// FIREBASE
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KineActivationScreen extends StatefulWidget {
  const KineActivationScreen({super.key});

  @override
  State<KineActivationScreen> createState() => _KineActivationScreenState();
}

class _KineActivationScreenState extends State<KineActivationScreen> {
  // Archivo seleccionado desde FilePicker
  PlatformFile? _selectedPlatformFile;
  String? _fileName;

  // Estado para indicar si se está subiendo el archivo
  bool _isUploading = false;

  // Cliente de Supabase para manejar el Storage
  final supabase = Supabase.instance.client;

  // Referencia a Firestore
  final firestore = FirebaseFirestore.instance;

  /// Permite seleccionar un archivo desde el dispositivo.
  /// Se aceptan extensiones: jpg, jpeg, png y pdf.
  /// Se requiere withData:true para obtener los bytes necesarios para subirlos.
  Future<void> pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // Necesario para obtener bytes del archivo
    );

    // Si el usuario selecciona archivo
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPlatformFile = result.files.single;
        _fileName = result.files.single.name;
      });
    } else {
      // Si cancela, se limpia el estado
      setState(() {
        _selectedPlatformFile = null;
        _fileName = null;
      });
    }
  }

  /// Sube el archivo seleccionado a Supabase Storage
  /// y crea una solicitud en Firestore para activar al usuario como kinesiólogo.
  Future<void> uploadFile() async {
    // Validación inicial
    if (_selectedPlatformFile == null || _selectedPlatformFile!.bytes == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Obtiene bytes del archivo
      final Uint8List fileBytes = _selectedPlatformFile!.bytes!;

      // Extensión del archivo
      final String fileExtension = _selectedPlatformFile!.extension ?? 'dat';

      // UID del usuario actual
      final String? userUid = FirebaseAuth.instance.currentUser?.uid;

      // Carpeta principal en Supabase Storage
      const String mainFolder = 'documentos_kinesiologo';

      // Nombre único basado en timestamp
      final String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // Ruta final del archivo dentro del bucket
      final String storagePath = '$mainFolder/$userUid/$uniqueFileName';

      // Subida efectiva del archivo a Supabase Storage
      final String fullPath = await supabase.storage
          .from('kine_app') // Nombre del bucket
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // Notifica éxito al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Archivo $_fileName subido con éxito')),
      );

      // Obtiene URL pública del archivo subido
      final String publicUrl = supabase.storage
          .from('kine_app')
          .getPublicUrl(storagePath);

      // Registra la solicitud en Firestore
      await firestore.collection('solicitudes_kinesiologo').add({
        'usuario': userUid,
        'estado': 'pendiente',
        'fecha_solicitud': FieldValue.serverTimestamp(),
        'documento': publicUrl,
      });

      // Limpia estado interno
      setState(() {
        _selectedPlatformFile = null;
        _fileName = null;
      });
    } on StorageException catch (e) {
      // Error específico del Storage de Supabase
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de Storage: ${e.message}')));
    } catch (e) {
      // Error general
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error inesperado al subir: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// Construcción visual de la pantalla.
  /// Muestra:
  /// - Botón para seleccionar archivo
  /// - Vista previa del archivo seleccionado
  /// - Botón para subir archivo a Supabase
  /// - Indicador de carga durante la subida
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Subir Documento de Kinesiólogo"),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón para seleccionar archivo del dispositivo
              ElevatedButton.icon(
                onPressed: _isUploading ? null : pickFile,
                icon: const Icon(Icons.folder_open),
                label: const Text("Seleccionar Archivo (JPG, PNG, PDF)"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Si está subiendo, muestra indicador
              if (_isUploading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Subiendo archivo..."),
                  ],
                )
              // Si ya hay un archivo seleccionado
              else if (_selectedPlatformFile != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vista del archivo seleccionado
                    Card(
                      elevation: 4,
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color: Colors.blue,
                              size: 30,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                _fileName ?? 'Archivo seleccionado',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Botón de subida a Supabase
                    ElevatedButton.icon(
                      onPressed: uploadFile,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text("Subir a Supabase Storage"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ],
                )
              // Cuando aún no se ha seleccionado archivo
              else
                const Text(
                  "Aún no se ha seleccionado ningún archivo para subir.",
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
