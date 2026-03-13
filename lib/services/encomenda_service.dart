import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/encomenda.dart';

class EncomendaService {
  final _supabase = Supabase.instance.client;

  Future<List<Encomenda>> listarPorSala(String salaId) async {
    final response = await _supabase
        .from('encomendas')
        .select()
        .eq('sala_id', salaId)
        .order('criado_em', ascending: false);
    return response.map((e) => Encomenda.fromJson(e)).toList();
  }

  Future<List<Encomenda>> listarPendentes() async {
    final response = await _supabase
        .from('encomendas')
        .select()
        .eq('status', 'pendente')
        .order('criado_em', ascending: false);
    return response.map((e) => Encomenda.fromJson(e)).toList();
  }

  Future<void> registrar({
    required String salaId,
    required String nomeDestinatario,
    String? codigoRastreio,
    File? foto,
  }) async {
    String? fotoUrl;
    final expiraEm = DateTime.now().add(const Duration(days: 120));

    if (foto != null) {
      final fileName = '${salaId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('encomendas').upload(fileName, foto);
      fotoUrl = _supabase.storage.from('encomendas').getPublicUrl(fileName);
    }

    await _supabase.from('encomendas').insert({
      'sala_id': salaId,
      'nome_destinatario': nomeDestinatario,
      'codigo_rastreio': codigoRastreio,
      'foto_url': fotoUrl,
      'foto_expira_em': expiraEm.toIso8601String(),
      'status': 'pendente',
    });

    // Dispara notificacao push para a sala
    try {
      await _supabase.functions.invoke('notify-encomenda', body: {
        'sala_id': salaId,
        'nome_destinatario': nomeDestinatario,
        'codigo_rastreio': codigoRastreio,
      });
    } catch (_) {
      // Notificacao falhou mas encomenda foi registrada
    }
  }

  Future<void> marcarRetirada(String encomendaId) async {
    await _supabase.from('encomendas').update({
      'status': 'retirada',
      'retirado_em': DateTime.now().toIso8601String(),
    }).eq('id', encomendaId);
  }
}
