import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reserva.dart';
import '../models/espaco_comum.dart';

class ReservaService {
  final _supabase = Supabase.instance.client;

  // Valores por periodo de 2h
  static const Map<String, double> valoresPor2h = {
    'Sala 1': 105.0,
    'Sala 2': 105.0,
    'Sala 3': 150.0,
    'Sala de Reunioes': 105.0,
    'Copa': 50.0,
    'Coffe': 0.0,
  };

  // Limites de material por sala
  static const Map<String, Map<String, int>> limitesMaterial = {
    'Sala 1': {'cadeiras_max': 45, 'mesas_max': 12, 'cadeiras_conf1': 45, 'mesas_conf1': 1, 'cadeiras_conf2': 24, 'mesas_conf2': 12},
    'Sala 2': {'cadeiras_max': 45, 'mesas_max': 12, 'cadeiras_conf1': 45, 'mesas_conf1': 1, 'cadeiras_conf2': 24, 'mesas_conf2': 12},
    'Sala 3': {'cadeiras_max': 55, 'mesas_max': 14, 'cadeiras_conf1': 55, 'mesas_conf1': 1, 'cadeiras_conf2': 28, 'mesas_conf2': 14},
  };

  static const int totalCadeiras = 115;
  static const int totalMesas = 33;

  Future<List<EspacoComum>> listarEspacos() async {
    final response = await _supabase
        .from('espacos_comuns')
        .select()
        .order('nome');
    return response.map((e) => EspacoComum.fromJson(e)).toList();
  }

