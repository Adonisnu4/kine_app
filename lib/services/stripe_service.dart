// lib/services/stripe_service.dart
import 'dart:async'; // Para el 'Completer'
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 1. Crea una sesión de pago en Firestore
  /// Esto activa la extensión de Stripe para generar una URL de pago
  Future<String> createCheckoutSession(String priceId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado.");

    // Define la ruta del documento donde se creará la sesión
    // Asegúrate que 'customers' sea la colección que configuraste en la extensión
    final docRef = _firestore
        .collection('customers')
        .doc(user.uid)
        .collection('checkout_sessions')
        .doc(); // Firestore genera un ID nuevo

    print("Creando documento de checkout en: ${docRef.path}");

    // Completer nos permite esperar una respuesta del 'snapshot listener'
    final completer = Completer<String>();

    // Escucha en tiempo real los cambios en el documento que acabamos de crear
    // La extensión de Stripe editará este documento y añadirá la URL o un error
    final StreamSubscription subscription = docRef.snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        if (data != null) {
          // --- CASO ERROR ---
          // La extensión escribió un error
          if (data.containsKey('error')) {
            final error = data['error']['message'];
            print("Error creando checkout: $error");
            if (!completer.isCompleted) {
              completer.completeError(Exception("Error de Stripe: $error"));
            }
          }
          // --- CASO ÉXITO ---
          // La extensión escribió la URL de pago
          else if (data.containsKey('url')) {
            final String url = data['url'];
            print("URL de Checkout recibida: $url");
            if (!completer.isCompleted) {
              completer.complete(url); // Devuelve la URL exitosamente
            }
          }
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError(
            Exception("Error al escuchar snapshot: $error"),
          );
        }
      },
    );

    // Escribe la solicitud de pago en Firestore. ESTO ACTIVA LA EXTENSIÓN.
    await docRef.set({
      'price': priceId, // El ID del precio de Stripe (ej: price_1P...)
      'success_url':
          'https://kine-8c247.web.app/exito', // Página web a la que volver
      'cancel_url':
          'https://kine-8c247.web.app/cancelado', // Página web si cancela
      'mode': 'subscription', // Indica que es una suscripción
    });

    // Espera a que el 'listener' obtenga la URL
    final url = await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        subscription.cancel();
        throw TimeoutException(
          "Se agotó el tiempo de espera para la URL de Stripe.",
        );
      },
    );

    subscription.cancel(); // Deja de escuchar el documento
    return url;
  }

  /// 2. Abre la URL de pago en el navegador del dispositivo
  Future<void> launchStripeCheckout(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      // Abre la URL en el navegador externo (Chrome, Safari, etc.)
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo lanzar la URL de pago $url';
    }
  }

  /// 3. Verifica si el usuario actual tiene una suscripción Pro activa
  Future<bool> checkProSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) return false; // Si no está logueado, no es Pro

    try {
      // Busca en la subcolección 'subscriptions' del cliente
      final query = await _firestore
          .collection('customers') // Colección de la extensión
          .doc(user.uid) // Documento del usuario
          .collection('subscriptions') // Subcolección de suscripciones
          .where(
            'status',
            whereIn: ['active', 'trialing'],
          ) // Busca activas o en período de prueba
          .limit(1) // Solo necesitamos saber si existe al menos una
          .get();

      if (query.docs.isNotEmpty) {
        // ¡Encontró una suscripción activa!
        print("checkProSubscriptionStatus: Usuario ES Pro.");
        return true;
      } else {
        // No encontró ninguna
        print("checkProSubscriptionStatus: Usuario NO es Pro.");
        return false;
      }
    } catch (e) {
      print("Error en checkProSubscriptionStatus: $e");
      return false; // Asume que no es Pro si hay un error en la consulta
    }
  }
}
