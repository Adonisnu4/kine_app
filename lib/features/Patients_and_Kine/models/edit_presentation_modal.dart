import 'package:flutter/material.dart';

// Record que representa los datos profesionales del kinesiólogo.
// Es utilizado en el perfil.
typedef PresentationData = ({
  String specialization, // Especialidad principal
  String experience, // Años de experiencia
  String presentation, // Carta descriptiva
});

// Modal que permite editar la presentación profesional del kinesiólogo
class EditPresentationModal extends StatefulWidget {
  final PresentationData initialData; // Datos iniciales a mostrar
  final Function(PresentationData) onSave; // Callback a guardar

  const EditPresentationModal({
    super.key,
    required this.initialData,
    required this.onSave,
  });

  @override
  State<EditPresentationModal> createState() => _EditPresentationModalState();
}

class _EditPresentationModalState extends State<EditPresentationModal> {
  // Paleta de colores consistente con el resto de la app
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

  // Controladores de texto para manejar los campos del modal
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _presentationController;

  // Controla si se está guardando
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Carga los valores iniciales que vienen del perfil
    _specializationController = TextEditingController(
      text: widget.initialData.specialization,
    );

    _experienceController = TextEditingController(
      text: widget.initialData.experience,
    );

    _presentationController = TextEditingController(
      text: widget.initialData.presentation,
    );
  }

  @override
  void dispose() {
    // Libera memoria cuando el widget se elimina
    _specializationController.dispose();
    _experienceController.dispose();
    _presentationController.dispose();
    super.dispose();
  }

  // Construye una decoración estándar para los TextField
  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    int radius = 14,
  }) {
    return InputDecoration(
      labelText: label, // etiqueta arriba del campo
      hintText: hint, // ejemplo gris
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

      // Borde normal
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.toDouble()),
        borderSide: const BorderSide(color: _border),
      ),

      // Borde cuando no está enfocado
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.toDouble()),
        borderSide: const BorderSide(color: _border),
      ),

      // Borde cuando está enfocado
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.toDouble()),
        borderSide: const BorderSide(color: _blue, width: 1.3),
      ),

      labelStyle: const TextStyle(fontSize: 13.5),
    );
  }

  // Maneja el flujo de guardado al presionar el botón
  Future<void> _handleSave() async {
    final newPresentation = _presentationController.text.trim();
    final newSpecialization = _specializationController.text.trim();
    final newExperience = _experienceController.text.trim();

    // Validación básica: no permitir guardar campos vacíos
    if (newPresentation.isEmpty ||
        newSpecialization.isEmpty ||
        newExperience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios.')),
      );
      return;
    }

    // Marca que se está guardando
    setState(() => _isSaving = true);

    // Crea la estructura final usando el record
    final dataToSave = (
      specialization: newSpecialization,
      experience: newExperience,
      presentation: newPresentation,
    );

    // Llama al callback que viene desde el perfil
    await widget.onSave(dataToSave);

    // Verifica que la vista siga montada antes de cerrar
    if (!mounted) return;

    // Cierra el modal
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Detecta cuánto ocupa el teclado para ajustar el padding inferior
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPadding + 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra superior decorativa tipo "handle"
              Center(
                child: Container(
                  width: 46,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),

              // Encabezado del modal
              Row(
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      color: _blue.withOpacity(.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.badge_outlined,
                      color: _orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Administrar Datos Profesionales',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -.1,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              const Divider(height: 28),

              // Campo: Especialidad principal
              TextField(
                controller: _specializationController,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'Especialidad principal',
                  hint: 'Ej: Kinesiología deportiva',
                ),
              ),

              const SizedBox(height: 12),

              // Campo: Años de experiencia
              TextField(
                controller: _experienceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'Años de experiencia',
                  hint: 'Ej: 5',
                ),
              ),

              const SizedBox(height: 12),

              // Campo: Carta de presentación
              TextField(
                controller: _presentationController,
                maxLines: 7,
                minLines: 5,
                decoration: _fieldDecoration(
                  label: 'Carta de presentación (detalle)',
                  hint: 'Describe tu experiencia, formaciones y foco clínico.',
                  radius: 16,
                ),
              ),

              const SizedBox(height: 20),

              // Botón de guardar
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_outlined, size: 20),

                  label: Text(
                    _isSaving ? 'Guardando...' : 'Guardar y publicar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.05,
                    ),
                  ),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
