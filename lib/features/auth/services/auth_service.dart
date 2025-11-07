import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  // ===========================================================
  // 1️⃣ LOGIN CON CORREO Y CONTRASEÑA
  // ===========================================================
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ===========================================================
  // 2️⃣ LOGIN CON GOOGLE (CORREGIDO)
  // ===========================================================
  Future<UserCredential> signInWithGoogle() async {
    try {
      UserCredential userCred;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        userCred = await _auth.signInWithPopup(googleProvider);
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception("Inicio de sesión cancelado por el usuario");
        }
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

            // 🔥 ¡ESTA ES LA CORRECCIÓN!
            // Ahora guarda una Referencia, igual que tu pantalla de registro.
            'tipo_usuario': _firestore.collection('tipo_usuario').doc('1'),
          });
        }
      }
      return userCred;
    } catch (e) {
      debugPrint("⚠️ Error en Google Sign-In: $e");
      rethrow;
    }
  }

  // ===========================================================
  // 3️⃣ LOGIN CON FACEBOOK (CORREGIDO)
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
          throw Exception(
            result.message ?? 'Inicio de sesión con Facebook cancelado',
          );
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

            // 🔥 ¡ESTA ES LA CORRECCIÓN!
            'tipo_usuario': _firestore.collection('tipo_usuario').doc('1'),
          });
        }
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
  // 5️⃣ CERRAR SESIÓN (Versión "Forzada" contra caché)
  // ===========================================================
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        // 1. Revisa si Google está conectado
        final bool isGoogleSigned = await _googleSignIn.isSignedIn();

        if (isGoogleSigned) {
          // 2. Desconecta y revoca permisos PRIMERO
          await _googleSignIn.disconnect();
          // 3. Cierra sesión en la app
          await _googleSignIn.signOut();
        }

        // 4. Cierra sesión en Facebook
        await FacebookAuth.instance.logOut();
      }

      // 5. Cierra sesión en Firebase (SIEMPRE al final)
      await _auth.signOut();

      debugPrint('✅ Sesión cerrada correctamente');
    } catch (e) {
      debugPrint('⚠️ Error al cerrar sesión: $e');
    }
  }

  // ===========================================================
  // 6️⃣ OBTENER USUARIO ACTUAL
  // ===========================================================
  User? get currentUser => _auth.currentUser;
}
