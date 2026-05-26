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
  final double velocidadeMedia; // itens/hr
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

  // Filtros
  DateTimeRange? _periodo;
  String? _lojaIdFiltro;
  String? _usuarioIdFiltro;

  DateTimeRange? get periodo => _periodo;
  String? get lojaIdFiltro => _lojaIdFiltro;
  String? get usuarioIdFiltro => _usuarioIdFiltro;

  // Dados Agregados
  List<ColetaModel> _coletas = [];
  List<LojaModel> _lojas = [];
  List<UsuarioModel> _usuarios = [];
  
  List<UsuarioModel> get usuarios => _usuarios;

  // Métricas Globais
  int totalColetados = 0;
  int totalPendentes = 0;
  int totalCancelados = 0;
  double percentualConclusao = 0;
  double velocidadeMediaGlobal = 0; // itens/hr
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
      // 1. Buscar todas as lojas e usuários
      try {
        _lojas = await _lojaRepo.getLojasList();
        _usuarios = await _authRepo.getUsuariosList();
      } catch (e) {
        debugPrint('Erro ao buscar bases (lojas/users): $e');
      }

      // 2. Buscar todas as coletas (Ignoramos o filtro de usuário aqui para o Ranking e Pendentes)
      try {
        _coletas = await _coletaRepo.getColetasList(
          lojaId: _lojaIdFiltro,
          // usuarioId: _usuarioIdFiltro, -> Removido para não limitar os dados do ranking
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

      // 3. Buscar Demandas
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
          // Tenta collectionGroup
          try {
            final snapshotDemandas = await FirebaseFirestore.instance.collectionGroup('demandas').get();
            todasDemandasComLoja = snapshotDemandas.docs.map((d) {
              final lojaId = d.reference.parent.parent?.id;
              return DemandaWithStore(DemandaModel.fromFirestore(d.data(), d.id), lojaId);
            }).toList();
          } catch (e) {
            debugPrint('Falha no collectionGroup: $e');
            // Fallback: iterar lojas
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

      // 4. Calcular Métricas
      _calcularMetricas(coletasNoPeriodo, todasDemandasComLoja);

    } catch (e) {
      debugPrint('Erro geral no carregarDados: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calcularMetricas(List<ColetaModel> coletasTime, List<DemandaWithStore> demandasComLoja) {
    // Coletas do usuário específico para os cards de resumo
    final coletasUsuario = _usuarioIdFiltro != null 
        ? coletasTime.where((c) => c.usuarioId == _usuarioIdFiltro).toList()
        : coletasTime;

    totalColetados = coletasUsuario.length;
    
    // Filtragem de demandas de acordo com os filtros globais (lojaId)
    var demandasBase = demandasComLoja;
    if (_lojaIdFiltro != null) {
      demandasBase = demandasBase.where((d) => d.lojaId == _lojaIdFiltro).toList();
    }

    totalCancelados = demandasBase.where((d) => d.demanda.status == 'cancelado').length;
    final totalAtivos = demandasBase.length - totalCancelados;
    
    // Pendentes e Conclusão são calculados com base no progresso do TIME
    totalPendentes = totalAtivos - coletasTime.length;
    percentualConclusao = totalAtivos > 0 ? (coletasTime.length / totalAtivos).clamp(0, 1) : 0;

    // Cálculo de Velocidade e Tempo Médio (Respeita o filtro de usuário nos cards superiores)
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

    // Evolução Temporal (Agrupado por dia - Mantemos do TIME ou filtramos pelo USUÁRIO)
    // Para manter consistência com o resumo, vamos filtrar a evolução pelo usuário também
    final grouped = groupBy(coletasUsuario, (ColetaModel c) {
      return DateTime(c.dataColeta.year, c.dataColeta.month, c.dataColeta.day);
    });
    
    evolucaoTemporal = SplayTreeMap<DateTime, int>.from(
      grouped.map((key, value) => MapEntry(key, value.length)),
      (a, b) => a.compareTo(b),
    );

    // Distribuição por Loja (Respeita o filtro de usuário para o gráfico de pizza)
    distribuicaoPorLoja = _lojas.map((loja) {
      final coletadosLoja = coletasUsuario.where((c) => c.lojaId == loja.id).length;
      return StoreProgress(
        id: loja.id!,
        nome: loja.nome,
        coletados: coletadosLoja,
        total: totalColetados,
      );
    }).where((s) => s.coletados > 0).toList();

    // Ranking Equipe (SEMPRE usa coletasTime, ignorando o filtro de usuário)
    final porUsuarioRanking = groupBy(coletasTime, (ColetaModel c) => c.usuarioId);
    
    // Calculamos a média de velocidade do TIME para comparação no ranking
    double mediaVelocidadeTime = 0;
    if (coletasTime.isNotEmpty) {
      int segAtivosTime = 0;
      final porUser = groupBy(coletasTime, (ColetaModel c) => c.usuarioId);
      porUser.forEach((_, list) {
         final sorted = list.sortedBy((c) => c.dataColeta);
         segAtivosTime += 120;
         for(int i=0; i<sorted.length-1; i++) {
           final d = sorted[i+1].dataColeta.difference(sorted[i].dataColeta).inSeconds;
           segAtivosTime += (d < 3600) ? d : 120;
         }
      });
      mediaVelocidadeTime = (segAtivosTime > 0) ? coletasTime.length / (segAtivosTime / 3600.0) : 0;
    }

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

    // Progresso por Loja (Baseado no TIME)
    progressoPorLoja = _lojas.map((loja) {
      final coletadosLoja = coletasTime.where((c) => c.lojaId == loja.id).length;
      final totalLoja = demandasComLoja.where((d) => d.lojaId == loja.id && d.demanda.status != 'cancelado').length;
      
      return StoreProgress(
        id: loja.id!,
        nome: loja.nome,
        coletados: coletadosLoja,
        total: totalLoja,
      );
    }).toList();
  }
}
