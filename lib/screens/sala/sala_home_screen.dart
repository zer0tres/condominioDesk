import 'package:flutter/material.dart';
import '../../models/sala.dart';
import '../../services/notification_service.dart';

class SalaHomeScreen extends StatefulWidget {
  final Sala sala;
  const SalaHomeScreen({super.key, required this.sala});

  @override
  State<SalaHomeScreen> createState() => _SalaHomeScreenState();
}

class _SalaHomeScreenState extends State<SalaHomeScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService.salvarTokenSala(widget.sala.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sala.displayName),
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.meeting_room, size: 80, color: Colors.teal),
            const SizedBox(height: 16),
            Text(widget.sala.displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Sala ${widget.sala.numero}',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            const Text('Modulos em construcao...',
              style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
