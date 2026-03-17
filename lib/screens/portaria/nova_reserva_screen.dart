import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/espaco_comum.dart';
import '../../services/reserva_service.dart';
import '../../services/sala_service.dart';
import '../../models/sala.dart';

class NovaReservaScreen extends StatefulWidget {
  final DateTime dataInicial;
  final String? salaId;
  const NovaReservaScreen({super.key, required this.dataInicial, this.salaId});

  @override
  State<NovaReservaScreen> createState() => _NovaReservaScreenState();
}

class _NovaReservaScreenState extends State<NovaReservaScreen> {
  final _nomeController = TextEditingController();
  final _pessoasController = TextEditingController();
  final _cadeirasController = TextEditingController();
  final _mesasController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _reservaService = ReservaService();
  final _salaService = SalaService();
  final _buscaSalaController = TextEditingController();
  Sala? _salaSelecionada;
  List<Sala> _resultadosSala = [];
  bool _buscandoSala = false;

  DateTime _data = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _horaFim = const TimeOfDay(hour: 11, minute: 0);
  List<EspacoComum> _espacos = [];
  final List<String> _espacosSelecionados = [];
  bool _loading = false;
  bool _carregando = true;
  String? _erro;
  Map<String, bool> _copaCoffeeOcupado = {'copa': false, 'coffee': false};
  Map<String, int> _materialDisponivel = {'cadeiras': 115, 'mesas': 33};
  Map<String, int> _limiteMaterial = {'cadeiras': 0, 'mesas': 0};

  @override
  void initState() {
    super.initState();
    _data = widget.dataInicial;
    _carregarEspacos();
  }

  Future<void> _buscarSala(String termo) async {
    if (termo.isEmpty) { setState(() => _resultadosSala = []); return; }
    setState(() => _buscandoSala = true);
    try {
      List<Sala> r;
      if (int.tryParse(termo) != null || termo.toUpperCase() == 'ADM') {
        final s = await _salaService.buscarPorNumero(termo.toUpperCase());
        r = s != null ? [s] : [];
      } else {
        r = await _salaService.buscarPorNome(termo);
      }
      setState(() => _resultadosSala = r);
    } finally {
      setState(() => _buscandoSala = false);
    }
  }

  Future<void> _carregarEspacos() async {
    final espacos = await _reservaService.listarEspacos();
    setState(() { _espacos = espacos; _carregando = false; });
    _verificarDisponibilidade();
  }

