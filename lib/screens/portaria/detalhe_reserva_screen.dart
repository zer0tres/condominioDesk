import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reserva.dart';
import '../../models/espaco_comum.dart';
import '../../services/reserva_service.dart';

class DetalheReservaScreen extends StatelessWidget {
  final Reserva reserva;
  final List<EspacoComum> espacos;
  final VoidCallback onCancelada;
  final bool podeCancelar;

  const DetalheReservaScreen({
    super.key,
    required this.reserva,
    required this.espacos,
    required this.onCancelada,
    this.podeCancelar = true,
  });

  String _nomesEspacos(List<String> ids) {
    return ids.map((id) {
      final e = espacos.where((e) => e.id == id).firstOrNull;
      return e?.nome ?? id;
    }).join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Reserva'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline,
              color: podeCancelar ? null : Colors.grey),
            onPressed: !podeCancelar ? null : () async {
              final confirma = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Cancelar reserva?'),
                  content: Text('Reserva de ${reserva.responsavelNome} sera cancelada.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Nao')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Sim', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirma == true) {
                await ReservaService().cancelar(reserva.id);
                onCancelada();
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.shade200)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_nomesEspacos(reserva.espacoIds),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade900)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat("EEEE, d 'de' MMMM 'de' yyyy", 'pt_BR').format(reserva.data),
                    style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            if (!podeCancelar) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200)),
              child: Row(children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(child: Text(
                  'Cancelamento indisponivel. Prazo de 48h antes do evento ja encerrou.',
                  style: TextStyle(color: Colors.orange, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: 24),
            _infoRow(Icons.access_time, 'Horario',
              '${reserva.horaInicio.substring(0,5)} ate ${reserva.horaFim.substring(0,5)}'),
            _infoRow(Icons.person, 'Responsavel', reserva.responsavelNome),
            if (reserva.numPessoas != null)
              _infoRow(Icons.group, 'Numero de pessoas', '${reserva.numPessoas} pessoas'),
            if (reserva.duracaoTipo != null && reserva.duracaoValor != null)
              _infoRow(Icons.timer, 'Duracao',
                '${reserva.duracaoValor} ${reserva.duracaoTipo}'),
            if (reserva.valorTotal != null)
              _infoRow(Icons.attach_money, 'Valor estimado',
                'R\$ ${reserva.valorTotal!.toStringAsFixed(2)}'),
            if (reserva.observacoes != null && reserva.observacoes!.isNotEmpty)
              _infoRow(Icons.notes, 'Observacoes', reserva.observacoes!),
            if (reserva.salaId != null)
              _infoRow(Icons.meeting_room, 'Solicitado por', 'Sala ${reserva.salaId}'),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
