import 'package:flutter/material.dart';
import '../../services/sala_service.dart';
import '../../models/sala.dart';
import 'sala_home_screen.dart';

class SalaAcessoScreen extends StatefulWidget {
  const SalaAcessoScreen({super.key});

  @override
  State<SalaAcessoScreen> createState() => _SalaAcessoScreenState();
}

class _SalaAcessoScreenState extends State<SalaAcessoScreen> {
  final _codigoController = TextEditingController();
  final _salaService = SalaService();
  bool _loading = false;
  String? _erro;

  Future<void> _acessar() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      setState(() => _erro = 'Digite o número da sala.');
      return;
    }

    // Valida se é um número de sala válido (andar 4-25, sala 01-10)
    final numero = int.tryParse(codigo);
    bool salaValida = false;
    if (numero != null) {
      final andar = numero ~/ 100;
      final sala = numero % 100;
      salaValida = andar >= 4 && andar <= 25 && sala >= 1 && sala <= 10;
    }
    if (!salaValida) {
      setState(() => _erro = 'Sala inválida. Ex: 401, 1203, 2510.');
      return;
    }

    setState(() { _loading = true; _erro = null; });

    try {
      final Sala? sala = await _salaService.buscarPorNumero(codigo);
      if (!mounted) return;

      if (sala == null) {
        setState(() => _erro = 'Sala não encontrada. Fale com a portaria.');
      } else {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => SalaHomeScreen(sala: sala)));
      }
    } catch (_) {
      setState(() => _erro = 'Erro ao conectar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.meeting_room, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              const Text('Acesso da Sala',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                    color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Digite o número da sua sala',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 48),
              TextField(
                controller: _codigoController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.bold, letterSpacing: 8),
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: '401',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 32),
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30, width: 2),
                    borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16)),
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(_erro!, style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _acessar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.teal.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Acessar', style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