  Future<void> _verificarDisponibilidade() async {
    final copaCoffee = await _reservaService.verificarDisponibilidadeCopaCoffee(
        _data, widget.salaId);
    final inicio = _formatTime(_horaInicio);
    final fim = _formatTime(_horaFim);
    final material = await _reservaService.verificarMaterialDisponivel(
        _data, inicio, fim);
    setState(() {
      _copaCoffeeOcupado = copaCoffee;
      _materialDisponivel = material;
    });
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:00';

  double _calcularValor() {
    if (_horaInicio == _horaFim) return 0;
    return _reservaService.calcularValor(
      _espacosSelecionados, _espacos,
      _formatTime(_horaInicio), _formatTime(_horaFim));
  }

  int _calcularPeriodos() {
    final inicio = _horaInicio.hour * 60 + _horaInicio.minute;
    final fim = _horaFim.hour * 60 + _horaFim.minute;
    final duracao = fim - inicio;
    if (duracao <= 0) return 0;
    return (duracao / 120.0).ceil();
  }

  void _atualizarLimiteMaterial() {
    final limite = _reservaService.calcularLimiteMaterial(
        _espacosSelecionados, _espacos);
    setState(() => _limiteMaterial = limite);
  }

  Future<void> _salvar() async {
    if (_espacosSelecionados.isEmpty) {
      setState(() => _erro = 'Selecione pelo menos um espaco.');
      return;
    }
    if (_nomeController.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o nome do responsavel.');
      return;
    }
    final inicio = _formatTime(_horaInicio);
    final fim = _formatTime(_horaFim);
    if (inicio.compareTo(fim) >= 0) {
      setState(() => _erro = 'Hora de fim deve ser maior que hora de inicio.');
      return;
    }

    final cadeiras = int.tryParse(_cadeirasController.text) ?? 0;
    final mesas = int.tryParse(_mesasController.text) ?? 0;

    if (_limiteMaterial['cadeiras']! > 0 && cadeiras > _limiteMaterial['cadeiras']!) {
      setState(() => _erro = 'Maximo de ${_limiteMaterial['cadeiras']} cadeiras para as salas selecionadas.');
      return;
    }
    if (_limiteMaterial['mesas']! > 0 && mesas > _limiteMaterial['mesas']!) {
      setState(() => _erro = 'Maximo de ${_limiteMaterial['mesas']} mesas para as salas selecionadas.');
      return;
    }
    if (cadeiras > _materialDisponivel['cadeiras']!) {
      setState(() => _erro = 'Somente ${_materialDisponivel['cadeiras']} cadeiras disponiveis neste horario.');
      return;
    }
    if (mesas > _materialDisponivel['mesas']!) {
      setState(() => _erro = 'Somente ${_materialDisponivel['mesas']} mesas disponiveis neste horario.');
      return;
    }

    setState(() { _loading = true; _erro = null; });
    try {
      await _reservaService.criar(
        espacoIds: _espacosSelecionados,
        data: _data,
        horaInicio: inicio,
        horaFim: fim,
        responsavelNome: _nomeController.text.trim(),
        salaId: widget.salaId ?? _salaSelecionada?.id,
        numPessoas: int.tryParse(_pessoasController.text),
        valorTotal: _calcularValor(),
        observacoes: _observacoesController.text.trim().isEmpty
            ? null : _observacoesController.text.trim(),
        numCadeiras: cadeiras,
        numMesas: mesas,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva criada com sucesso!'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _erro = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _podeSelecionar(EspacoComum espaco) {
    if (espaco.nome == 'Copa' && _copaCoffeeOcupado['copa'] == true) return false;
    if (espaco.nome == 'Coffe' && _copaCoffeeOcupado['coffee'] == true) return false;
    if (!espaco.combinavel) return true;
    final combinaveis = _espacos.where((e) => e.combinavel).toList();
    final indices = _espacosSelecionados
        .where((id) => combinaveis.any((e) => e.id == id))
        .map((id) => combinaveis.indexWhere((e) => e.id == id))
        .toList();
    if (indices.isEmpty) return true;
    final idxEspaco = combinaveis.indexWhere((e) => e.id == espaco.id);
    final minIdx = indices.reduce((a, b) => a < b ? a : b);
    final maxIdx = indices.reduce((a, b) => a > b ? a : b);
    return idxEspaco == minIdx - 1 || idxEspaco == maxIdx + 1;
  }

  @override
  Widget build(BuildContext context) {
    final valorEstimado = _calcularValor();
    final periodos = _calcularPeriodos();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Reserva'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: _carregando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context, initialDate: _data,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) {
                      setState(() => _data = picked);
                      _verificarDisponibilidade();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, color: Colors.indigo),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd/MM/yyyy').format(_data),
                        style: const TextStyle(fontSize: 16)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Inicio', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context, initialTime: _horaInicio);
                          if (t != null) {
                            setState(() => _horaInicio = t);
                            _verificarDisponibilidade();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.access_time, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text(_horaInicio.format(context)),
                          ]),
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fim', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final t = await showTimePicker(
                            context: context, initialTime: _horaFim);
                          if (t != null) {
                            setState(() => _horaFim = t);
                            _verificarDisponibilidade();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.access_time_filled, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Text(_horaFim.format(context)),
                          ]),
                        ),
                      ),
                    ],
                  )),
                ]),
                if (periodos > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'Duracao: $periodos periodo${periodos > 1 ? 's' : ''} de 2h (cobranca minima 2h)',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 24),
                const Text('Espacos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._espacos.map((espaco) {
                  final selecionado = _espacosSelecionados.contains(espaco.id);
                  final podeSelecionar = selecionado || _podeSelecionar(espaco);
                  final ocupado = (espaco.nome == 'Copa' && _copaCoffeeOcupado['copa'] == true) ||
                                  (espaco.nome == 'Coffe' && _copaCoffeeOcupado['coffee'] == true);
                  final valor = ReservaService.valoresPor2h[espaco.nome] ?? 105.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: podeSelecionar ? () {
                        setState(() {
                          if (selecionado) {
                            _espacosSelecionados.remove(espaco.id);
                          } else {
                            _espacosSelecionados.add(espaco.id);
                          }
                        });
                        _atualizarLimiteMaterial();
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ocupado ? Colors.grey.shade100 :
                                 selecionado ? Colors.indigo.shade50 : Colors.white,
                          border: Border.all(
                            color: ocupado ? Colors.grey.shade300 :
                                   selecionado ? Colors.indigo : Colors.grey.shade300,
                            width: selecionado ? 2 : 1),
                          borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          Icon(
                            ocupado ? Icons.block :
                            selecionado ? Icons.check_box : Icons.check_box_outline_blank,
                            color: ocupado ? Colors.grey :
                                   selecionado ? Colors.indigo :
                                   podeSelecionar ? Colors.grey : Colors.grey.shade300),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(espaco.nome, style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ocupado ? Colors.grey :
                                       podeSelecionar ? Colors.black : Colors.grey.shade400)),
                              Row(children: [
                                if (ocupado)
                                  Text('Ja reservado neste dia',
                                    style: TextStyle(fontSize: 12, color: Colors.red.shade300))
                                else if (valor == 0)
                                  const Text('Gratuito',
                                    style: TextStyle(fontSize: 12, color: Colors.green,
                                        fontWeight: FontWeight.bold))
                                else
                                  Text('R\$ ${valor.toStringAsFixed(0)} por periodo de 2h',
                                    style: const TextStyle(fontSize: 12, color: Colors.indigo,
                                        fontWeight: FontWeight.bold)),
                              ]),
                            ],
                          )),
                        ]),
                      ),
                    ),
                  );
                }),
                if (_limiteMaterial['cadeiras']! > 0) ...[
                  const SizedBox(height: 16),
                  const Text('Material (opcional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    'Disponivel: ${_materialDisponivel["cadeiras"]} cadeiras e ${_materialDisponivel["mesas"]} mesas | Limite das salas: ${_limiteMaterial["cadeiras"]} cadeiras e ${_limiteMaterial["mesas"]} mesas',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _cadeirasController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cadeiras',
                        hintText: 'Max ${_limiteMaterial['cadeiras']}',
                        prefixIcon: const Icon(Icons.chair),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                      controller: _mesasController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Mesas',
                        hintText: 'Max ${_limiteMaterial['mesas']}',
                        prefixIcon: const Icon(Icons.table_restaurant),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    )),
                  ]),
                ],
                const SizedBox(height: 16),
                const Text('Numero de pessoas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _pessoasController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Quantas pessoas?',
                    prefixIcon: const Icon(Icons.group),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                if (widget.salaId == null) ...[
                  const Text('Sala do Condômino (opcional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _buscaSalaController,
                    onChanged: (v) {
                      if (_salaSelecionada != null) setState(() => _salaSelecionada = null);
                      _buscarSala(v);
                    },
                    decoration: InputDecoration(
                      hintText: 'Numero ou nome da sala...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _buscandoSala
                        ? const Padding(padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                  if (_resultadosSala.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: _resultadosSala.map((sala) => ListTile(
                          title: Text(sala.displayName),
                          subtitle: Text('Sala \${sala.numero}'),
                          onTap: () => setState(() {
                            _salaSelecionada = sala;
                            _buscaSalaController.text = '\${sala.numero} — \${sala.displayName}';
                            _resultadosSala = [];
                          }),
                        )).toList(),
                      ),
                    ),
                  ],
                  if (_salaSelecionada != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.indigo.shade50,
                        borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          'Sala \${_salaSelecionada!.numero} — \${_salaSelecionada!.displayName}',
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                const Text('Responsavel',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    hintText: 'Nome do responsavel...',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                const Text('Observacoes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _observacoesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Informacoes adicionais (opcional)...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                if (valorEstimado > 0) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade200)),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Valor total:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('R\$ ${valorEstimado.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.bold,
                                fontSize: 20, color: Colors.indigo.shade900)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('$periodos periodo${periodos > 1 ? 's' : ''} x R\$ ${(valorEstimado / periodos).toStringAsFixed(2)}/periodo',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
                if (_erro != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200)),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_erro!,
                        style: const TextStyle(color: Colors.red))),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                    icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                    label: Text(_loading ? 'Salvando...' : 'Confirmar Reserva',
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }
}
