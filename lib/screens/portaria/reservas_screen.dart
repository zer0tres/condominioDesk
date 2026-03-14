import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reserva.dart';
import '../../models/espaco_comum.dart';
import '../../services/reserva_service.dart';
import 'nova_reserva_screen.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final _reservaService = ReservaService();
  DateTime _dataSelecionada = DateTime.now();
  List<Reserva> _reservas = [];
  List<EspacoComum> _espacos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final espacos = await _reservaService.listarEspacos();
      final reservas = await _reservaService.listarPorData(_dataSelecionada);
      setState(() { _espacos = espacos; _reservas = reservas; });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataSelecionada,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dataSelecionada = picked);
      _carregar();
    }
  }

  String _nomesEspacos(List<String> ids) {
    return ids.map((id) {
      final e = _espacos.where((e) => e.id == id).firstOrNull;
      return e?.nome ?? id;
    }).join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(_dataSelecionada),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _selecionarData,
                  child: const Text('Mudar data'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _reservas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available,
                          size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Nenhuma reserva para este dia',
                          style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ))
                : RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _reservas.length,
                      itemBuilder: (_, i) {
                        final r = _reservas[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.indigo,
                              child: Icon(Icons.meeting_room,
                                color: Colors.white, size: 18)),
                            title: Text(_nomesEspacos(r.espacoIds),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${r.horaInicio.substring(0,5)} - ${r.horaFim.substring(0,5)} | ${r.responsavelNome}'),
                                if (r.numPessoas != null)
                                  Text('${r.numPessoas} pessoas', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (r.valorTotal != null)
                                  Text('R\$ ${r.valorTotal!.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () async {
                                final confirma = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Cancelar reserva?'),
                                    content: Text('Reserva de ${r.responsavelNome} sera cancelada.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Nao')),
                                      TextButton(onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Sim', style: TextStyle(color: Colors.red))),
                                    ],
                                  ),
                                );
                                if (confirma == true) {
                                  await _reservaService.cancelar(r.id);
                                  _carregar();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    )),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => NovaReservaScreen(dataInicial: _dataSelecionada)));
          _carregar();
        },
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Reserva'),
      ),
    );
  }
}
