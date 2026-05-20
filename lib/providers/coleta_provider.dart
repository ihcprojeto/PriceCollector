import 'dart:async';
import 'package:flutter/material.dart';
import '../models/coleta_model.dart';
import '../repositories/coleta_repository.dart';
import '../repositories/produto_repository.dart';

class ColetaProvider with ChangeNotifier {
  final ColetaRepository _coletaRepository = ColetaRepository();
  final ProdutoRepository _produtoRepository = ProdutoRepository();

  List<ColetaModel> _coletas = [];
  List<ColetaModel> _filteredColetas = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  String? _lojaIdFiltro;
  String? _usuarioIdFiltro;
  String _searchQuery = '';
  String _orderBy = 'Nome A-Z';
  
  int _totalDemandas = 0;

  List<ColetaModel> get coletas => _filteredColetas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get progresso {
    if (_totalDemandas == 0) return 0;
    return _coletas.length / _totalDemandas;
  }

  StreamSubscription<List<ColetaModel>>? _subscription;

  void fetchColetas({String? lojaId, String? usuarioId}) {
    _lojaIdFiltro = lojaId;
    _usuarioIdFiltro = usuarioId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _coletaRepository.getColetas(lojaId: _lojaIdFiltro, usuarioId: _usuarioIdFiltro).listen((data) async {
      try {
        _coletas = data;
        
        try {
          // Tenta buscar o total, mas não trava o fluxo se falhar (ex: falta de índice)
          _totalDemandas = await _produtoRepository.getTotalDemandas(lojaId: _lojaIdFiltro);
        } catch (e) {
          debugPrint('Aviso: Falha ao calcular total de demandas (provavelmente falta de índice): $e');
          _totalDemandas = 0; // Define como 0 para não quebrar o cálculo do progresso
        }

        _applyFiltersAndSort();
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _errorMessage = 'Erro ao processar listagem: $e';
        _isLoading = false;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('ColetaProvider Error (Stream): $e');
      _errorMessage = 'Erro ao carregar coletas: $e';
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void setLojaFiltro(String? lojaId) {
    _lojaIdFiltro = lojaId;
    fetchColetas(lojaId: _lojaIdFiltro, usuarioId: _usuarioIdFiltro);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  void setOrderBy(String order) {
    _orderBy = order;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredColetas = _coletas.where((c) {
      final matchesSearch = c.produtoNome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.marcaProduto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.produtoBarcode.contains(_searchQuery);
      return matchesSearch;
    }).toList();

    switch (_orderBy) {
      case 'Preço: Menor ao Maior':
        _filteredColetas.sort((a, b) => a.preco.compareTo(b.preco));
        break;
      case 'Preço: Maior ao Menor':
        _filteredColetas.sort((a, b) => b.preco.compareTo(a.preco));
        break;
      case 'Nome A-Z':
        _filteredColetas.sort((a, b) => a.produtoNome.compareTo(b.produtoNome));
        break;
      case 'Nome Z-A':
        _filteredColetas.sort((a, b) => b.produtoNome.compareTo(a.produtoNome));
        break;
      case 'Marca A-Z':
        _filteredColetas.sort((a, b) => a.marcaProduto.compareTo(b.marcaProduto));
        break;
      case 'Marca Z-A':
        _filteredColetas.sort((a, b) => b.marcaProduto.compareTo(a.marcaProduto));
        break;
    }
    notifyListeners();
  }

  Future<void> excluirColeta(ColetaModel coleta) async {
    try {
      await _coletaRepository.excluirColeta(coleta.id!, coleta.lojaId, coleta.produtoBarcode);
    } catch (e) {
      _errorMessage = 'Erro ao excluir coleta: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
