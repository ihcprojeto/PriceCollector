import 'dart:io';
import 'package:flutter/material.dart';
import '../models/loja_model.dart';
import '../repositories/loja_repository.dart';
import '../services/cloudinary_service.dart';

class LojaProvider extends ChangeNotifier {
  final LojaRepository _repository = LojaRepository();
  final CloudinaryService _cloudinaryService = CloudinaryService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> saveLoja({
    required String nome,
    required String cnpj,
    required String endereco,
    required File imageFile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Upload imagem
      final imageUrl = await _cloudinaryService.uploadImage(imageFile, folder: 'lojas');
      
      if (imageUrl == null) {
        throw Exception('Falha ao fazer upload da imagem para o Cloudinary');
      }

      // 2. Salvar no Firestore
      final novaLoja = LojaModel(
        nome: nome,
        cnpj: cnpj,
        endereco: endereco,
        imagemUrl: imageUrl,
      );

      await _repository.addLoja(novaLoja);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
