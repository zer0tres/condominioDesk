import 'package:flutter/material.dart';
import '../../models/sala.dart';

class SalaHomeScreen extends StatelessWidget {
  final Sala sala;
  const SalaHomeScreen({super.key, required this.sala});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sala.displayName),
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('Bem-vindo, ${sala.displayName}!\nSala ${sala.numero}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20)),
      ),
    );
  }
}
