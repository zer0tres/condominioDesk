class Reserva {
  final String id;
  final String? salaId;
  final List<String> espacoIds;
  final DateTime data;
  final String horaInicio;
  final String horaFim;
  final String responsavelNome;
  final int? numPessoas;
  final String? duracaoTipo;
  final double? duracaoValor;
  final double? valorTotal;
  final String? observacoes;
  final int? numCadeiras;
  final int? numMesas;
  final DateTime criadoEm;

  Reserva({
    required this.id,
    this.salaId,
    required this.espacoIds,
    required this.data,
    required this.horaInicio,
    required this.horaFim,
    required this.responsavelNome,
    this.numPessoas,
    this.duracaoTipo,
    this.duracaoValor,
    this.valorTotal,
    this.observacoes,
    this.numCadeiras,
    this.numMesas,
    required this.criadoEm,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) {
    return Reserva(
      id: json['id'],
      salaId: json['sala_id'],
      espacoIds: List<String>.from(json['espaco_ids']),
      data: DateTime.parse(json['data']),
      horaInicio: json['hora_inicio'],
      horaFim: json['hora_fim'],
      responsavelNome: json['responsavel_nome'],
      numPessoas: json['num_pessoas'],
      duracaoTipo: json['duracao_tipo'],
      duracaoValor: json['duracao_valor'] != null
          ? double.parse(json['duracao_valor'].toString()) : null,
      valorTotal: json['valor_total'] != null
          ? double.parse(json['valor_total'].toString()) : null,
      observacoes: json['observacoes'],
      numCadeiras: json['num_cadeiras'],
      numMesas: json['num_mesas'],
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }
}
