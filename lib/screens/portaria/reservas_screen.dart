import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/reserva.dart';
import '../../models/espaco_comum.dart';
import '../../services/reserva_service.dart';
import 'nova_reserva_screen.dart';
import 'detalhe_reserva_screen.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final _reservaService = ReservaService();
  List<Reserva> _reservas = [];
  List<Reserva> _reservasFiltradas = [];
  List<EspacoComum> _espacos = [];
  bool _loading = true;
  final _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final espacos = await _reservaService.listarEspacos();
      final reservas = await _reservaService.listarProximas();
      setState(() {
        _espacos = espacos;
        _reservas = reservas;
        _reservasFiltradas = reservas;
        _buscaController.clear();
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  void _filtrarReservas(String termo) {
    final t = termo.toLowerCase();
    setState(() {
      _reservasFiltradas = t.isEmpty ? _reservas : _reservas.where((r) =>
        r.responsavelNome.toLowerCase().contains(t) ||
        _nomesEspacos(r.espacoIds).toLowerCase().contains(t) ||
        (r.observacoes?.toLowerCase().contains(t) ?? false) ||
        r.data.toIso8601String().contains(t)
      ).toList();
    });
  }

  String _nomesEspacos(List<String> ids) {
    return ids.map((id) {
      final e = _espacos.where((e) => e.id == id).firstOrNull;
      return e?.nome ?? id;
    }).join(' + ');
  }

  bool _isHoje(DateTime data) {
    final hoje = DateTime.now();
    return data.year == hoje.year && data.month == hoje.month && data.day == hoje.day;
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Reserva>> porData = {};
    for (final r in _reservasFiltradas) {
      final chave = r.data.toIso8601String().split('T')[0];
      porData.putIfAbsent(chave, () => []).add(r);
    }

    return Scaffold(
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _reservas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Nenhuma reserva proxima',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                ],
              ))
          : Column(
              children: [
                Container(
                  color: Colors.indigo.shade50,
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _buscaController,
                    onChanged: _filtrarReservas,
                    decoration: InputDecoration(
                      hintText: 'Filtrar reservas...',
                      prefixIcon: const Icon(Icons.filter_list),
                      suffixIcon: _buscaController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _buscaController.clear();
                              _filtrarReservas('');
                            })
                        : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _carregar,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: porData.length,
                      itemBuilder: (_, i) {
                        final chave = porData.keys.elementAt(i);
                        final data = DateTime.parse(chave);
                        final reservasDia = porData[chave]!;
                        final hoje = _isHoje(data);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(bottom: 8, top: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: hoje
                                  ? Colors.indigo.shade900
                                  : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                hoje
                                  ? 'Hoje — ${DateFormat("d 'de' MMMM", 'pt_BR').format(data)}'
                                  : DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(data),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: hoje ? Colors.white : Colors.grey.shade700,
                                  fontSize: 13),
                              ),
                            ),
                            ...reservasDia.map((r) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                onTap: () async {
                                  await Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => DetalheReservaScreen(
                                      reserva: r,
                                      espacos: _espacos,
                                      onCancelada: _carregar)));
                                },
                                leading: CircleAvatar(
                                  backgroundColor: hoje
                                    ? Colors.indigo.shade900
                                    : Colors.indigo.shade300,
                                  child: const Icon(Icons.meeting_room,
                                      color: Colors.white, size: 18)),
                                title: Text(_nomesEspacos(r.espacoIds),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${r.horaInicio.substring(0,5)} - ${r.horaFim.substring(0,5)} | ${r.responsavelNome}'),
                                    if (r.numPessoas != null)
                                      Text('${r.numPessoas} pessoas',
                                        style: const TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                trailing: r.valorTotal != null
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('R\$ ${r.valorTotal!.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo.shade900)),
                                        const Icon(Icons.chevron_right,
                                            color: Colors.grey, size: 16),
                                      ])
                                  : const Icon(Icons.chevron_right, color: Colors.grey),
                                isThreeLine: r.numPessoas != null,
                              ),
                            )),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => NovaReservaScreen(dataInicial: DateTime.now())));
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
