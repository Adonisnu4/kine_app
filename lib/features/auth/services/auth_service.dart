// Importa funcionalidades de Firebase Authentication
import 'package:firebase_auth/firebase_auth.dart';

// Utilidades de Flutter para identificar plataforma y para impresión de logs
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

// SDK para autenticación con Facebook
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// Firestore para persistencia de datos del usuario
import 'package:cloud_firestore/cloud_firestore.dart';

// SDK para autenticación con Google
import 'package:google_sign_in/google_sign_in.dart';

// Servicio propio para registrar y eliminar tokens de notificaciones push
import 'package:kine_app/features/auth/services/notification_tokens.dart';

/// Servicio centralizado de autenticación.
/// Gestiona inicio de sesión con email, Google, Facebook, registro de tokens
/// para notificaciones y cierre de sesión.
class AuthService {
  // Instancia principal de Firebase Authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Conexión a Firestore para guardar y consultar usuarios
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Configuración del inicio de sesión por Google
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // Servicio encargado del manejo de tokens FCM
  final PushTokenService _tokenService = PushTokenService();

  //INICIO DE SESIÓN CON CORREO Y CONTRASEÑA
  Future<UserCredential> signInWithEmail(String email, String password) async {
    // Realiza la autenticación tradicional mediante email y contraseña
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Registra el token de notificaciones FCM para el usuario autenticado
    await _tokenService.registerTokenForUser(userCred.user!.uid);

    return userCred;
  }

  // INICIO DE SESIÓN CON GOOGLE
  Future<UserCredential> signInWithGoogle() async {
    try {
      UserCredential userCred;

      // Flujo para aplicaciones Web
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCred = await _auth.signInWithPopup(googleProvider);
      }
      // Flujo para plataformas móviles
      else {
        // Abre el selector de cuenta de Google
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception("Inicio de sesión cancelado");
        }

        // Obtiene los tokens del usuario autenticado con Google
        final googleAuth = await googleUser.authentication;

        // Crea credenciales válidas para Firebase Authentication
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Completa el inicio de sesión en Firebase
        userCred = await _auth.signInWithCredential(credential);
      }

      // Verifica si el usuario existe y crea su documento en Firestore si es nuevo
      final user = userCred.user;
      if (user != null) {
        final userDoc = _firestore.collection('usuarios').doc(user.uid);
        final doc = await userDoc.get();

        if (!doc.exists) {
          await userDoc.set({
            'uid': user.uid,
            'nombre_completo': user.displayName ?? '',
            'email': user.email ?? '',
            'imagen_perfil': user.photoURL ?? '',
            'fecha_registro': FieldValue.serverTimestamp(),
            'provider': 'google',
            'tipo_usuario': _firestore.collection('tipo_usuario').doc('1'),
          });
        }

        // Registra el token FCM en la base de datos
        await _tokenService.registerTokenForUser(user.uid);
      }

      return userCred;
    } catch (e) {
      debugPrint("Error en Google Sign-In: $e");
      rethrow;
    }
  }

  // INICIO DE SESIÓN CON FACEBOOK
  Future<UserCredential> signInWithFacebook() async {
    try {
      UserCredential userCred;

      // Flujo para Web
      if (kIsWeb) {
        final facebookProvider = FacebookAuthProvider();
        userCred = await _auth.signInWithPopup(facebookProvider);
      }
      // Flujo para Android/iOS
      else {
        final LoginResult result = await FacebookAuth.instance.login();

        if (result.status == LoginStatus.success) {
          final AccessToken accessToken = result.accessToken!;
          final credential = FacebookAuthProvider.credential(
            accessToken.tokenString,
          );

          // Inicia sesión con credenciales de Facebook
          userCred = await _auth.signInWithCredential(credential);
        } else {
          throw Exception(result.message ?? 'Inicio de sesión cancelado');
        }
      }

      // Verificación y creación de usuario en Firestore si es necesario
      final user = userCred.user;
      if (user != null) {
        final userDoc = _firestore.collection('usuarios').doc(user.uid);
        final doc = await userDoc.get();

        if (!doc.exists) {
          await userDoc.set({
            'uid': user.uid,
            'nombre_completo': user.displayName ?? '',
            'email': user.email ?? '',
            'imagen_perfil': user.photoURL ?? '',
            'fecha_registro': FieldValue.serverTimestamp(),
            'provider': 'facebook',
            'tipo_usuario': _firestore.collection('tipo_usuario').doc('1'),
          });
        }

        // Registra el token FCM
        await _tokenService.registerTokenForUser(user.uid);
      }

      return userCred;
    } catch (e) {
      debugPrint("Error en Facebook Sign-In: $e");
      rethrow;
    }
  }

  //RECUPERACIÓN DE CONTRASEÑA
  Future<void> sendPasswordReset(String email) async {
    // Envía un correo electrónico con el enlace de recuperación de contraseña
    await _auth.sendPasswordResetEmail(email: email);
  }

  // CIERRE DE SESIÓN
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;

      // Elimina el token FCM asociado al usuario que cierra sesión
      if (user != null) {
        await _tokenService.removeTokenForUser(user.uid);
      }

      // Limpia sesiones externas en plataformas móviles
      if (!kIsWeb) {
        final bool isGoogleSigned = await _googleSignIn.isSignedIn();
        if (isGoogleSigned) {
          await _googleSignIn.disconnect();
          await _googleSignIn.signOut();
        }

        await FacebookAuth.instance.logOut();
      }

      // Cierra sesión en Firebase Authentication
      await _auth.signOut();
      debugPrint('Sesión cerrada correctamente');
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  // OBTENER USUARIO ACTUAL AUTENTICADO
  User? get currentUser => _auth.currentUser;
}
