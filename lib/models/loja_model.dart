class LojaModel {
  final String? id;
  final String nome;
  final String cnpj;
  final String endereco;
  final String imagemUrl;
  final bool ativo;

  LojaModel({
    this.id,
    required this.nome,
    required this.cnpj,
    required this.endereco,
    required this.imagemUrl,
    this.ativo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'cnpj': cnpj,
      'endereco': endereco,
      'imagemUrl': imagemUrl,
      'ativo': ativo,
    };
  }

  factory LojaModel.fromMap(Map<String, dynamic> map, String id) {
    return LojaModel(
      id: id,
      nome: map['nome'] ?? '',
      cnpj: map['cnpj'] ?? '',
      endereco: map['endereco'] ?? '',
      imagemUrl: map['imagemUrl'] ?? '',
      ativo: map['ativo'] ?? true,
    );
  }
}
