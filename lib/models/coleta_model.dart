class ColetaModel {
  final String? id;
  final DateTime dataColeta;
  final String dispositivoId;
  final String dispositivoModelo;
  final String lojaId;
  final String lojaNome;
  final double preco;
  final String produtoBarcode;
  final String produtoNome;
  final String? produtoImagemUrl;
  final String usuarioId;
  final String usuarioMatricula;
  final String usuarioNome;

  ColetaModel({
    this.id,
    required this.dataColeta,
    required this.dispositivoId,
    required this.dispositivoModelo,
    required this.lojaId,
    required this.lojaNome,
    required this.preco,
    required this.produtoBarcode,
    required this.produtoNome,
    this.produtoImagemUrl,
    required this.usuarioId,
    required this.usuarioMatricula,
    required this.usuarioNome,
  });

  Map<String, dynamic> toMap() {
    return {
      'dataColeta': dataColeta.toIso8601String(),
      'dispositivoId': dispositivoId,
      'dispositivoModelo': dispositivoModelo,
      'lojaId': lojaId,
      'lojaNome': lojaNome,
      'preco': preco,
      'produtoBarcode': produtoBarcode,
      'produtoNome': produtoNome,
      'produtoImagemUrl': produtoImagemUrl,
      'usuarioId': usuarioId,
      'usuarioMatricula': usuarioMatricula,
      'usuarioNome': usuarioNome,
    };
  }

  factory ColetaModel.fromFirestore(Map<String, dynamic> json, String id) {
    return ColetaModel(
      id: id,
      dataColeta: DateTime.parse(json['dataColeta']),
      dispositivoId: json['dispositivoId'] ?? '',
      dispositivoModelo: json['dispositivoModelo'] ?? '',
      lojaId: json['lojaId'] ?? '',
      lojaNome: json['lojaNome'] ?? '',
      preco: (json['preco'] ?? 0.0).toDouble(),
      produtoBarcode: json['produtoBarcode'] ?? '',
      produtoNome: json['produtoNome'] ?? '',
      produtoImagemUrl: json['produtoImagemUrl'],
      usuarioId: json['usuarioId'] ?? '',
      usuarioMatricula: json['usuarioMatricula'] ?? '',
      usuarioNome: json['usuarioNome'] ?? '',
    );
  }
}
