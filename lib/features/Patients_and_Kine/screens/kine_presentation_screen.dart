import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/screens/booking_screen.dart';
import 'package:kine_app/features/Chat/screens/chat_screen.dart';

class KinePresentationScreen extends StatelessWidget {
  final String kineId;
  final Map<String, String> kineData;

  const KinePresentationScreen({
    super.key,
    required this.kineId,
    required this.kineData,
  });

  // paleta centralizada
  static const Color _blue = Color(0xFF47A5D6);
  static const Color _orange = Color(0xFFE28825);
  static const Color _bg = Color(0xFFF4F4F5);

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
    final String kineName = kineData['name'] ?? 'Kinesiólogo';
    final String kineTitle = kineData['specialization'] ?? 'Especialista';
    final String kinePhotoUrl = kineData['photoUrl'] ?? '';
    final String kinePresentation =
        kineData['presentation'] ??
            'Este profesional aún no agrega una presentación.';
    final String kineExperience = kineData['experience'] ?? '—';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
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
            // acento
            Container(
              width: 46,
              height: 3.5,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            // CARD de perfil
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: _blue.withOpacity(.12),
                    backgroundImage:
                        kinePhotoUrl.isNotEmpty ? NetworkImage(kinePhotoUrl) : null,
                    child: kinePhotoUrl.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 34,
                            color: _blue.withOpacity(.9),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kineName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          kineTitle,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // chip de experiencia
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
                              Icon(
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
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Presentación profesional',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // card de presentación (no textfield)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x0FA1A1AA)),
              ),
              padding: const EdgeInsets.all(14),
              child: Text(
                kinePresentation,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: 26),

            // BOTONES
            Row(
              children: [
                // mensaje
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToChat(context),
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: _blue,
                    ),
                    label: Text(
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
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // agendar
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToBooking(context),
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: const Text('Agendar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      elevation: 0,
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
