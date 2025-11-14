import 'package:flutter/material.dart';

// record que usas en el perfil
typedef PresentationData = ({
  String specialization,
  String experience,
  String presentation,
});

class EditPresentationModal extends StatefulWidget {
  final PresentationData initialData;
  final Function(PresentationData) onSave;

  const EditPresentationModal({
    super.key,
    required this.initialData,
    required this.onSave,
  });

  @override
  State<EditPresentationModal> createState() => _EditPresentationModalState();
}

class _EditPresentationModalState extends State<EditPresentationModal> {
  // paleta que venimos usando
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _presentationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _specializationController =
        TextEditingController(text: widget.initialData.specialization);
    _experienceController =
        TextEditingController(text: widget.initialData.experience);
    _presentationController =
        TextEditingController(text: widget.initialData.presentation);
  }

  @override
  void dispose() {
    _specializationController.dispose();
    _experienceController.dispose();
    _presentationController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    int radius = 14,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.toDouble()),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.toDouble()),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.toDouble()),
        borderSide: const BorderSide(color: _blue, width: 1.3),
      ),
      labelStyle: const TextStyle(fontSize: 13.5),
    );
  }

  Future<void> _handleSave() async {
    final newPresentation = _presentationController.text.trim();
    final newSpecialization = _specializationController.text.trim();
    final newExperience = _experienceController.text.trim();

    if (newPresentation.isEmpty ||
        newSpecialization.isEmpty ||
        newExperience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los campos son obligatorios.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final dataToSave = (
      specialization: newSpecialization,
      experience: newExperience,
      presentation: newPresentation,
    );

    await widget.onSave(dataToSave);

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
              // handle
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
              // Especialidad
              TextField(
                controller: _specializationController,
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(
                  label: 'Especialidad principal',
                  hint: 'Ej: Kinesiología deportiva',
                ),
              ),
              const SizedBox(height: 12),
              // Años de experiencia
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
              // Carta
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
              // botón
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
