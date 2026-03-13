class Reserva {
  final String id;
  final String? salaId;
  final List<String> espacoIds;
  final DateTime data;
  final String horaInicio;
  final String horaFim;
  final String responsavelNome;
  final DateTime criadoEm;

  Reserva({
    required this.id,
    this.salaId,
    required this.espacoIds,
    required this.data,
    required this.horaInicio,
    required this.horaFim,
    required this.responsavelNome,
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
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }
}