  Future<List<Reserva>> listarProximas() async {
    final hoje = DateTime.now().toIso8601String().split('T')[0];
    final response = await _supabase
        .from('reservas')
        .select('*, salas(numero, nome_empresa)')
        .gte('data', hoje)
        .order('data')
        .order('hora_inicio');
    return response.map((e) => Reserva.fromJson(e)).toList();
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

  // Calcula valor total baseado em periodos de 2h arredondados para cima
  double calcularValor(List<String> espacoIds, List<EspacoComum> espacos,
      String horaInicio, String horaFim) {
    final inicio = _timeToMinutes(horaInicio);
    final fim = _timeToMinutes(horaFim);
    final duracaoMin = fim - inicio;
    final periodos = (duracaoMin / 120.0).ceil();

    double total = 0;
    for (final id in espacoIds) {
      final espaco = espacos.where((e) => e.id == id).firstOrNull;
      if (espaco != null) {
        final valor = valoresPor2h[espaco.nome] ?? 105.0;
        total += valor * periodos;
      }
    }
    return total;
  }

  int _timeToMinutes(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  // Verifica se Copa/Coffe já foi reservada no dia por outro condômino
  Future<Map<String, bool>> verificarDisponibilidadeCopaCoffee(
      DateTime data, String? salaIdAtual) async {
    final dataStr = data.toIso8601String().split('T')[0];
    final response = await _supabase
        .from('reservas')
        .select('espaco_ids, sala_id')
        .eq('data', dataStr);

    final reservasDia = response as List;

    // Busca IDs de Copa e Coffe
    final espacos = await listarEspacos();
    final copaId = espacos.where((e) => e.nome == 'Copa').firstOrNull?.id;
    final coffeeId = espacos.where((e) => e.nome == 'Coffe').firstOrNull?.id;

    bool copaOcupada = false;
    bool coffeeOcupado = false;

    for (final r in reservasDia) {
      final ids = List<String>.from(r['espaco_ids']);
      final salaId = r['sala_id'];
      // Ignora reserva do proprio condomino
      if (salaId == salaIdAtual) continue;
      if (copaId != null && ids.contains(copaId)) copaOcupada = true;
      if (coffeeId != null && ids.contains(coffeeId)) coffeeOcupado = true;
    }

    return {'copa': copaOcupada, 'coffee': coffeeOcupado};
  }

  // Verifica material disponivel no horario
  Future<Map<String, int>> verificarMaterialDisponivel(
      DateTime data, String horaInicio, String horaFim,
      {String? ignorarReservaId}) async {
    final dataStr = data.toIso8601String().split('T')[0];
    var query = _supabase
        .from('material_reservado')
        .select()
        .eq('data', dataStr)
        .lt('hora_inicio', horaFim)
        .gt('hora_fim', horaInicio);

    final response = await query;
    int cadeirasUsadas = 0;
    int mesasUsadas = 0;

    for (final m in response) {
      if (ignorarReservaId != null && m['reserva_id'] == ignorarReservaId) continue;
      cadeirasUsadas += (m['num_cadeiras'] as int? ?? 0);
      mesasUsadas += (m['num_mesas'] as int? ?? 0);
    }

    return {
      'cadeiras': totalCadeiras - cadeirasUsadas,
      'mesas': totalMesas - mesasUsadas,
    };
  }

  // Calcula limites de material baseado nas salas selecionadas
  Map<String, int> calcularLimiteMaterial(
      List<String> espacoIds, List<EspacoComum> espacos) {
    int maxCadeiras = 0;
    int maxMesas = 0;

    for (final id in espacoIds) {
      final espaco = espacos.where((e) => e.id == id).firstOrNull;
      if (espaco != null && limitesMaterial.containsKey(espaco.nome)) {
        final limite = limitesMaterial[espaco.nome]!;
        maxCadeiras += limite['cadeiras_max']!;
        maxMesas += limite['mesas_max']!;
      }
    }
    // Nunca pode ultrapassar o total do prédio
    return {
      'cadeiras': maxCadeiras > totalCadeiras ? totalCadeiras : maxCadeiras,
      'mesas': maxMesas > totalMesas ? totalMesas : maxMesas,
    };
  }

  Future<bool> verificarConflito({
    required List<String> espacoIds,
    required DateTime data,
    required String horaInicio,
    required String horaFim,
    String? ignorarReservaId,
  }) async {
    final dataStr = data.toIso8601String().split('T')[0];

    // Adiciona 1h de intervalo de limpeza
    final fimComIntervalo = _adicionarHora(horaFim);

    final response = await _supabase
        .from('reservas')
        .select()
        .eq('data', dataStr)
        .lt('hora_inicio', fimComIntervalo)
        .gt('hora_fim', horaInicio);

    final reservas = response.map((e) => Reserva.fromJson(e)).toList();

    for (final reserva in reservas) {
      if (ignorarReservaId != null && reserva.id == ignorarReservaId) continue;
      for (final id in espacoIds) {
        if (reserva.espacoIds.contains(id)) return true;
      }
    }
    return false;
  }

  String _adicionarHora(String hora) {
    final parts = hora.split(':');
    int h = int.parse(parts[0]) + 1;
    if (h >= 24) h = 23;
    return '${h.toString().padLeft(2, '0')}:${parts[1]}:00';
  }

  Future<void> criar({
    required List<String> espacoIds,
    required DateTime data,
    required String horaInicio,
    required String horaFim,
    required String responsavelNome,
    String? salaId,
    int? numPessoas,
    double? valorTotal,
    String? observacoes,
    int numCadeiras = 0,
    int numMesas = 0,
  }) async {
    final conflito = await verificarConflito(
      espacoIds: espacoIds,
      data: data,
      horaInicio: horaInicio,
      horaFim: horaFim,
    );
    if (conflito) {
      throw Exception('Horario conflita com reserva existente ou intervalo de limpeza.');
    }

    final reservaId = await _supabase.from('reservas').insert({
      'espaco_ids': espacoIds,
      'data': data.toIso8601String().split('T')[0],
      'hora_inicio': horaInicio,
      'hora_fim': horaFim,
      'responsavel_nome': responsavelNome,
      'sala_id': salaId,
      'num_pessoas': numPessoas,
      'valor_total': valorTotal,
      'observacoes': observacoes,
      'num_cadeiras': numCadeiras,
      'num_mesas': numMesas,
    }).select('id').single();

    // Registra material reservado
    if (numCadeiras > 0 || numMesas > 0) {
      await _supabase.from('material_reservado').insert({
        'reserva_id': reservaId['id'],
        'data': data.toIso8601String().split('T')[0],
        'hora_inicio': horaInicio,
        'hora_fim': horaFim,
        'num_cadeiras': numCadeiras,
        'num_mesas': numMesas,
      });
    }
  }

  Future<void> cancelar(String reservaId) async {
    await _supabase.from('reservas').delete().eq('id', reservaId);
  }

  Future<bool> podeCancelar(String reservaId) async {
    final response = await _supabase
        .from('reservas')
        .select('data')
        .eq('id', reservaId)
        .single();
    final data = DateTime.parse(response['data']);
    final limite = DateTime.now().add(const Duration(hours: 48));
    return data.isAfter(limite);
  }
}
