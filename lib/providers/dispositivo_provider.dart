import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../models/dispositivo_model.dart';
import '../models/coleta_model.dart';
import '../repositories/dispositivo_repository.dart';

class DeviceUsageStats {
  final int totalColetas;
  final DateTime? ultimaAtividade;
  final Map<String, int> coletasPorUsuario; // usuarioId -> count
  final Map<String, String> nomesUsuarios; // usuarioId -> nome
  final Map<String, String> matriculasUsuarios; // usuarioId -> matricula

  DeviceUsageStats({
    required this.totalColetas,
    this.ultimaAtividade,
    required this.coletasPorUsuario,
    required this.nomesUsuarios,
    required this.matriculasUsuarios,
  });
}

class DispositivoProvider with ChangeNotifier {
  final DispositivoRepository _repository = DispositivoRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<DispositivoModel> _allDispositivos = [];
  List<DispositivoModel> _filteredDispositivos = [];
  List<DispositivoModel> get dispositivos => _filteredDispositivos;

  Map<String, DeviceUsageStats> _usageStats = {};
  Map<String, DeviceUsageStats> get usageStats => _usageStats;

  // Métricas de Dashboard
  int totalAtivos = 0;
  int totalInativos = 0;
  String mostUsedDevice = '--';
  int totalOperacoes = 0;

  String _searchQuery = '';
  String _orderBy = 'Utilização (Maior)';

  Future<void> carregarDados() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Buscar todos os dispositivos
      _allDispositivos = await _repository.getAllDispositivos();
      
      // 2. Buscar todas as coletas para consolidar estatísticas
      final allColetas = await _repository.getAllColetas();
      totalOperacoes = allColetas.length;

      // 3. Consolidar estatísticas por dispositivo
      _usageStats = {};
      final coletasPorDisp = groupBy(allColetas, (ColetaModel c) => c.dispositivoId);
      
      for (var entry in coletasPorDisp.entries) {
        final coletas = entry.value;
        final coletasUser = groupBy(coletas, (ColetaModel c) => c.usuarioId);
        
        _usageStats[entry.key] = DeviceUsageStats(
          totalColetas: coletas.length,
          ultimaAtividade: coletas.map((c) => c.dataColeta).maxOrNull,
          coletasPorUsuario: coletasUser.map((key, value) => MapEntry(key, value.length)),
          nomesUsuarios: Map.fromEntries(coletas.map((c) => MapEntry(c.usuarioId, c.usuarioNome))),
          matriculasUsuarios: Map.fromEntries(coletas.map((c) => MapEntry(c.usuarioId, c.usuarioMatricula))),
        );
      }

      // 4. Calcular métricas globais
      totalAtivos = _allDispositivos.where((d) => d.ativo).length;
      totalInativos = _allDispositivos.length - totalAtivos;
      
      final mostUsed = _usageStats.entries.sortedBy<num>((e) => e.value.totalColetas).lastOrNull;
      if (mostUsed != null) {
        final disp = _allDispositivos.firstWhereOrNull((d) => d.id == mostUsed.key);
        mostUsedDevice = disp?.displayName ?? '--';
      }

      _applyFilters();
    } catch (e) {
      _errorMessage = 'Erro ao carregar dispositivos: $e';
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
    _filteredDispositivos = _allDispositivos.where((d) {
      final search = _searchQuery.toLowerCase();
      return d.modelo.toLowerCase().contains(search) ||
             d.marca.toLowerCase().contains(search) ||
             d.serial.toLowerCase().contains(search);
    }).toList();

    // Ordenação
    if (_orderBy == 'Utilização (Maior)') {
      _filteredDispositivos.sort((a, b) {
        final countA = _usageStats[a.id]?.totalColetas ?? 0;
        final countB = _usageStats[b.id]?.totalColetas ?? 0;
        return countB.compareTo(countA);
      });
    } else if (_orderBy == 'Utilização (Menor)') {
      _filteredDispositivos.sort((a, b) {
        final countA = _usageStats[a.id]?.totalColetas ?? 0;
        final countB = _usageStats[b.id]?.totalColetas ?? 0;
        return countA.compareTo(countB);
      });
    } else if (_orderBy == 'Nome A-Z') {
      _filteredDispositivos.sort((a, b) => a.modelo.compareTo(b.modelo));
    }

    notifyListeners();
  }

  Future<void> toggleStatus(String id, bool newStatus) async {
    try {
      await _repository.toggleStatus(id, newStatus);
      // Atualiza localmente para feedback imediato
      final index = _allDispositivos.indexWhere((d) => d.id == id);
      if (index != -1) {
        _allDispositivos[index] = DispositivoModel(
          id: _allDispositivos[index].id,
          marca: _allDispositivos[index].marca,
          modelo: _allDispositivos[index].modelo,
          serial: _allDispositivos[index].serial,
          ativo: newStatus,
        );
        carregarDados(); // Recarrega para atualizar métricas
      }
    } catch (e) {
      _errorMessage = 'Erro ao alterar status: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
