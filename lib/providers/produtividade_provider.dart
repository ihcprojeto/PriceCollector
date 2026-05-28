import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'dart:collection';
import '../models/coleta_model.dart';
import '../models/loja_model.dart';
import '../models/demanda_model.dart';
import '../repositories/coleta_repository.dart';
import '../repositories/loja_repository.dart';
import '../repositories/auth_repository.dart';
import '../models/usuario_model.dart';

class UserPerformance {
  final String id;
  final String nome;
  final String matricula;
  final int itensColetados;
  final double velocidadeMedia;
  final Duration tempoMedio;
  final DateTime? ultimaAtividade;

  UserPerformance({
    required this.id,
    required this.nome,
    required this.matricula,
    required this.itensColetados,
    required this.velocidadeMedia,
    required this.tempoMedio,
    this.ultimaAtividade,
  });
}

class StoreProgress {
  final String id;
  final String nome;
  final int coletados;
  final int total;
  double get percentual => total > 0 ? coletados / total : 0;

  StoreProgress({
    required this.id,
    required this.nome,
    required this.coletados,
    required this.total,
  });
}

class DemandaWithStore {
  final DemandaModel demanda;
  final String? lojaId;

  DemandaWithStore(this.demanda, this.lojaId);
}

class ProdutividadeProvider with ChangeNotifier {
  final ColetaRepository _coletaRepo = ColetaRepository();
  final LojaRepository _lojaRepo = LojaRepository();
  final AuthRepository _authRepo = AuthRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  DateTimeRange? _periodo;
  String? _lojaIdFiltro;
  String? _usuarioIdFiltro;

  DateTimeRange? get periodo => _periodo;
  String? get lojaIdFiltro => _lojaIdFiltro;
  String? get usuarioIdFiltro => _usuarioIdFiltro;

  List<ColetaModel> _coletas = [];
  List<LojaModel> _lojas = [];
  List<UsuarioModel> _usuarios = [];
  
  List<UsuarioModel> get usuarios => _usuarios;

  int totalColetados = 0;
  int totalColetadosOperacional = 0;
  int totalPendentes = 0;
  int totalCancelados = 0;
  double percentualConclusao = 0;
  double velocidadeMediaGlobal = 0;
  Duration tempoMedioGlobal = Duration.zero;

  List<UserPerformance> rankingEquipe = [];
  List<StoreProgress> progressoPorLoja = [];
  List<StoreProgress> distribuicaoPorLoja = [];
  Map<DateTime, int> evolucaoTemporal = {};

  void setPeriodo(DateTimeRange? range) {
    _periodo = range;
    carregarDados();
  }

  void setLojaFiltro(String? id) {
    _lojaIdFiltro = id;
    carregarDados();
  }

  void setUsuarioFiltro(String? id) {
    _usuarioIdFiltro = id;
    carregarDados();
  }

