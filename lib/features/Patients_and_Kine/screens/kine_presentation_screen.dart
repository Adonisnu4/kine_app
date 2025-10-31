// lib/screens/kine_presentation_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/screens/booking_screen.dart'; // Importa pantalla de agendar
// --- 👇 1. ASEGÚRATE QUE ESTE IMPORT ESTÉ DESCOMENTADO Y LA RUTA SEA CORRECTA 👇 ---
import 'package:kine_app/features/Chat/screens/chat_screen.dart'; // Importa tu pantalla de chat

class KinePresentationScreen extends StatelessWidget {
  final String kineId;
  final Map<String, String> kineData; // Datos ya cargados desde el directorio

  const KinePresentationScreen({
    super.key,
    required this.kineId,
    required this.kineData, // Es obligatorio
  });

  // Navega a la pantalla de agendamiento
  void _navigateToBooking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BookingScreen(kineId: kineId, kineNombre: kineData['name']!),
      ),
    );
  }

  /// Navega a la pantalla de chat con este Kine
  void _navigateToChat(BuildContext context) {
    // --- 👇 2. CÓDIGO DE NAVEGACIÓN REAL (DESCOMENTADO) 👇 ---
    Navigator.push(
      context,
      MaterialPageRoute(
        // Asegúrate que tu ChatScreen reciba 'receiverId' y 'receiverName'
        builder: (context) => ChatScreen(
          receiverId: kineId, // Usa el kineId de esta pantalla
          receiverName: kineData['name']!, // Usa el nombre de kineData
        ),
      ),
    );
    // --- FIN CÓDIGO DE NAVEGACIÓN ---

    /* // Comenta o elimina el placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando al chat con ${kineData['name'] ?? 'Kine'}...')),
    );
    */
  }

  @override
  Widget build(BuildContext context) {
    // Extrae los datos del mapa kineData para facilitar el acceso
    final String kineName = kineData['name'] ?? 'Kinesiólogo';
    final String kineTitle = kineData['specialization'] ?? 'Especialista';
    final String kinePhotoUrl =
        kineData['photoUrl'] ??
        'https://via.placeholder.com/150'; // Placeholder
    final String kinePresentation =
        kineData['presentation'] ?? 'No hay presentación disponible.';
    final String kineExperience = kineData['experience'] ?? '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil Profesional'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // Permite scrollear si el contenido es largo
        padding: const EdgeInsets.all(20), // Padding general
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Alinea textos a la izquierda
          children: [
            // --- Sección Superior: Foto, Nombre, Título, Experiencia ---
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Centra verticalmente
              children: [
                CircleAvatar(
                  // Foto del Kine
                  radius: 45, // Tamaño de la foto
                  backgroundImage: NetworkImage(kinePhotoUrl),
                  backgroundColor: Colors.grey.shade200, // Fondo mientras carga
                ),
                const SizedBox(width: 20), // Espacio entre foto y texto
                Expanded(
                  // Para que el texto ocupe el espacio restante
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Alinea textos a la izquierda
                    children: [
                      Text(
                        // Nombre del Kine
                        kineName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        // Título/Especialidad
                        kineTitle,
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      const SizedBox(height: 5), // Pequeño espacio
                      Text(
                        // Años de Experiencia
                        '$kineExperience años de experiencia',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 35), // Línea divisoria con espacio
            // --- Carta de Presentación ---
            Text(
              'Presentación Profesional',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10), // Espacio antes del texto
            Container(
              // Contenedor para el texto de presentación
              width: double.infinity, // Ocupa todo el ancho disponible
              padding: const EdgeInsets.all(15), // Padding interno
              decoration: BoxDecoration(
                // Estilo del contenedor
                color: Colors.teal.shade50, // Fondo color teal muy claro
                borderRadius: BorderRadius.circular(10), // Bordes redondeados
                border: Border.all(color: Colors.teal.shade100), // Borde sutil
              ),
              child: Text(
                // Texto de la presentación
                kinePresentation,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.black87,
                ), // Estilo del texto
              ),
            ),
            const SizedBox(height: 30), // Espacio antes de los botones
            // --- Botones de Acción ---
            Row(
              // Coloca los botones uno al lado del otro
              mainAxisAlignment: MainAxisAlignment
                  .spaceEvenly, // Espacio equitativo entre botones
              children: [
                // --- Botón Enviar Mensaje ---
                OutlinedButton.icon(
                  // Botón con borde
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: const Text('Mensaje'), // Texto corto
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.teal.shade700, // Color del texto e icono
                    side: BorderSide(
                      color: Colors.teal.shade300,
                    ), // Color del borde
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 12,
                    ), // Padding interno
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ), // Estilo del texto
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ), // Bordes redondeados
                  ),
                  onPressed: () =>
                      _navigateToChat(context), // Llama a la función de chat
                ),

                // --- Botón Agendar Cita ---
                ElevatedButton.icon(
                  // Botón con fondo
                  onPressed: () => _navigateToBooking(
                    context,
                  ), // Llama a la función de agendar
                  icon: const Icon(Icons.calendar_month, size: 20),
                  label: const Text('Agendar'), // Texto corto
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.blueAccent.shade700, // Color de fondo
                    foregroundColor: Colors.white, // Color del texto e icono
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 12,
                    ), // Padding interno
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ), // Estilo del texto
                    elevation: 3, // Sombra
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ), // Bordes redondeados
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20), // Espacio extra al final de la pantalla
          ],
        ),
      ),
    );
  }
}
