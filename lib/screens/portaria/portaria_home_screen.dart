import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'encomendas_screen.dart';
import 'reservas_screen.dart';
import '../portaria/login_screen.dart';

class PortariaHomeScreen extends StatelessWidget {
  const PortariaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo.shade900,
          foregroundColor: Colors.white,
          title: const Row(
            children: [
              Icon(Icons.business, size: 24),
              SizedBox(width: 8),
              Text('AR3000', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2), text: 'Encomendas'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Reservas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            EncomendasScreen(),
            ReservasScreen(),
          ],
        ),
      ),
    );
  }
}
