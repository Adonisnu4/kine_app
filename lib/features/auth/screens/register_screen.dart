// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 💡 IMPORTAMOS AMBOS TIPOS DE POPUP
import 'package:kine_app/shared/widgets/app_dialog.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // =======================
  // 1) Estado / controladores
  // =======================
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _selectedGender;
  bool _showPassword = false;

  final List<String> _genders = const [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no decirlo',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // =======================
  // 2) Helpers
  // =======================

  // (La función _showSnackBar ya no es necesaria)

  // =======================
  // 3) Lógica de registro (💡 MODIFICADA)
  // =======================
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = cred.user;
      if (user != null) {
        await user.sendEmailVerification(); // <- Async Gap

        final tipoUsuarioRef = _firestore
            .collection('tipo_usuario')
            .doc('1'); // Paciente por defecto

        final userData = {
          'nombre_completo': _nameController.text.trim(),
          'nombre_usuario': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'edad': int.tryParse(_ageController.text.trim()),
          'sexo': _selectedGender,
          'tipo_usuario': tipoUsuarioRef,
          'fecha_registro': FieldValue.serverTimestamp(),
          'plan': 'estandar',
          'perfilDestacado': false,
          'limitePacientes': 50,
        };

        await _firestore
            .collection('usuarios')
            .doc(user.uid)
            .set(userData); // <- Async Gap

        await _auth.signOut(); // <- Async Gap

        // 💡 --- CORRECCIÓN ASYNC GAP ---
        if (!mounted) return;

        // 1. Muestra el popup de éxito
        await showAppInfoDialog(
          context: context,
          icon: Icons.mark_email_read_rounded,
          title: '¡Registro Exitoso!',
          content:
              'Te enviamos un correo de verificación. Por favor, revisa tu bandeja de entrada y spam.',
          confirmText: 'Entendido',
        );

        // 2. Vuelve al login
        if (mounted) {
          // 💡 Doble chequeo por si acaso
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      // 💡 --- SECCIÓN DE ERROR MODIFICADA ---
      String title;
      String message;
      IconData icon;

      if (e.code == 'weak-password') {
        title = 'Contraseña Débil';
        message = 'La contraseña es demasiado débil (mínimo 6 caracteres).';
        icon = Icons.lock_clock_rounded;
      } else if (e.code == 'email-already-in-use') {
        title = 'Correo ya Existe';
        message = 'Ya existe una cuenta registrada con este correo.';
        icon = Icons.alternate_email_rounded;
      } else if (e.code == 'invalid-email') {
        title = 'Correo Inválido';
        message = 'El formato del correo electrónico es inválido.';
        icon = Icons.email_outlined;
      } else {
        title = 'Error Desconocido';
        message = 'Ocurrió un error inesperado. Por favor, inténtalo de nuevo.';
        icon = Icons.error_outline_rounded;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Muestra el POPUP de error
      await showAppErrorDialog(
        context: context,
        icon: icon, // 💡 Icono añadido
        title: title,
        content: message,
      );

      return;

      // 💡 --- FIN DE LA MODIFICACIÓN ---
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  // =======================
  // 4) UI (Sin cambios)
  // =======================
  @override
  Widget build(BuildContext context) {
    // Paleta base del login
    const inputRadius = 28.0;
    const fieldHeight = 56.0;

    InputBorder _border([Color c = const Color(0xFFDDDDDD)]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: c, width: 1.4),
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text(
          'Crear Nueva Cuenta',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 520,
              ), // columna estrecha
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Ingresa tus datos\npara registrarte.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---- Campos ----
                    _LabeledField(
                      height: fieldHeight,
                      controller: _nameController,
                      hintText: 'Nombre Completo*',
                      prefix: const Icon(Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El nombre es obligatorio.'
                          : null,
                      borderBuilder: _border,
                    ),
                    const SizedBox(height: 14),

                    _LabeledField(
                      height: fieldHeight,
                      controller: _usernameController,
                      hintText: 'Nombre de Usuario*',
                      prefix: const Icon(Icons.alternate_email),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'El nombre de usuario es obligatorio.';
                        }
                        if (v.trim().length < 4) {
                          return 'Debe tener al menos 4 caracteres.';
                        }
                        return null;
                      },
                      borderBuilder: _border,
                    ),
                    const SizedBox(height: 14),

                    _LabeledField(
                      height: fieldHeight,
                      controller: _emailController,
                      hintText: 'Correo electrónico*',
                      keyboardType: TextInputType.emailAddress,
                      prefix: const Icon(Icons.email_outlined),
                      validator: (v) {
                        final s = v?.trim() ?? '';
                        if (s.isEmpty || !s.contains('@') || !s.contains('.')) {
                          return 'Ingresa un correo válido.';
                        }
                        return null;
                      },
                      borderBuilder: _border,
                    ),
                    const SizedBox(height: 14),

                    _LabeledField(
                      height: fieldHeight,
                      controller: _passwordController,
                      hintText: 'Contraseña* (mín. 6 caracteres)',
                      prefix: const Icon(Icons.lock_outline),
                      obscureText: !_showPassword,
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres.'
                          : null,
                      borderBuilder: _border,
                    ),
                    const SizedBox(height: 14),

                    _LabeledField(
                      height: fieldHeight,
                      controller: _ageController,
                      hintText: 'Edad*',
                      keyboardType: TextInputType.number,
                      prefix: const Icon(Icons.numbers),
                      validator: (v) {
                        final age = int.tryParse((v ?? '').trim());
                        if (age == null || age < 1 || age > 120) {
                          return 'Ingresa una edad válida (1-120).';
                        }
                        return null;
                      },
                      borderBuilder: _border,
                    ),
                    const SizedBox(height: 14),

                    // Dropdown estilizado (campo)
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedGender,
                      onChanged: (v) => setState(() => _selectedGender = v),
                      validator: (v) =>
                          v == null ? 'El sexo es obligatorio.' : null,
                      items: _genders.map((g) {
                        return DropdownMenuItem<String>(
                          value: g,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.wc, size: 18),
                                const SizedBox(width: 10),
                                Text(g),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      menuMaxHeight: 360,
                      dropdownColor: Colors.white, // fondo del menú
                      borderRadius: BorderRadius.circular(
                        20,
                      ), // esquinas del menú
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Selecciona tu sexo*',
                        prefixIcon: const Icon(Icons.wc),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        enabledBorder: _border(),
                        focusedBorder: _border(Colors.black),
                        errorBorder: _border(Colors.redAccent),
                        focusedErrorBorder: _border(Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón negro full width
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text('Registrarme'),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Link sutil como en login
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text.rich(
                        TextSpan(
                          text: '¿Ya tienes una cuenta? ',
                          style: const TextStyle(color: Colors.black87),
                          children: const [
                            TextSpan(
                              text: 'Inicia sesión',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ), // negrita
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFDFDFD),
    );
  }
}

/*--------------------------
  Campo reutilizable estilizado
---------------------------*/
class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.controller,
    required this.hintText,
    required this.borderBuilder,
    this.prefix,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.height = 56,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final double height;
  final InputBorder Function([Color]) borderBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          enabledBorder: borderBuilder(),
          focusedBorder: borderBuilder(Colors.black),
          errorBorder: borderBuilder(Colors.redAccent),
          focusedErrorBorder: borderBuilder(Colors.redAccent),
        ),
      ),
    );
  }
}
