import 'dart:io';
import 'package:excel/excel.dart';
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
          d.produtoDescricao.toLowerCase().contains(_searchQuery.toLowerCase()) ||
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

  Future<void> reativarDemanda(String lojaId, String demandaId) async {
    try {
      await _repository.atualizarStatusDemanda(lojaId, demandaId, 'pendente');
    } catch (e) {
      _errorMessage = 'Erro ao reativar demanda: $e';
      notifyListeners();
    }
  }

  Future<void> deletarDemanda(String lojaId, String demandaId) async {
    try {
      await _repository.deletarDemanda(lojaId, demandaId);
    } catch (e) {
      _errorMessage = 'Erro ao deletar demanda: $e';
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

  Future<bool> importarExcel(String lojaId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null) return false;

      final bytes = result.files.first.bytes;
      List<int> fileBytes;
      if (bytes != null) {
        fileBytes = bytes;
      } else {
        final path = result.files.first.path;
        if (path != null) {
          fileBytes = await File(path).readAsBytes();
        } else {
          throw 'Não foi possível ler o caminho do arquivo';
        }
      }

      var excel = Excel.decodeBytes(fileBytes);
      
      if (excel.tables.isEmpty) throw 'O arquivo Excel não possui planilhas';
      var table = excel.tables.values.first;
      
      if (table.rows.isEmpty) throw 'O arquivo Excel está vazio';

      Map<String, DemandaModel> uniqueDemandas = {};
      int excelDuplicates = 0;

      for (var i = 1; i < table.rows.length; i++) {
        final row = table.rows[i];
        if (row.isEmpty) continue;

        String getVal(int index) {
          if (index >= row.length) return '';
          final cell = row[index];
          if (cell == null || cell.value == null) return '';
          return cell.value.toString().trim();
        }

        final barcode = getVal(0);
        if (barcode.isEmpty) continue;

        if (uniqueDemandas.containsKey(barcode)) {
          excelDuplicates++;
          continue;
        }

        uniqueDemandas[barcode] = DemandaModel(
          id: '',
          barcode: barcode,
          produtoNome: getVal(1),
          produtoMarca: getVal(2),
          produtoDescricao: getVal(3),
          produtoImagemUrl: getVal(4),
          status: 'pendente',
        );
      }

      if (uniqueDemandas.isNotEmpty) {
        int firestoreIgnored = await _repository.importarDemandas(lojaId, uniqueDemandas.values.toList());
        int totalIgnored = excelDuplicates + firestoreIgnored;

        if (totalIgnored > 0) {
          _errorMessage = '$totalIgnored produtos ignorados por duplicidade.';
        }
      } else {
        throw 'Nenhum produto válido encontrado na planilha.';
      }

      return true;
    } catch (e) {
      _errorMessage = 'Erro na importação: $e';
      return false;
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
