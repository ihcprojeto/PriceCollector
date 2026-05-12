class DemandaModel {
  final String id;
  final String barcode;
  final String produtoDescricao;
  final String produtoImagemUrl;
  final String produtoMarca;
  final String produtoNome;
  final String status; // 'pendente', 'coletado', 'cancelado'

  DemandaModel({
    required this.id,
    required this.barcode,
    required this.produtoDescricao,
    required this.produtoImagemUrl,
    required this.produtoMarca,
    required this.produtoNome,
    required this.status,
  });

  factory DemandaModel.fromFirestore(Map<String, dynamic> json, String id) {
    return DemandaModel(
      id: id,
      barcode: json['barcode'] ?? '',
      produtoDescricao: json['produtoDescricao'] ?? '',
      produtoImagemUrl: json['produtoImagemUrl'] ?? '',
      produtoMarca: json['produtoMarca'] ?? '',
      produtoNome: json['produtoNome'] ?? '',
      status: json['status'] ?? 'pendente',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'produtoDescricao': produtoDescricao,
      'produtoImagemUrl': produtoImagemUrl,
      'produtoMarca': produtoMarca,
      'produtoNome': produtoNome,
      'status': status,
    };
  }

  DemandaModel copyWith({
    String? status,
  }) {
    return DemandaModel(
      id: id,
      barcode: barcode,
      produtoDescricao: produtoDescricao,
      produtoImagemUrl: produtoImagemUrl,
      produtoMarca: produtoMarca,
      produtoNome: produtoNome,
      status: status ?? this.status,
    );
  }
}
