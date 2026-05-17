class DispositivoModel {
  final String id;
  final String marca;
  final String modelo;
  final String serial;
  final bool ativo;

  DispositivoModel({
    required this.id,
    required this.marca,
    required this.modelo,
    required this.serial,
    this.ativo = true,
  });

  factory DispositivoModel.fromFirestore(Map<String, dynamic> json, String id) {
    return DispositivoModel(
      id: id,
      marca: json['marca'] ?? '',
      modelo: json['modelo'] ?? '',
      serial: json['serial'] ?? '',
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'marca': marca,
      'modelo': modelo,
      'serial': serial,
      'ativo': ativo,
    };
  }

  String get displayName => '$marca $modelo ($serial)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DispositivoModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
