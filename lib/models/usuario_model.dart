class UsuarioModel {
  final String? id;
  final String email;
  final String funcao;
  final String matricula;
  final String nome;
  final String senha;

  UsuarioModel({
    this.id,
    required this.email,
    required this.funcao,
    required this.matricula,
    required this.nome,
    required this.senha,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json, [String? id]) {
    return UsuarioModel(
      id: id,
      email: json['email'] ?? '',
      funcao: json['funcao'] ?? 'coletador',
      matricula: json['matricula'] ?? '',
      nome: json['nome'] ?? '',
      senha: json['senha'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'funcao': funcao,
      'matricula': matricula,
      'nome': nome,
      'senha': senha,
    };
  }

  UsuarioModel copyWith({
    String? id,
    String? email,
    String? funcao,
    String? matricula,
    String? nome,
    String? senha,
  }) {
    return UsuarioModel(
      id: id ?? this.id,
      email: email ?? this.email,
      funcao: funcao ?? this.funcao,
      matricula: matricula ?? this.matricula,
      nome: nome ?? this.nome,
      senha: senha ?? this.senha,
    );
  }
}
