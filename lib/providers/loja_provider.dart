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

  List<LojaModel> _lojas = [];
  List<LojaModel> _filteredLojas = [];
  List<LojaModel> get lojas => _filteredLojas;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchLojas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Usando stream para tempo real ou get para uma única vez. 
      // Requisito pede "carregar dados", vamos usar get para facilitar o filtro local inicial.
      // Mas o Repository tem getLojas() como Stream. Vou adaptar.
      _repository.getLojas().listen((lojasList) {
        _lojas = lojasList;
        _filteredLojas = lojasList;
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        _errorMessage = 'Erro ao carregar lojas: $e';
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      _errorMessage = 'Erro inesperado: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterLojas(String query) {
    if (query.isEmpty) {
      _filteredLojas = _lojas;
    } else {
      _filteredLojas = _lojas.where((loja) {
        final nome = loja.nome.toLowerCase();
        final endereco = loja.endereco.toLowerCase();
        final search = query.toLowerCase();
        return nome.contains(search) || endereco.contains(search);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> deleteLoja(String id) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _repository.deleteLoja(id);
    } catch (e) {
      _errorMessage = 'Erro ao excluir loja: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveLoja({
    required String nome,
    required String cnpj,
    required String endereco,
    File? imageFile,
    String? existingImageUrl,
    String? id,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? finalImageUrl = existingImageUrl;

      if (imageFile != null) {
        finalImageUrl = await _cloudinaryService.uploadImage(imageFile, folder: 'lojas');
      }
      
      if (finalImageUrl == null) {
        throw Exception('Imagem é obrigatória');
      }

      final loja = LojaModel(
        id: id,
        nome: nome,
        cnpj: cnpj,
        endereco: endereco,
        imagemUrl: finalImageUrl,
      );

      if (id == null) {
        await _repository.addLoja(loja);
      } else {
        await _repository.updateLoja(loja);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
