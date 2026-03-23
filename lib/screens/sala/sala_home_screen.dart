import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/sala.dart';
import '../../models/encomenda.dart';
import '../../models/reserva.dart';
import '../../models/espaco_comum.dart';
import '../../services/encomenda_service.dart';
import '../../services/reserva_service.dart';
import '../../services/notification_service.dart';
import '../portaria/nova_reserva_screen.dart';
import '../portaria/detalhe_reserva_screen.dart';
import '../../widgets/foto_fullscreen_viewer.dart';

class SalaHomeScreen extends StatefulWidget {
  final Sala sala;
  const SalaHomeScreen({super.key, required this.sala});

  @override
  State<SalaHomeScreen> createState() => _SalaHomeScreenState();
}

class _SalaHomeScreenState extends State<SalaHomeScreen> {
  final _encomendaService = EncomendaService();
  final _reservaService = ReservaService();

  List<Encomenda> _encomendas = [];
  List<Reserva> _reservas = [];
  List<EspacoComum> _espacos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    NotificationService.salvarTokenSala(widget.sala.id);
    NotificationService.salvarSalaId(widget.sala.id);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    try {
      final encomendas = await _encomendaService.listarPorSala(widget.sala.id);
      final espacos = await _reservaService.listarEspacos();
      final reservas = await _reservaService.listarProximasPorSala(widget.sala.id);
      setState(() {
        _encomendas = encomendas;
        _espacos = espacos;
        _reservas = reservas;
      });
    } finally {
      setState(() => _loading = false);
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.teal.shade900,
          foregroundColor: Colors.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.sala.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Sala ${widget.sala.numero}',
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2), text: 'Minhas Encomendas'),
              Tab(icon: Icon(Icons.calendar_month), text: 'Agenda'),
            ],
          ),
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              children: [
                _buildEncomendas(),
                _buildAgenda(),
              ],
            ),
      ),
    );
  }

  Widget _buildEncomendas() {
    final pendentes = _encomendas.where((e) => e.isPendente).toList();
    final retiradas = _encomendas.where((e) => !e.isPendente).toList();

    if (_encomendas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nenhuma encomenda encontrada',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Suas encomendas aparecerao aqui',
              style: TextStyle(color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (pendentes.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Aguardando retirada',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 16, color: Colors.orange)),
            ),
            ...pendentes.map((e) => _buildEncomendaCard(e)),
          ],
          if (retiradas.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Retiradas',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 16, color: Colors.green)),
            ),
            ...retiradas.map((e) => _buildEncomendaCard(e)),
          ],
        ],
      ),
    );
  }

  Widget _buildEncomendaCard(Encomenda e) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: e.isPendente ? Colors.orange : Colors.green,
              child: Icon(
                e.isPendente ? Icons.inventory_2 : Icons.check_circle,
                color: Colors.white, size: 18)),
            title: Text(e.nomeDestinatario,
              style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (e.codigoRastreio != null)
                  Text('Codigo: ${e.codigoRastreio}'),
                Text('Chegou: ${DateFormat('dd/MM/yyyy HH:mm').format(e.criadoEm)}'),
                if (e.retiradoEm != null)
                  Text('Retirado: ${DateFormat('dd/MM/yyyy HH:mm').format(e.retiradoEm!)}',
                    style: const TextStyle(color: Colors.green)),
              ],
            ),
            isThreeLine: true,
          ),
          if (e.fotoUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => FotoFullscreenViewer(fotoUrl: e.fotoUrl!))),
                  child: Stack(
                    children: [
                      Image.network(e.fotoUrl!,
                        height: 150, width: double.infinity, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                      Positioned(
                        bottom: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.fullscreen, color: Colors.white, size: 20)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAgenda() {
    return Scaffold(
      body: _reservas.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text('Nenhuma reserva futura encontrada',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              ],
            ))
        : ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'Proximas reservas desta sala',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              ..._reservas.map((r) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () async {
                    final podeCancelar = await ReservaService().podeCancelar(r.id);
                    if (!mounted) return;
                    await Navigator.push(context, MaterialPageRoute(
                      builder: (_) => DetalheReservaScreen(
                        reserva: r,
                        espacos: _espacos,
                        podeCancelar: podeCancelar,
                        onCancelada: _carregar)));
                  },
                  leading: const CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Icon(Icons.meeting_room, color: Colors.white, size: 18)),
                  title: Text(_nomesEspacos(r.espacoIds),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${r.horaInicio.substring(0,5)} - ${r.horaFim.substring(0,5)} | ${r.responsavelNome}'),
                  trailing: r.salaId == widget.sala.id
                    ? const Icon(Icons.chevron_right, color: Colors.grey)
                    : null,
                ),
              )),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => NovaReservaScreen(
              dataInicial: DateTime.now(),
              salaId: widget.sala.id)));
          _carregar();
        },
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Reserva'),
      ),
    );
  }
}
