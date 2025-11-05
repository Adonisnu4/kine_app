import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

// FLUTTER
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
  // Estado para almacenar el archivo seleccionado (FilePicker)
  PlatformFile? _selectedPlatformFile;
  String? _fileName;
  bool _isUploading = false;

  // Cliente de Supabase
  final supabase = Supabase.instance.client;

  // Cliente Firestore
  final firestore = FirebaseFirestore.instance;

  // Función para seleccionar el archivo
  Future<void> pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true, // Necesitamos los bytes para uploadBinary
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedPlatformFile = result.files.single;
        _fileName = result.files.single.name;
      });
    } else {
      // Usuario canceló la selección
      setState(() {
        _selectedPlatformFile = null;
        _fileName = null;
      });
    }
  }

  // Lógica de subida a Supabase
  Future<void> uploadFile() async {
    if (_selectedPlatformFile == null || _selectedPlatformFile!.bytes == null) {
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // 1. Obtener los bytes y la extensión
      final Uint8List fileBytes = _selectedPlatformFile!.bytes!;
      final String fileExtension = _selectedPlatformFile!.extension ?? 'dat';
      final String? userUid = FirebaseAuth.instance.currentUser?.uid;

      // 2. Definir la ruta de almacenamiento
      const String mainFolder = 'documentos_kinesiologo';
      final String uniqueFileName =
          '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final String storagePath = '$mainFolder/$userUid/$uniqueFileName';

      // 3. Subir el archivo
      final String fullPath = await supabase.storage
          .from('kine_app') // Nombre del bucket
          .uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 4. Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Archivo $_fileName subido con éxito')),
      );

      // 5. Obtener URL pública
      final String publicUrl = supabase.storage
          .from('kine_app')
          .getPublicUrl(storagePath);
      print(publicUrl);

      // 6. Guardar solicitud en Firestore
      await firestore.collection('solicitudes_kinesiologo').add({
        'usuario': userUid,
        'estado': 'pendiente',
        'fecha_solicitud': FieldValue.serverTimestamp(),
        'documento': publicUrl,
      });

      // 7. Limpiar estado
      setState(() {
        _selectedPlatformFile = null;
        _fileName = null;
      });
    } on StorageException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error de Storage: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error inesperado al subir: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

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
              // Botón de Seleccionar Archivo
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

              // Vista condicional del archivo seleccionado
              if (_isUploading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text("Subiendo archivo..."),
                  ],
                )
              else if (_selectedPlatformFile != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Indicador de archivo seleccionado
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

                    // Botón de Subir Archivo
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
