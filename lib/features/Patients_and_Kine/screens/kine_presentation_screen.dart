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
        kineData['presentation'] ?? 'Este profesional aún no agrega una presentación.';
    final String kineExperience = kineData['experience'] ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5), // gris muy claro
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Perfil Profesional',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CARD PRINCIPAL
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x0F000000)),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // avatar
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFE5E7EB),
                    backgroundImage:
                        kinePhotoUrl.isNotEmpty ? NetworkImage(kinePhotoUrl) : null,
                    child: kinePhotoUrl.isEmpty
                        ? const Icon(Icons.person, size: 32, color: Colors.white)
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
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kineTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.work_outline,
                                size: 16, color: Colors.black38),
                            const SizedBox(width: 4),
                            Text(
                              '$kineExperience años de experiencia',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Presentación profesional',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),

            // card de presentación
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x10A1A1AA)),
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

            const SizedBox(height: 22),

            // BOTONES
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToChat(context),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Mensaje'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToBooking(context),
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: const Text('Agendar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
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
