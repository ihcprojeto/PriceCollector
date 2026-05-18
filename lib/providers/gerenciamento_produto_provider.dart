import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/produto_model.dart';
import '../models/demanda_model.dart';
import '../repositories/produto_repository.dart';

class GerenciamentoProdutoProvider with ChangeNotifier {
  final ProdutoRepository _repository = ProdutoRepository();

  List<ProdutoModel> _produtos = [];
  List<ProdutoModel> _filteredProdutos = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProdutoModel> get produtos => _filteredProdutos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String _orderBy = 'Nome';
  final Set<String> _selectedBarcodes = {};

  Set<String> get selectedBarcodes => _selectedBarcodes;

  Future<void> fetchProdutos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.getTodosProdutos();
      
      // Para cada produto, buscar em quantas lojas ele está presente
      // Otimização: Em bases grandes, isso deveria ser feito via Cloud Function ou agregação
      List<ProdutoModel> finalData = [];
      for (var p in data) {
        final totalLojas = await _repository.getContagemLojasDoProduto(p.barcode);
        finalData.add(p.copyWith(totalLojas: totalLojas));
      }
      
      _produtos = finalData;
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Erro ao carregar catálogo: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setOrderBy(String order) {
    _orderBy = order;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredProdutos = _produtos.where((p) {
      final search = _searchQuery.toLowerCase();
      return p.nome.toLowerCase().contains(search) ||
          p.marca.toLowerCase().contains(search) ||
          p.descricao.toLowerCase().contains(search) ||
          p.barcode.contains(search);
    }).toList();

    if (_orderBy == 'Nome') {
      _filteredProdutos.sort((a, b) => a.nome.compareTo(b.nome));
    } else {
      _filteredProdutos.sort((a, b) => a.marca.compareTo(b.marca));
    }
    notifyListeners();
  }

  void toggleSelection(String barcode) {
    if (_selectedBarcodes.contains(barcode)) {
      _selectedBarcodes.remove(barcode);
    } else {
      _selectedBarcodes.add(barcode);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedBarcodes.clear();
    notifyListeners();
  }

  Future<bool> excluirSelecionados() async {
    _isLoading = true;
    notifyListeners();
    try {
      for (var barcode in _selectedBarcodes) {
        await _repository.excluirProdutoPermanente(barcode);
      }
      await fetchProdutos();
      clearSelection();
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao excluir produtos: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, int>> adicionarEmLojas(List<String> lojaIds) async {
    _isLoading = true;
    notifyListeners();

    int adicionados = 0;
    int ignorados = 0;
    int falhas = 0;

    try {
      final selectedProds = _produtos.where((p) => _selectedBarcodes.contains(p.barcode)).toList();
      
      for (var lojaId in lojaIds) {
        for (var prod in selectedProds) {
          try {
            // Verifica se já existe na loja
            final existente = await _repository.getDemandaByBarcode(lojaId, prod.barcode);
            if (existente != null) {
              ignorados++;
              continue;
            }

            final demanda = DemandaModel(
              id: prod.barcode,
              barcode: prod.barcode,
              produtoNome: prod.nome,
              produtoMarca: prod.marca,
              produtoDescricao: prod.descricao,
              produtoImagemUrl: prod.imagemUrl,
              status: 'pendente',
            );

            await FirebaseFirestore.instance
                .collection('lojas')
                .doc(lojaId)
                .collection('demandas')
                .doc(prod.barcode)
                .set(demanda.toMap());
            
            adicionados++;
          } catch (e) {
            falhas++;
          }
        }
      }
      await fetchProdutos();
      clearSelection();
      return {'adicionados': adicionados, 'ignorados': ignorados, 'falhas': falhas};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, int>> importarExcel() async {
    _isLoading = true;
    notifyListeners();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return {};

      final bytes = result.files.first.bytes;
      List<int> fileBytes;
      if (bytes != null) {
        fileBytes = bytes;
      } else {
        final path = result.files.first.path;
        if (path != null) {
          fileBytes = await File(path).readAsBytes();
        } else {
          throw 'Não foi possível ler o arquivo';
        }
      }

      var excel = Excel.decodeBytes(fileBytes);
      var table = excel.tables.values.first;
      
      int adicionados = 0;
      int ignorados = 0;

      for (var i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.isEmpty) continue;

        String getVal(int idx) => idx < row.length ? (row[idx]?.value?.toString().trim() ?? '') : '';

        final barcode = getVal(0);
        if (barcode.isEmpty) continue;

        // Verifica duplicidade global
        final doc = await FirebaseFirestore.instance.collection('produtos').doc(barcode).get();
        if (doc.exists) {
          ignorados++;
          continue;
        }

        final prod = ProdutoModel(
          barcode: barcode,
          nome: getVal(1),
          marca: getVal(2),
          descricao: getVal(3),
          imagemUrl: getVal(4),
        );

        await FirebaseFirestore.instance.collection('produtos').doc(barcode).set(prod.toMap());
        adicionados++;
      }

      await fetchProdutos();
      return {'adicionados': adicionados, 'ignorados': ignorados};
    } catch (e) {
      _errorMessage = 'Erro na importação: $e';
      return {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
