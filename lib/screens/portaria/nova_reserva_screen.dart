import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/espaco_comum.dart';
import '../../services/reserva_service.dart';

class NovaReservaScreen extends StatefulWidget {
  final DateTime dataInicial;
  const NovaReservaScreen({super.key, required this.dataInicial});

  @override
  State<NovaReservaScreen> createState() => _NovaReservaScreenState();
}

class _NovaReservaScreenState extends State<NovaReservaScreen> {
  final _nomeController = TextEditingController();
  final _pessoasController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _reservaService = ReservaService();

  DateTime _data = DateTime.now();
  TimeOfDay _horaInicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _horaFim = const TimeOfDay(hour: 10, minute: 0);
  List<EspacoComum> _espacos = [];
  final List<String> _espacosSelecionados = [];
  String _duracaoTipo = 'horas';
  bool _loading = false;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _data = widget.dataInicial;
    _carregarEspacos();
  }

  Future<void> _carregarEspacos() async {
    final espacos = await _reservaService.listarEspacos();
    setState(() { _espacos = espacos; _carregando = false; });
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}:00';

  double _calcularValor() {
    double total = 0;
    for (final id in _espacosSelecionados) {
      final espaco = _espacos.where((e) => e.id == id).firstOrNull;
      if (espaco != null) {
        final valorHora = ReservaService.valoresPorHora[espaco.nome] ?? 100.0;
        if (_duracaoTipo == 'horas') {
          final horas = _horaFim.hour - _horaInicio.hour +
              (_horaFim.minute - _horaInicio.minute) / 60.0;
          total += valorHora * horas.clamp(0, 24);
        } else {
          final dias = double.tryParse(_pessoasController.text) ?? 1;
          total += valorHora * 8 * dias;
        }
      }
    }
    return total;
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

    setState(() { _loading = true; _erro = null; });
    try {
      await _reservaService.criar(
        espacoIds: _espacosSelecionados,
        data: _data,
        horaInicio: inicio,
        horaFim: fim,
        responsavelNome: _nomeController.text.trim(),
        numPessoas: int.tryParse(_pessoasController.text),
        duracaoTipo: _duracaoTipo,
        duracaoValor: _duracaoTipo == 'horas'
            ? (_horaFim.hour - _horaInicio.hour).toDouble()
            : double.tryParse(_pessoasController.text),
        valorTotal: _calcularValor(),
        observacoes: _observacoesController.text.trim().isEmpty
            ? null : _observacoesController.text.trim(),
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
                    if (picked != null) setState(() => _data = picked);
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
                          if (t != null) setState(() => _horaInicio = t);
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
                          if (t != null) setState(() => _horaFim = t);
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
                const SizedBox(height: 24),
                const Text('Espacos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._espacos.map((espaco) {
                  final selecionado = _espacosSelecionados.contains(espaco.id);
                  final podeSelecionar = selecionado || _podeSelecionar(espaco);
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
                      } : null,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: selecionado ? Colors.indigo.shade50 : Colors.white,
                          border: Border.all(
                            color: selecionado ? Colors.indigo : Colors.grey.shade300,
                            width: selecionado ? 2 : 1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)]),
                        child: Row(children: [
                          Icon(
                            selecionado ? Icons.check_box : Icons.check_box_outline_blank,
                            color: selecionado ? Colors.indigo : (podeSelecionar ? Colors.grey : Colors.grey.shade300)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(espaco.nome, style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: podeSelecionar ? Colors.black : Colors.grey.shade400)),
                              Row(children: [
                                if (espaco.combinavel)
                                  Text('Combinavel  ', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                                Text('R\$ ${ReservaService.valoresPorHora[espaco.nome]?.toStringAsFixed(0) ?? "100"}/hora',
                                  style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
                              ]),
                            ],
                          )),
                        ]),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Text('Numero de pessoas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _pessoasController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Quantas pessoas?',
                    prefixIcon: const Icon(Icons.group),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                const Text('Tipo de duracao', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _duracaoChip('horas', 'Por horas')),
                  const SizedBox(width: 12),
                  Expanded(child: _duracaoChip('dias', 'Por dias')),
                ]),
                const SizedBox(height: 16),
                const Text('Responsavel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    hintText: 'Nome do responsavel...',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                ),
                const SizedBox(height: 16),
                const Text('Observacoes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Valor estimado:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('R\$ ${valorEstimado.toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 20, color: Colors.indigo.shade900)),
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
                      Expanded(child: Text(_erro!, style: const TextStyle(color: Colors.red))),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                    label: Text(_loading ? 'Salvando...' : 'Confirmar Reserva',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }

  Widget _duracaoChip(String valor, String label) {
    final selecionado = _duracaoTipo == valor;
    return GestureDetector(
      onTap: () => setState(() => _duracaoTipo = valor),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selecionado ? Colors.indigo.shade900 : Colors.white,
          border: Border.all(color: Colors.indigo.shade900),
          borderRadius: BorderRadius.circular(12)),
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(
            color: selecionado ? Colors.white : Colors.indigo.shade900,
            fontWeight: FontWeight.bold)),
      ),
    );
  }
}
