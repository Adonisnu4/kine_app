import 'package:flutter/material.dart';

/// DIALOGO 1: Confirmación (Sí / No)
/// Muestra un diálogo con dos opciones: Confirmar o Cancelar.
/// Útil para eliminar, confirmar acciones, guardar, salir, etc.
///
/// ➤ Retorna un Future<bool?>:
///     true  → el usuario confirmó
///     false → el usuario canceló
///     null  → si se cierra de otro modo
Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required IconData icon, // ícono grande superior
  required String title, // título del diálogo
  required String content, // texto descriptivo
  required String confirmText, // texto del botón "confirmar"
  String cancelText = 'Cancelar', // texto del botón cancelar
  bool isDestructive = false, // cambia el color (rojo si es acción peligrosa)
}) {
  // Si es acción peligrosa → color rojo, si no → verde
  final Color themeColor = isDestructive
      ? Colors.red.shade700
      : Colors.teal.shade700;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),

      // Ícono principal
      icon: Icon(icon, color: themeColor, size: 48),

      // Título estilizado
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: themeColor,
        ),
      ),

      // Contenido
      content: Text(
        content,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),

      // Botones
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actionsAlignment: MainAxisAlignment.center,
      actions: <Widget>[
        // Botón cancelar
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(
            cancelText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),

        // Botón confirmar
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: themeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    ),
  );
}

/// ============================================================================
/// DIALOGO 2: Información (Verde)
/// ============================================================================
/// Ideal para mostrar mensajes informativos como:
/// - "Tu plan fue actualizado"
/// - "Tu cita fue creada correctamente"
Future<void> showAppInfoDialog({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String content,
  String confirmText = 'Entendido',
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // no se puede cerrar tocando afuera
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),

      icon: Icon(icon, color: Colors.teal.shade700, size: 48),

      title: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade700,
        ),
      ),

      content: Text(
        content,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),

      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

      // Botón de cerrar
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    ),
  );
}

/// ============================================================================
/// DIALOGO 3: Error (Rojo)
/// ============================================================================
/// Ideal para:
/// - Error al iniciar sesión
/// - Error de Firestore
/// - Fallos de validación
Future<void> showAppErrorDialog({
  required BuildContext context,
  required IconData icon, // ícono recibido
  required String title,
  required String content,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),

      // Ícono rojo
      icon: Icon(icon, color: Colors.red.shade700, size: 48),

      // Título
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.red.shade700,
        ),
      ),

      // Cuerpo
      content: Text(
        content,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),

      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text(
            'Entendido',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    ),
  );
}

/// ============================================================================
/// DIALOGO 4: Advertencia (Naranjo)
/// ============================================================================
/// Útil para:
/// - "Tu suscripción está por expirar"
/// - "No tienes permisos para esta acción"
/// - "Faltan datos importantes"
Future<void> showAppWarningDialog({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String content,
}) {
  final Color warningColor = Colors.orange.shade800;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),

      icon: Icon(icon, color: warningColor, size: 48),

      title: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: warningColor,
        ),
      ),

      content: Text(
        content,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge,
      ),

      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: warningColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text(
            'Entendido',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    ),
  );
}
