import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kine_app/shared/widgets/app_dialog.dart';
import 'package:kine_app/features/auth/services/push_token_service.dart';

/// misma paleta que splash/login
class AppColors {
  static const blue = Color(0xFF47A5D6);
  static const orange = Color(0xFFE28825);
  static const greyText = Color(0xFF8A9397);
  static const border = Color(0xFFDDDDDD);
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _showPassword = false;
  String? _selectedGender;

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
        await user.sendEmailVerification();

        final userData = {
          'nombre_completo': _nameController.text.trim(),
          'nombre_usuario': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'edad': int.tryParse(_ageController.text.trim()),
          'sexo': _selectedGender,
          'tipo_usuario': _firestore.collection('tipo_usuario').doc('1'),
          'fecha_registro': FieldValue.serverTimestamp(),
          'plan': 'estandar',
          'perfilDestacado': false,
          'limitePacientes': 50,
        };

        await _firestore.collection('usuarios').doc(user.uid).set(userData);
        await PushTokenService().registerTokenForUser(user.uid);
        await _auth.signOut();

        if (!mounted) return;
        await showAppInfoDialog(
          context: context,
          icon: Icons.mark_email_read_rounded,
          title: '¡Registro exitoso!',
          content:
              'Te enviamos un correo de verificación. Revísalo antes de iniciar sesión.',
          confirmText: 'Ok',
        );
        if (mounted) Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String title;
      String message;
      IconData icon;

      if (e.code == 'weak-password') {
        title = 'Contraseña débil';
        message = 'La contraseña es demasiado corta (mínimo 6).';
        icon = Icons.lock_clock_rounded;
      } else if (e.code == 'email-already-in-use') {
        title = 'Correo ya registrado';
        message = 'Ya existe una cuenta con este correo.';
        icon = Icons.alternate_email_rounded;
      } else if (e.code == 'invalid-email') {
        title = 'Correo inválido';
        message = 'Revisa el formato del correo.';
        icon = Icons.email_outlined;
      } else {
        title = 'Error';
        message = e.message ?? 'Ocurrió un error inesperado.';
        icon = Icons.error_outline_rounded;
      }

      if (mounted) setState(() => _isLoading = false);

      await showAppErrorDialog(
        context: context,
        icon: icon,
        title: title,
        content: message,
      );
    } finally {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const inputRadius = 28.0;
    const fieldHeight = 56.0;

    InputBorder border([Color c = AppColors.border]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(inputRadius),
      borderSide: BorderSide(color: c, width: 1.3),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
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
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // acento naranja
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 46,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Ingresa tus datos\npara registrarte.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        height: 1.25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Completa los campos para crear tu perfil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.greyText,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 26),

                    _LabeledField(
                      height: fieldHeight,
                      controller: _nameController,
                      hintText: 'Nombre Completo*',
                      prefix: const Icon(Icons.person_outline),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'El nombre es obligatorio.'
                          : null,
                      borderBuilder: border,
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
                      borderBuilder: border,
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
                      borderBuilder: border,
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
                          color: Colors.black54,
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres.'
                          : null,
                      borderBuilder: border,
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
                      borderBuilder: border,
                    ),
                    const SizedBox(height: 14),

                    // 🔥 dropdown sin iconos en cada opción
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedGender,
                      onChanged: (v) => setState(() => _selectedGender = v),
                      validator: (v) =>
                          v == null ? 'El sexo es obligatorio.' : null,
                      items: _genders.map((g) {
                        return DropdownMenuItem<String>(
                          value: g,
                          child: Text(g), // <- solo texto
                        );
                      }).toList(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      borderRadius: BorderRadius.circular(20),
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        hintText: 'Selecciona tu sexo*',
                        prefixIcon: const Icon(
                          Icons.wc,
                        ), // <- aquí el único icono
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 18,
                        ),
                        enabledBorder: border(),
                        focusedBorder: border(AppColors.blue),
                        errorBorder: border(Colors.redAccent),
                        focusedErrorBorder: border(Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 26),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
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
                            : const Text(
                                'Registrarme',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                                color: AppColors.blue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
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
    );
  }
}

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
          focusedBorder: borderBuilder(AppColors.blue),
          errorBorder: borderBuilder(Colors.redAccent),
          focusedErrorBorder: borderBuilder(Colors.redAccent),
        ),
      ),
    );
  }
}
