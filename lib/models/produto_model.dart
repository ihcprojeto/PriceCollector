class ProdutoModel {
  final String barcode;
  final String nome;
  final String marca;
  final String descricao;
  final String imagemUrl;
  final int totalLojas; // Calculado em tempo de execução ou via agregação

  ProdutoModel({
    required this.barcode,
    required this.nome,
    required this.marca,
    required this.descricao,
    required this.imagemUrl,
    this.totalLojas = 0,
  });

  factory ProdutoModel.fromFirestore(Map<String, dynamic> json) {
    return ProdutoModel(
      barcode: json['barcode'] ?? '',
      nome: json['nome'] ?? '',
      marca: json['marca'] ?? '',
      descricao: json['descricao'] ?? '',
      imagemUrl: json['imagemUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'nome': nome,
      'marca': marca,
      'descricao': descricao,
      'imagemUrl': imagemUrl,
    };
  }

  ProdutoModel copyWith({
    String? barcode,
    String? nome,
    String? marca,
    String? descricao,
    String? imagemUrl,
    int? totalLojas,
  }) {
    return ProdutoModel(
      barcode: barcode ?? this.barcode,
      nome: nome ?? this.nome,
      marca: marca ?? this.marca,
      descricao: descricao ?? this.descricao,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      totalLojas: totalLojas ?? this.totalLojas,
    );
  }
}
