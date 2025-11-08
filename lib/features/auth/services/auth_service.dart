import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kine_app/features/auth/services/notification_tokens.dart'; // 👈 Import del servicio de notificaciones

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final PushTokenService _tokenService =
      PushTokenService(); // 👈 Instancia del servicio

  // ===========================================================
  // 1️⃣ LOGIN CON CORREO Y CONTRASEÑA
  // ===========================================================
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 👇 Registra el token FCM para el usuario logueado
    await _tokenService.registerTokenForUser(userCred.user!.uid);

    return userCred;
  }

  // ===========================================================
  // 2️⃣ LOGIN CON GOOGLE
  // ===========================================================
  Future<UserCredential> signInWithGoogle() async {
    try {
      UserCredential userCred;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCred = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) throw Exception("Inicio de sesión cancelado");
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCred = await _auth.signInWithCredential(credential);
      }

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

        // 👇 Registra el token FCM
        await _tokenService.registerTokenForUser(user.uid);
      }

      return userCred;
    } catch (e) {
      debugPrint("⚠️ Error en Google Sign-In: $e");
      rethrow;
    }
  }

  // ===========================================================
  // 3️⃣ LOGIN CON FACEBOOK
  // ===========================================================
  Future<UserCredential> signInWithFacebook() async {
    try {
      UserCredential userCred;

      if (kIsWeb) {
        final facebookProvider = FacebookAuthProvider();
        userCred = await _auth.signInWithPopup(facebookProvider);
      } else {
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success) {
          final AccessToken accessToken = result.accessToken!;
          final credential = FacebookAuthProvider.credential(
            accessToken.tokenString,
          );
          userCred = await _auth.signInWithCredential(credential);
        } else {
          throw Exception(result.message ?? 'Inicio de sesión cancelado');
        }
      }

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

        // 👇 Registra el token FCM
        await _tokenService.registerTokenForUser(user.uid);
      }

      return userCred;
    } catch (e) {
      debugPrint("⚠️ Error en Facebook Sign-In: $e");
      rethrow;
    }
  }

  // ===========================================================
  // 4️⃣ RECUPERAR CONTRASEÑA
  // ===========================================================
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ===========================================================
  // 5️⃣ CERRAR SESIÓN
  // ===========================================================
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 👇 Elimina el token FCM del usuario al cerrar sesión
        await _tokenService.removeTokenForUser(user.uid);
      }

      if (!kIsWeb) {
        final bool isGoogleSigned = await _googleSignIn.isSignedIn();
        if (isGoogleSigned) {
          await _googleSignIn.disconnect();
          await _googleSignIn.signOut();
        }
        await FacebookAuth.instance.logOut();
      }

      await _auth.signOut();
      debugPrint('✅ Sesión cerrada correctamente');
    } catch (e) {
      debugPrint('⚠️ Error al cerrar sesión: $e');
    }
  }

  // ===========================================================
  // 6️⃣ USUARIO ACTUAL
  // ===========================================================
  User? get currentUser => _auth.currentUser;
}
