class EspacoComum {
  final String id;
  final String nome;
  final bool combinavel;

  EspacoComum({
    required this.id,
    required this.nome,
    required this.combinavel,
  });

  factory EspacoComum.fromJson(Map<String, dynamic> json) {
    return EspacoComum(
      id: json['id'],
      nome: json['nome'],
      combinavel: json['combinavel'],
    );
  }
}
