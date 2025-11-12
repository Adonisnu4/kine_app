import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/features/Patients_and_Kine/services/kine_service.dart';
import 'kine_presentation_screen.dart';
import '../../auth/screens/profile_screen.dart';

class KineDirectoryScreen extends StatefulWidget {
  const KineDirectoryScreen({super.key});

  @override
  State<KineDirectoryScreen> createState() => _KineDirectoryScreenState();
}

class _KineDirectoryScreenState extends State<KineDirectoryScreen> {
  final KineService _kineService = KineService();
  late Future<List<Map<String, dynamic>>> _kineListFuture;

  @override
  void initState() {
    super.initState();
    _kineListFuture = _kineService.getKineDirectory();
  }

  void _reloadKineList() {
    setState(() {
      _kineListFuture = _kineService.getKineDirectory();
    });
  }

  void _navigateToKineScreen(Map<String, dynamic> kine) async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final Widget destinationScreen;

    if (currentUserId != null && kine['id'] == currentUserId) {
      destinationScreen = const ProfileScreen();
    } else {
      destinationScreen = KinePresentationScreen(
        kineId: kine['id']!,
        kineData: kine.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      );
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationScreen),
    );

    _reloadKineList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // sin appBar: ya lo pone el HomeScreen
      backgroundColor: const Color(0xFFF3F3F3),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Directorio de Kinesiólogos',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text(
              'Encuentra profesionales disponibles para ti.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _kineListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Ocurrió un error al cargar: ${snapshot.error}'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No hay kinesiólogos disponibles en este momento.'),
                  );
                }

                final kineList = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  itemCount: kineList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final kine = kineList[index];
                    final photoUrl = kine['photoUrl'] as String?;
                    final name = (kine['name'] ?? 'Kinesiólogo') as String;
                    final specialization =
                        (kine['specialization'] ?? 'Sin especialidad') as String;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x0F000000)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage:
                              (photoUrl != null && photoUrl.isNotEmpty)
                                  ? NetworkImage(photoUrl)
                                  : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          specialization,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.5,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.black54,
                        ),
                        onTap: () => _navigateToKineScreen(kine),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
