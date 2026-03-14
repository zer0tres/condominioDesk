import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/encomenda.dart';
import '../../widgets/foto_fullscreen_viewer.dart';

class DetalheEncomendaScreen extends StatelessWidget {
  final Encomenda encomenda;
  final String nomeEmpresa;
  const DetalheEncomendaScreen({
    super.key,
    required this.encomenda,
    required this.nomeEmpresa,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da Encomenda'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: encomenda.isPendente ? Colors.orange.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: encomenda.isPendente ? Colors.orange : Colors.green)),
              child: Row(
                children: [
                  Icon(
                    encomenda.isPendente ? Icons.inventory_2 : Icons.check_circle,
                    color: encomenda.isPendente ? Colors.orange : Colors.green,
                    size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        encomenda.isPendente ? 'Aguardando retirada' : 'Retirada',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: encomenda.isPendente ? Colors.orange : Colors.green)),
                      Text(nomeEmpresa,
                        style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _infoRow(Icons.person, 'Destinatario', encomenda.nomeDestinatario),
            if (encomenda.codigoRastreio != null)
              _infoRow(Icons.qr_code, 'Codigo', encomenda.codigoRastreio!),
            _infoRow(Icons.access_time, 'Chegou em',
              DateFormat('dd/MM/yyyy HH:mm').format(encomenda.criadoEm)),
            if (encomenda.retiradoEm != null)
              _infoRow(Icons.check, 'Retirado em',
                DateFormat('dd/MM/yyyy HH:mm').format(encomenda.retiradoEm!)),
            const SizedBox(height: 24),
            if (encomenda.fotoUrl != null) ...[
              const Text('Foto da Encomenda',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FotoFullscreenViewer(fotoUrl: encomenda.fotoUrl!))),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        encomenda.fotoUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.fullscreen,
                          color: Colors.white, size: 24)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
