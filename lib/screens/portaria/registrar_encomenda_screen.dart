import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/sala.dart';
import '../../services/sala_service.dart';
import '../../services/encomenda_service.dart';

class RegistrarEncomendaScreen extends StatefulWidget {
  final Sala? sala;
  const RegistrarEncomendaScreen({super.key, this.sala});

  @override
  State<RegistrarEncomendaScreen> createState() =>
      _RegistrarEncomendaScreenState();
}

class _RegistrarEncomendaScreenState extends State<RegistrarEncomendaScreen> {
  final _nomeController = TextEditingController();
  final _codigoController = TextEditingController();
  final _buscaSalaController = TextEditingController();
  final _salaService = SalaService();
  final _encomendaService = EncomendaService();

  Sala? _salaSelecionada;
  File? _foto;
  bool _loading = false;
  bool _buscandoSala = false;
  List<Sala> _resultadosSala = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    if (widget.sala != null) {
      _salaSelecionada = widget.sala;
      _buscaSalaController.text =
          '${widget.sala!.numero} - ${widget.sala!.displayName}';
    }
  }

  Future<void> _tirarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.camera, imageQuality: 70, maxWidth: 1024);
    if (picked != null) setState(() => _foto = File(picked.path));
  }

  Future<void> _buscarSala(String termo) async {
    if (termo.isEmpty) {
      setState(() => _resultadosSala = []);
      return;
    }
    setState(() => _buscandoSala = true);
    try {
      List<Sala> r;
      if (int.tryParse(termo) != null) {
        final s = await _salaService.buscarPorNumero(termo);
        r = s != null ? [s] : [];
      } else {
        r = await _salaService.buscarPorNome(termo);
      }
      setState(() => _resultadosSala = r);
    } finally {
      setState(() => _buscandoSala = false);
    }
  }

  Future<void> _salvar() async {
    if (_salaSelecionada == null) {
      setState(() => _erro = 'Selecione uma sala.');
      return;
    }
    if (_nomeController.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o nome do destinatario.');
      return;
    }
    setState(() { _loading = true; _erro = null; });
    try {
      await _encomendaService.registrar(
        salaId: _salaSelecionada!.id,
        nomeDestinatario: _nomeController.text.trim(),
        codigoRastreio: _codigoController.text.trim().isEmpty
            ? null : _codigoController.text.trim(),
        foto: _foto,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Encomenda registrada com sucesso!'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _erro = 'Erro ao registrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Encomenda'),
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sala destinataria',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _buscaSalaController,
              onChanged: (v) {
                if (_salaSelecionada != null) {
                  setState(() => _salaSelecionada = null);
                }
                _buscarSala(v);
              },
              decoration: InputDecoration(
                hintText: 'Numero ou nome da empresa...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscandoSala
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
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
                    subtitle: Text('Sala ${sala.numero}'),
                    onTap: () {
                      setState(() {
                        _salaSelecionada = sala;
                        _buscaSalaController.text =
                            '${sala.numero} - ${sala.displayName}';
                        _resultadosSala = [];
                      });
                    },
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
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sala ${_salaSelecionada!.numero} - ${_salaSelecionada!.displayName}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text('Destinatario',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                hintText: 'Nome de quem vai retirar...',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Codigo / Rastreio',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                hintText: 'Codigo da transportadora (opcional)...',
                prefixIcon: const Icon(Icons.qr_code),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Foto da Encomenda',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _tirarFoto,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12)),
                child: _foto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_foto!, fit: BoxFit.cover))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt,
                          size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Toque para tirar foto',
                          style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
              ),
            ),
            if (_foto != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _foto = null),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Remover foto',
                  style: TextStyle(color: Colors.red)),
              ),
            ],
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: Colors.red)),
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
                    borderRadius: BorderRadius.circular(12)),
                ),
                icon: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
                label: Text(
                  _loading ? 'Salvando...' : 'Registrar Encomenda',
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