  Future<void> carregarDados() async {
    _isLoading = true;
    notifyListeners();

    try {
      try {
        _lojas = await _lojaRepo.getLojasList();
        _usuarios = await _authRepo.getUsuariosList();
      } catch (e) {
        debugPrint('Erro ao buscar bases (lojas/users): $e');
      }

      try {
        _coletas = await _coletaRepo.getColetasList(
          lojaId: _lojaIdFiltro,
        );
      } catch (e) {
        debugPrint('Erro ao buscar coletas: $e');
        _coletas = [];
      }

      var coletasNoPeriodo = _coletas;
      if (_periodo != null) {
        coletasNoPeriodo = coletasNoPeriodo.where((c) {
          try {
            return c.dataColeta.isAfter(_periodo!.start) && 
                   c.dataColeta.isBefore(_periodo!.end.add(const Duration(days: 1)));
          } catch (_) {
            return false;
          }
        }).toList();
      }

      List<DemandaWithStore> todasDemandasComLoja = [];
      
      try {
        if (_lojaIdFiltro != null) {
          final snapshot = await FirebaseFirestore.instance
              .collection('lojas')
              .doc(_lojaIdFiltro)
              .collection('demandas')
              .get();
          todasDemandasComLoja = snapshot.docs.map((d) => 
              DemandaWithStore(DemandaModel.fromFirestore(d.data(), d.id), _lojaIdFiltro)).toList();
        } else {
          try {
            final snapshotDemandas = await FirebaseFirestore.instance.collectionGroup('demandas').get();
            todasDemandasComLoja = snapshotDemandas.docs.map((d) {
              final lojaId = d.reference.parent.parent?.id;
              return DemandaWithStore(DemandaModel.fromFirestore(d.data(), d.id), lojaId);
            }).toList();
          } catch (e) {
            debugPrint('Falha no collectionGroup: $e');
            for (var loja in _lojas) {
              final snapshot = await FirebaseFirestore.instance
                  .collection('lojas')
                  .doc(loja.id)
                  .collection('demandas')
                  .get();
              todasDemandasComLoja.addAll(snapshot.docs.map((d) => 
                  DemandaWithStore(DemandaModel.fromFirestore(d.data(), d.id), loja.id)));
            }
          }
        }
      } catch (e) {
        debugPrint('Erro ao buscar demandas: $e');
      }

      _calcularMetricas(coletasNoPeriodo, todasDemandasComLoja);

    } catch (e) {
      debugPrint('Erro geral no carregarDados: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calcularMetricas(List<ColetaModel> coletasTime, List<DemandaWithStore> demandasComLoja) {
    final coletasUsuario = _usuarioIdFiltro != null 
        ? coletasTime.where((c) => c.usuarioId == _usuarioIdFiltro).toList()
        : coletasTime;

    totalColetados = coletasUsuario.length;
    
    var demandasBase = demandasComLoja;
    if (_lojaIdFiltro != null) {
      demandasBase = demandasBase.where((d) => d.lojaId == _lojaIdFiltro).toList();
    }

    totalCancelados = demandasBase.where((d) => d.demanda.status == 'cancelado').length;
    final totalAtivos = demandasBase.length - totalCancelados;
    
    // O progresso operacional deve ser baseado no status das demandas atuais
    totalColetadosOperacional = demandasBase.where((d) => d.demanda.status == 'coletado').length;
    totalPendentes = totalAtivos - totalColetadosOperacional;
    percentualConclusao = totalAtivos > 0 ? (totalColetadosOperacional / totalAtivos).clamp(0, 1) : 0;

    if (coletasUsuario.isNotEmpty) {
      final coletasPorUsuario = groupBy(coletasUsuario, (ColetaModel c) => c.usuarioId);
      
      int totalSegundosAtivosSessao = 0;

      coletasPorUsuario.forEach((usuarioId, userColetas) {
        final sortedUserColetas = userColetas.sortedBy((c) => c.dataColeta);
        int userSegundosAtivos = 120; 

        for (int i = 0; i < sortedUserColetas.length - 1; i++) {
          final diff = sortedUserColetas[i + 1].dataColeta.difference(sortedUserColetas[i].dataColeta).inSeconds;
          if (diff < 3600) {
            userSegundosAtivos += diff;
          } else {
            userSegundosAtivos += 120;
          }
        }
        totalSegundosAtivosSessao += userSegundosAtivos;
      });

      final double horasAtivasTotal = totalSegundosAtivosSessao / 3600.0;
      velocidadeMediaGlobal = horasAtivasTotal > 0 ? coletasUsuario.length / horasAtivasTotal : 0;
      tempoMedioGlobal = Duration(seconds: (totalSegundosAtivosSessao / coletasUsuario.length).round());
      
    } else {
      velocidadeMediaGlobal = 0;
      tempoMedioGlobal = Duration.zero;
    }

    final grouped = groupBy(coletasUsuario, (ColetaModel c) {
      return DateTime(c.dataColeta.year, c.dataColeta.month, c.dataColeta.day);
    });
    
    evolucaoTemporal = SplayTreeMap<DateTime, int>.from(
      grouped.map((key, value) => MapEntry(key, value.length)),
      (a, b) => a.compareTo(b),
    );

    distribuicaoPorLoja = _lojas.map((loja) {
      final coletadosLoja = coletasUsuario.where((c) => c.lojaId == loja.id).length;
      return StoreProgress(
        id: loja.id!,
        nome: loja.nome,
        coletados: coletadosLoja,
        total: totalColetados,
      );
    }).where((s) => s.coletados > 0).toList();

    final porUsuarioRanking = groupBy(coletasTime, (ColetaModel c) => c.usuarioId);
    
    rankingEquipe = _usuarios.map((u) {
      final userColetas = porUsuarioRanking[u.id] ?? [];
      
      if (userColetas.isEmpty) {
        return UserPerformance(
          id: u.id!,
          nome: u.nome,
          matricula: u.matricula,
          itensColetados: 0,
          velocidadeMedia: 0,
          tempoMedio: Duration.zero,
          ultimaAtividade: null,
        );
      }

      final sortedUserColetas = userColetas.sortedBy((c) => c.dataColeta);
      final userFim = sortedUserColetas.last.dataColeta;
      
      int userSegundosAtivos = 120; 

      for (int i = 0; i < sortedUserColetas.length - 1; i++) {
        final d = sortedUserColetas[i + 1].dataColeta.difference(sortedUserColetas[i].dataColeta).inSeconds;
        if (d < 3600) {
          userSegundosAtivos += d;
        } else {
          userSegundosAtivos += 120;
        }
      }
      
      final double userHoras = userSegundosAtivos / 3600.0;
      final double vel = userHoras > 0 ? userColetas.length / userHoras : 0;

      return UserPerformance(
        id: u.id!,
        nome: u.nome,
        matricula: u.matricula,
        itensColetados: userColetas.length,
        velocidadeMedia: vel,
        tempoMedio: Duration(seconds: (userSegundosAtivos / userColetas.length).round()),
        ultimaAtividade: userFim,
      );
    }).toList()..sort((a, b) => b.itensColetados.compareTo(a.itensColetados));

    progressoPorLoja = _lojas.map((loja) {
      final demandasDaLoja = demandasComLoja.where((d) => d.lojaId == loja.id).toList();
      final coletadosLoja = demandasDaLoja.where((d) => d.demanda.status == 'coletado').length;
      final totalLoja = demandasDaLoja.where((d) => d.demanda.status != 'cancelado').length;
      
      return StoreProgress(
        id: loja.id!,
        nome: loja.nome,
        coletados: coletadosLoja,
        total: totalLoja,
      );
    }).toList();
  }
}
