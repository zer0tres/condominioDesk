import 'package:flutter/material.dart';
import '../../models/encomenda.dart';
import '../../services/encomenda_service.dart';
import '../../services/sala_service.dart';
import '../../models/sala.dart';
import 'registrar_encomenda_screen.dart';

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
    } finally {
      
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
            child: TextField(
              controller: _buscaController,
              onChanged: _buscarSala,
              decoration: InputDecoration(
                hintText: 'Buscar sala por número ou empresa...',
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
                      style: TextStyle(fontWeight: FontWeight.bold,
                          color: Colors.grey)),
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
                        Text('Nenhuma encomenda pendente',
                          style: TextStyle(color: Colors.grey.shade500,
                              fontSize: 16)),
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
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.inventory_2,
                                  color: Colors.white, size: 18)),
                            title: Text(e.nomeDestinatario,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(e.codigoRastreio ?? 'Sem código'),
                            trailing: const Chip(
                              label: Text('Pendente',
                                style: TextStyle(fontSize: 11, color: Colors.white)),
                              backgroundColor: Colors.orange,
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
}
