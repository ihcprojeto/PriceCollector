import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  String _orderBy = 'Nome (A-Z)';
  String _statusFilter = 'Todos';
  
  int _totalDemandas = 0;
  int _totalColetados = 0;

  List<ColetaModel> get coletas => _filteredColetas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get progresso {
    if (_totalDemandas == 0) return 0;
    return _totalColetados / _totalDemandas;
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
        List<ColetaModel> coletasComStatus = data;
        
        try {
          _totalDemandas = await _produtoRepository.getTotalDemandas(lojaId: _lojaIdFiltro);
          _totalColetados = await _produtoRepository.getColetadosDemandas(lojaId: _lojaIdFiltro);

          // Verificar se cada coleta ainda possui uma demanda ativa correspondente
          final Set<String> demandasAtivasIds = {};
          if (_lojaIdFiltro != null) {
            final snapshot = await FirebaseFirestore.instance
                .collection('lojas')
                .doc(_lojaIdFiltro)
                .collection('demandas')
                .get();
            demandasAtivasIds.addAll(snapshot.docs.map((d) => d.id));
          } else {
            // Se for global (Minhas Coletas), buscamos por barcode + lojaId pode ser lento
            // mas como é para o usuário logado, geralmente são poucas coletas
            final snapshot = await FirebaseFirestore.instance.collectionGroup('demandas').get();
            demandasAtivasIds.addAll(snapshot.docs.map((d) => '${d.reference.parent.parent?.id}_${d.id}'));
          }

          coletasComStatus = data.map((c) {
            final String key = _lojaIdFiltro != null ? c.produtoBarcode : '${c.lojaId}_${c.produtoBarcode}';
            return c.copyWith(isDemandActive: demandasAtivasIds.contains(key));
          }).toList();

        } catch (e) {
          debugPrint('Aviso: Falha ao carregar metadados das demandas: $e');
          _totalDemandas = 0;
        }

        _coletas = coletasComStatus;
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

  void setStatusFilter(String status) {
    _statusFilter = status;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredColetas = _coletas.where((c) {
      final matchesSearch = c.produtoNome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.marcaProduto.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.produtoBarcode.contains(_searchQuery);
      
      bool matchesStatus = true;
      if (_statusFilter == 'Ativos') {
        matchesStatus = c.isDemandActive != false;
      } else if (_statusFilter == 'Removidos') {
        matchesStatus = c.isDemandActive == false;
      }

      return matchesSearch && matchesStatus;
    }).toList();

    switch (_orderBy) {
      case 'Menor preço':
        _filteredColetas.sort((a, b) => a.preco.compareTo(b.preco));
        break;
      case 'Maior preço':
        _filteredColetas.sort((a, b) => b.preco.compareTo(a.preco));
        break;
      case 'Nome (A-Z)':
        _filteredColetas.sort((a, b) => a.produtoNome.compareTo(b.produtoNome));
        break;
      case 'Nome (Z-A)':
        _filteredColetas.sort((a, b) => b.produtoNome.compareTo(a.produtoNome));
        break;
      case 'Marca (A-Z)':
        _filteredColetas.sort((a, b) => a.marcaProduto.compareTo(b.marcaProduto));
        break;
      case 'Marca (Z-A)':
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
