import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sala.dart';

class SalaService {
  final _supabase = Supabase.instance.client;

  Future<Sala?> buscarPorNumero(String numero) async {
    final response = await _supabase
        .from('salas')
        .select()
        .eq('numero', numero)
        .maybeSingle();
    if (response == null) return null;
    return Sala.fromJson(response);
  }

  Future<List<Sala>> buscarPorNome(String nome) async {
    final response = await _supabase
        .from('salas')
        .select()
        .ilike('nome_empresa', '%$nome%')
        .order('numero');
    return response.map((e) => Sala.fromJson(e)).toList();
  }

  Future<List<Sala>> listarTodas() async {
    final response = await _supabase
        .from('salas')
        .select()
        .order('numero');
    return response.map((e) => Sala.fromJson(e)).toList();
  }

  Future<void> atualizarFcmToken(String salaId, String token) async {
    await _supabase
        .from('salas')
        .update({'fcm_token': token})
        .eq('id', salaId);
  }
}
