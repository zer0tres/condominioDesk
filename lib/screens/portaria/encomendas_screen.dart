import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/encomenda.dart';
import '../../models/sala.dart';
import '../../services/encomenda_service.dart';
import '../../services/sala_service.dart';
import 'registrar_encomenda_screen.dart';
import 'detalhe_encomenda_screen.dart';

class EncomendasScreen extends StatefulWidget {
  const EncomendasScreen({super.key});

  @override
  State<EncomendasScreen> createState() => _EncomendasScreenState();
}

class _EncomendasScreenState extends State<EncomendasScreen> {
  final _encomendaService = EncomendaService();
  final _salaService = SalaService();
  final _buscaController = TextEditingController();

  List<Encomenda> _encomendas = [];
  List<Sala> _resultadosBusca = [];
  bool _loading = true;
  String _filtro = 'pendente';

  @override
  void initState() {
    super.initState();
    _carregarEncomendas();
  }

  Future<void> _carregarEncomendas() async {
    setState(() => _loading = true);
    try {
      final lista = await _encomendaService.listarPendentes();
      setState(() => _encomendas = lista);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _buscarSala(String termo) async {
    if (termo.isEmpty) {
      setState(() => _resultadosBusca = []);
      return;
    }
    try {
      List<Sala> resultados;
      if (int.tryParse(termo) != null) {
        final sala = await _salaService.buscarPorNumero(termo);
        resultados = sala != null ? [sala] : [];
      } else {
        resultados = await _salaService.buscarPorNome(termo);
      }
      setState(() => _resultadosBusca = resultados);
    } catch (_) {}
  }

  Future<void> _marcarRetirada(Encomenda encomenda) async {
    final nomeController = TextEditingController();
    final confirma = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar retirada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Encomenda de ${encomenda.nomeDestinatario}'),
            const SizedBox(height: 16),
            TextField(
              controller: nomeController,
              decoration: InputDecoration(
                labelText: 'Nome de quem retirou',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (confirma == true && nomeController.text.trim().isNotEmpty) {
      await _encomendaService.marcarRetirada(encomenda.id, nomeController.text.trim());
      _carregarEncomendas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encomenda marcada como retirada!'),
            backgroundColor: Colors.green));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.indigo.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _buscaController,
                  onChanged: _buscarSala,
                  decoration: InputDecoration(
                    hintText: 'Buscar sala por numero ou empresa...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _buscaController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _buscaController.clear();
                            setState(() => _resultadosBusca = []);
                          })
                      : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _filtroChip('pendente', 'Pendentes', Colors.orange),
                    const SizedBox(width: 8),
                    _filtroChip('retirada', 'Retiradas', Colors.green),
                  ],
                ),
              ],
            ),
          ),
          if (_resultadosBusca.isNotEmpty)
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('Salas encontradas:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                  ..._resultadosBusca.map((sala) => ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.meeting_room, color: Colors.white, size: 18)),
                    title: Text(sala.displayName),
                    subtitle: Text('Sala ${sala.numero}'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () async {
                      _buscaController.clear();
                      setState(() => _resultadosBusca = []);
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => RegistrarEncomendaScreen(sala: sala)));
                      _carregarEncomendas();
                    },
                  )),
                  const Divider(height: 1),
                ],
              ),
            ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _encomendas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          _filtro == 'pendente'
                            ? 'Nenhuma encomenda pendente'
                            : 'Nenhuma encomenda retirada',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                      ],
                    ))
                : RefreshIndicator(
                    onRefresh: _carregarEncomendas,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _encomendas.length,
                      itemBuilder: (_, i) {
                        final e = _encomendas[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (_) => DetalheEncomendaScreen(
                                  encomenda: e,
                                  nomeEmpresa: 'Sala ${e.salaId}')));
                              _carregarEncomendas();
                            },
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
                                Text(e.codigoRastreio ?? 'Sem codigo'),
                                Text(DateFormat('dd/MM HH:mm').format(e.criadoEm),
                                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            trailing: e.isPendente
                              ? ElevatedButton(
                                  onPressed: () => _marcarRetirada(e),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 8)),
                                  child: const Text('Retirada',
                                    style: TextStyle(color: Colors.white, fontSize: 12)))
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    if (e.retiradoPor != null)
                                      Text(e.retiradoPor!,
                                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
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
            builder: (_) => const RegistrarEncomendaScreen()));
          _carregarEncomendas();
        },
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova Encomenda'),
      ),
    );
  }

  Widget _filtroChip(String valor, String label, Color cor) {
    final selecionado = _filtro == valor;
    return GestureDetector(
      onTap: () async {
        setState(() { _filtro = valor; _loading = true; });
        try {
          List<Encomenda> lista;
          if (valor == 'pendente') {
            lista = await _encomendaService.listarPendentes();
          } else {
            lista = await _encomendaService.listarRetiradas();
          }
          setState(() => _encomendas = lista);
        } finally {
          setState(() => _loading = false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selecionado ? cor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cor)),
        child: Text(label,
          style: TextStyle(
            color: selecionado ? Colors.white : cor,
            fontWeight: FontWeight.bold)),
      ),
    );
  }
}
