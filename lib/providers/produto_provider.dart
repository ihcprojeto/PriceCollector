import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/coleta_model.dart';
import '../models/demanda_model.dart';
import '../repositories/produto_repository.dart';
import '../repositories/coleta_repository.dart';

class ProdutoProvider with ChangeNotifier {
  final ProdutoRepository _repository = ProdutoRepository();
  final ColetaRepository _coletaRepository = ColetaRepository();

  List<DemandaModel> _demandas = [];
  List<DemandaModel> _filteredDemandas = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<DemandaModel> get demandas => _filteredDemandas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String _searchQuery = '';
  String _statusFilter = 'Geral';

  int get totalColetados => _demandas.where((d) => d.status == 'coletado').length;
  int get totalDemandas => _demandas.where((d) => d.status != 'cancelado').length;

  void fetchDemandas(String lojaId) {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _repository.getDemandas(lojaId).listen((data) {
      _demandas = data;
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _errorMessage = 'Erro ao carregar demandas: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredDemandas = _demandas.where((d) {
      final matchesSearch = d.produtoNome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.produtoMarca.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.barcode.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesStatus = _statusFilter == 'Geral' || d.status.toLowerCase() == _statusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
    notifyListeners();
  }

  Future<void> cancelarDemanda(String lojaId, String demandaId) async {
    try {
      await _repository.atualizarStatusDemanda(lojaId, demandaId, 'cancelado');
    } catch (e) {
      _errorMessage = 'Erro ao cancelar demanda: $e';
      notifyListeners();
    }
  }

  Future<DemandaModel?> validarBarcode(String lojaId, String barcode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final demanda = await _repository.getDemandaByBarcode(lojaId, barcode);
      return demanda;
    } catch (e) {
      _errorMessage = 'Erro ao validar código: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> salvarColeta({
    required ColetaModel coleta,
    required String demandaId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _coletaRepository.salvarColeta(coleta, demandaId);
      return true;
    } catch (e) {
      _errorMessage = 'Erro ao salvar coleta: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importarCSV(String lojaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        final bytes = result.files.first.bytes;
        String csvString;
        if (bytes != null) {
          csvString = utf8.decode(bytes);
        } else {
          final path = result.files.first.path;
          if (path != null) {
            csvString = await File(path).readAsString();
          } else {
            throw 'Não foi possível ler o arquivo';
          }
        }

        List<List<dynamic>> rows = const CsvToListConverter().convert(csvString);
        
        if (rows.isEmpty) throw 'O arquivo CSV está vazio';

        // Assuming structure: barcode, nome, marca, descricao, imagemUrl
        List<DemandaModel> novasDemandas = [];
        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          if (row.length < 5) continue;

          novasDemandas.add(DemandaModel(
            id: '',
            barcode: row[0].toString(),
            produtoNome: row[1].toString(),
            produtoMarca: row[2].toString(),
            produtoDescricao: row[3].toString(),
            produtoImagemUrl: row[4].toString(),
            status: 'pendente',
          ));
        }

        if (novasDemandas.isNotEmpty) {
          await _repository.importarDemandas(lojaId, novasDemandas);
        }
      }
    } catch (e) {
      _errorMessage = 'Erro na importação: $e';
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
