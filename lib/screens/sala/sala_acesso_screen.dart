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
  final _numeroController = TextEditingController();
  final _senhaController = TextEditingController();
  final _salaService = SalaService();
  bool _loading = false;
  bool _senhaVisivel = false;
  String? _erro;

  Future<void> _acessar() async {
    final numero = _numeroController.text.trim();
    final senha = _senhaController.text.trim();

    if (numero.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Preencha todos os campos.');
      return;
    }

    final n = int.tryParse(numero);
    final andar = n != null ? n ~/ 100 : 0;
    final salaNum = n != null ? n % 100 : 0;
    if (n == null || andar < 4 || andar > 25 || salaNum < 1 || salaNum > 10) {
      setState(() => _erro = 'Numero de sala invalido.');
      return;
    }

    setState(() { _loading = true; _erro = null; });
    try {
      final Sala? sala = await _salaService.autenticar(numero, senha);
      if (!mounted) return;
      if (sala == null) {
        setState(() => _erro = 'Numero ou senha incorretos.');
      } else if (sala.isPrimeiroAcesso) {
        _mostrarDialogNovaSenha(sala);
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

  void _mostrarDialogNovaSenha(Sala sala) {
    final novaSenhaController = TextEditingController();
    final confirmarController = TextEditingController();
    String? erroDialog;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Primeiro acesso'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Crie sua senha pessoal para acessar suas encomendas.'),
              const SizedBox(height: 16),
              TextField(
                controller: novaSenhaController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmarController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar senha',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12))),
              ),
              if (erroDialog != null) ...[
                const SizedBox(height: 8),
                Text(erroDialog!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final nova = novaSenhaController.text.trim();
                final confirmar = confirmarController.text.trim();
                if (nova.length < 4) {
                  setStateDialog(() => erroDialog = 'Senha muito curta (min. 4 caracteres).');
                  return;
                }
                if (nova != confirmar) {
                  setStateDialog(() => erroDialog = 'As senhas nao coincidem.');
                  return;
                }
                await _salaService.atualizarSenha(sala.id, nova);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => SalaHomeScreen(sala: sala)));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade900),
              child: const Text('Salvar senha', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
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
              const Text('Digite o numero e senha da sua sala',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 48),
              TextField(
                controller: _numeroController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 28,
                    fontWeight: FontWeight.bold, letterSpacing: 4),
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: '401',
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 28),
                  counterText: '',
                  labelText: 'Numero da sala',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30, width: 2),
                    borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: !_senhaVisivel,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: const TextStyle(color: Colors.white70),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white70),
                    onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                  ),
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
