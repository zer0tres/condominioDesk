import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reserva.dart';
import '../models/espaco_comum.dart';

class ReservaService {
  final _supabase = Supabase.instance.client;

  Future<List<EspacoComum>> listarEspacos() async {
    final response = await _supabase
        .from('espacos_comuns')
        .select()
        .order('nome');
    return response.map((e) => EspacoComum.fromJson(e)).toList();
  }

  Future<List<Reserva>> listarPorData(DateTime data) async {
    final dataStr = data.toIso8601String().split('T')[0];
    final response = await _supabase
        .from('reservas')
        .select()
        .eq('data', dataStr)
        .order('hora_inicio');
    return response.map((e) => Reserva.fromJson(e)).toList();
  }

  Future<bool> verificarConflito({
    required List<String> espacoIds,
    required DateTime data,
    required String horaInicio,
    required String horaFim,
    String? ignorarReservaId,
  }) async {
    final dataStr = data.toIso8601String().split('T')[0];
    var query = _supabase
        .from('reservas')
        .select()
        .eq('data', dataStr)
        .lt('hora_inicio', horaFim)
        .gt('hora_fim', horaInicio);

    final response = await query;
    final reservas = response.map((e) => Reserva.fromJson(e)).toList();

    for (final reserva in reservas) {
      if (ignorarReservaId != null && reserva.id == ignorarReservaId) continue;
      for (final id in espacoIds) {
        if (reserva.espacoIds.contains(id)) return true;
      }
    }
    return false;
  }

  Future<void> criar({
    required List<String> espacoIds,
    required DateTime data,
    required String horaInicio,
    required String horaFim,
    required String responsavelNome,
    String? salaId,
  }) async {
    final conflito = await verificarConflito(
      espacoIds: espacoIds,
      data: data,
      horaInicio: horaInicio,
      horaFim: horaFim,
    );
    if (conflito) throw Exception('Horario conflita com reserva existente.');

    await _supabase.from('reservas').insert({
      'espaco_ids': espacoIds,
      'data': data.toIso8601String().split('T')[0],
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'responsavel_nome': responsavelNome,
      'sala_id': salaId,
    });
  }

  Future<void> cancelar(String reservaId) async {
    await _supabase.from('reservas').delete().eq('id', reservaId);
  }
}
