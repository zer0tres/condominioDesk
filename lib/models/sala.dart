class Sala {
  final String id;
  final String numero;
  final String? nomeEmpresa;
  final String? fcmToken;
  final DateTime criadoEm;

  Sala({
    required this.id,
    required this.numero,
    this.nomeEmpresa,
    this.fcmToken,
    required this.criadoEm,
  });

  factory Sala.fromJson(Map<String, dynamic> json) {
    return Sala(
      id: json['id'],
      numero: json['numero'],
      nomeEmpresa: json['nome_empresa'],
      fcmToken: json['fcm_token'],
      criadoEm: DateTime.parse(json['criado_em']),
    );
  }

  String get displayName => nomeEmpresa ?? 'Sala $numero';
}
