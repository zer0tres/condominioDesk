class Encomenda {
  final String id;
  final String salaId;
  final String nomeDestinatario;
  final String? codigoRastreio;
  final String? fotoUrl;
  final DateTime? fotoExpiraEm;
  final String status;
  final DateTime criadoEm;
  final DateTime? retiradoEm;
  final String? retiradoPor;
  final String? salaNumero;
  final String? salaNomeEmpresa;

  Encomenda({
    required this.id,
    required this.salaId,
    required this.nomeDestinatario,
    this.codigoRastreio,
    this.fotoUrl,
    this.fotoExpiraEm,
    required this.status,
    required this.criadoEm,
    this.retiradoEm,
    this.retiradoPor,
    this.salaNumero,
    this.salaNomeEmpresa,
  });

  factory Encomenda.fromJson(Map<String, dynamic> json) {
    return Encomenda(
      id: json['id'],
      salaId: json['sala_id'],
      nomeDestinatario: json['nome_destinatario'],
      codigoRastreio: json['codigo_rastreio'],
      fotoUrl: json['foto_url'],
      fotoExpiraEm: json['foto_expira_em'] != null
          ? DateTime.parse(json['foto_expira_em'])
          : null,
      status: json['status'],
      criadoEm: DateTime.parse(json['criado_em']),
      retiradoEm: json['retirado_em'] != null
          ? DateTime.parse(json['retirado_em'])
          : null,
      retiradoPor: json['retirado_por'],
      salaNumero: json['salas']?['numero'],
      salaNomeEmpresa: json['salas']?['nome_empresa'],
    );
  }

  String get salaDisplay {
    if (salaNomeEmpresa != null) return 'Sala $salaNumero — $salaNomeEmpresa';
    if (salaNumero != null) return 'Sala $salaNumero';
    return 'Sala desconhecida';
  }

  bool get isPendente => status == 'pendente';
}
