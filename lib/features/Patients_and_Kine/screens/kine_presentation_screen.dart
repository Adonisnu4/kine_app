import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/screens/booking_screen.dart';
import 'package:kine_app/features/Chat/screens/chat_screen.dart';

/// Pantalla pública de presentación del kinesiólogo.
/// Muestra datos profesionales, foto, especialidad, experiencia,
/// carta de presentación y botones para chatear o agendar una cita.
class KinePresentationScreen extends StatelessWidget {
  final String kineId;

  final Map<String, String> kineData;

  const KinePresentationScreen({
    super.key,
    required this.kineId,
    required this.kineData,
  });

  // 🎨 Paleta centralizada
  static const Color _blue = Color(0xFF47A5D6);
  static const Color _orange = Color(0xFFE28825);
  static const Color _bg = Color(0xFFF4F4F5);

  /// Navega a la pantalla de agendamiento
  void _navigateToBooking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingScreen(
          kineId: kineId,
          kineNombre: kineData['name'] ?? 'Kinesiólogo',
        ),
      ),
    );
  }

  /// Navega al chat con el kinesiólogo
  void _navigateToChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: kineId,
          receiverName: kineData['name'] ?? 'Kinesiólogo',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Variables limpias para usar en la UI
    final String kineName = kineData['name'] ?? 'Kinesiólogo';
    final String kineTitle = kineData['specialization'] ?? 'Especialista';
    final String kinePhotoUrl = kineData['photoUrl'] ?? '';
    final String kineExperience = kineData['experience'] ?? '—';

    final String kinePresentation =
        kineData['presentation'] ??
        'Este profesional aún no agrega una presentación.';

    return Scaffold(
      backgroundColor: _bg,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Perfil Profesional',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Línea decorativa naranja
            Container(
              width: 46,
              height: 3.5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // TARJETA DE PERFIL
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),

              child: Row(
                children: [
                  /// FOTO DEL KINESIÓLOGO
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: _blue.withOpacity(.12),
                    backgroundImage: kinePhotoUrl.isNotEmpty
                        ? NetworkImage(kinePhotoUrl)
                        : null,
                    child: kinePhotoUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 34,
                            color: _blue.withOpacity(.9),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

                  /// INFORMACIÓN PRINCIPAL
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre
                        Text(
                          kineName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),

                        // Especialidad
                        Text(
                          kineTitle,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Chip de experiencia
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _blue.withOpacity(.07),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.badge_outlined,
                                size: 14,
                                color: _blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$kineExperience años de experiencia',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _blue.withOpacity(.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // PRESENTACIÓN DEL KINESIÓLOGO
            const Text(
              'Presentación profesional',
              style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Color(0x0FA1A1AA)),
              ),

              child: Text(
                kinePresentation,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 26),

            // BOTONES: CHAT + AGENDAR
            Row(
              children: [
                ///BOTÓN MENSAJE
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToChat(context),
                    icon: const Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: _blue,
                    ),
                    label: const Text(
                      'Mensaje',
                      style: TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _blue.withOpacity(.35)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // BOTÓN AGENDAR
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToBooking(context),
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: const Text('Agendar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
