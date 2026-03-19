import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../portaria/portaria_home_screen.dart';
import '../sala/sala_acesso_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _loading = false;
  String? _erro;

  Future<void> _login() async {
    setState(() { _loading = true; _erro = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const PortariaHomeScreen()));
      }
    } on AuthException catch (_) {
      setState(() => _erro = 'Email ou senha incorretos.');
    } catch (e) {
      setState(() => _erro = 'Erro ao conectar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade900,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              const Text('AR3000',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                    color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Acesso da Portaria',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.indigo.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Entrar', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Text('Sou empresa/sala',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SalaAcessoScreen())),
                  icon: const Icon(Icons.meeting_room, color: Colors.white70),
                  label: const Text('Acessar minhas encomendas',
                    style: TextStyle(color: Colors.white70)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
