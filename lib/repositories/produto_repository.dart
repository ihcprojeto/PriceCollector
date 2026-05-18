import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import '../firebase_options.dart';
import '../models/demanda_model.dart';
import '../models/produto_model.dart';

class ProdutoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- MÉTODOS DE PRODUTOS (CATÁLOGO GLOBAL) ---

  Future<List<ProdutoModel>> getTodosProdutos() async {
    final snapshot = await _firestore.collection('produtos').get();
    return snapshot.docs.map((doc) => ProdutoModel.fromFirestore(doc.data())).toList();
  }

  Future<void> excluirProdutoPermanente(String barcode) async {
    final batch = _firestore.batch();

    // 1. Deleta da coleção global
    batch.delete(_firestore.collection('produtos').doc(barcode));

    // 2. Deleta de todas as demandas (subcoleções)
    final lojasSnapshot = await _firestore.collection('lojas').get();
    for (var lojaDoc in lojasSnapshot.docs) {
      batch.delete(lojaDoc.reference.collection('demandas').doc(barcode));
    }

    await batch.commit();
  }

  Future<int> getContagemLojasDoProduto(String barcode) async {
    final snapshot = await _firestore.collectionGroup('demandas')
        .where('barcode', isEqualTo: barcode)
        .get();
    return snapshot.size;
  }

  // --- MÉTODOS DE DEMANDAS ---

  Stream<List<DemandaModel>> getDemandas(String lojaId) {
    return _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DemandaModel.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> atualizarStatusDemanda(String lojaId, String demandaId, String novoStatus) async {
    await _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .doc(demandaId)
        .update({'status': novoStatus});
  }

  Future<void> deletarDemanda(String lojaId, String demandaId) async {
    await _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .doc(demandaId)
        .delete();
  }

  Future<int> importarDemandas(String lojaId, List<DemandaModel> novasDemandas) async {
    // 1. Busca barcodes existentes na loja para evitar duplicidade
    final snapshot = await _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .get();
    
    final existingBarcodes = snapshot.docs.map((doc) => doc.data()['barcode'] as String).toSet();
    
    final demandasCollection = _firestore.collection('lojas').doc(lojaId).collection('demandas');
    final produtosCollection = _firestore.collection('produtos');

    int ignoredCount = 0;
    List<DemandaModel> aImportar = [];

    for (var demanda in novasDemandas) {
      if (existingBarcodes.contains(demanda.barcode)) {
        ignoredCount++;
        continue;
      }
      aImportar.add(demanda);
      existingBarcodes.add(demanda.barcode); // Evita duplicados na própria lista de importação
    }

    if (aImportar.isEmpty) return ignoredCount;

    // 2. Processa em lotes (limite de 500 do Firestore)
    for (var i = 0; i < aImportar.length; i += 500) {
      final batch = _firestore.batch();
      final end = (i + 500 < aImportar.length) ? i + 500 : aImportar.length;
      final chunk = aImportar.sublist(i, end);

      for (var demanda in chunk) {
        // Usa barcode como ID para garantir unicidade estrutural na subcoleção de demandas
        final demandaDocRef = demandasCollection.doc(demanda.barcode);
        batch.set(demandaDocRef, demanda.toMap());

        // Atualiza/Cria na coleção global de produtos
        final produtoDocRef = produtosCollection.doc(demanda.barcode);
        batch.set(produtoDocRef, {
          'barcode': demanda.barcode,
          'descricao': demanda.produtoDescricao,
          'imagemUrl': demanda.produtoImagemUrl,
          'marca': demanda.produtoMarca,
          'nome': demanda.produtoNome,
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }
    
    return ignoredCount;
  }

  Future<DemandaModel?> getDemandaByBarcode(String lojaId, String barcode) async {
    final query = await _firestore
        .collection('lojas')
        .doc(lojaId)
        .collection('demandas')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return DemandaModel.fromFirestore(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  Future<int> getTotalDemandas({String? lojaId}) async {
    if (lojaId != null && lojaId.isNotEmpty) {
      final snapshot = await _firestore
          .collection('lojas')
          .doc(lojaId)
          .collection('demandas')
          .where('status', isNotEqualTo: 'cancelado')
          .get();
      return snapshot.size;
    } else {
      final snapshot = await _firestore
          .collectionGroup('demandas')
          .where('status', isNotEqualTo: 'cancelado')
          .get();
      return snapshot.size;
    }
  }

  // --- MÉTODOS DE MIGRAÇÃO (TEMPORÁRIOS) ---

  /// Percorre todas as demandas de todas as lojas e garante que os produtos 
  /// existam na coleção global 'produtos' sem sobrescrever os existentes.
  Future<Map<String, int>> migrarProdutosDasDemandas() async {
    int adicionados = 0;
    int ignorados = 0;
    int falhas = 0;

    try {
      print('Iniciando migração de produtos das demandas...');

      // 1. Obter todos os produtos globais existentes para evitar sobrescrever
      final produtosSnapshot = await _firestore.collection('produtos').get();
      final Set<String> barcodesGlobais = produtosSnapshot.docs.map((doc) => doc.id).toSet();

      // 2. Coletar produtos únicos das demandas de todas as lojas
      final Map<String, Map<String, dynamic>> novosProdutosMap = {};
      final Set<String> barcodesProcessados = {}; 

      final lojasSnapshot = await _firestore.collection('lojas').get();
      print('Lojas encontradas: ${lojasSnapshot.size}');
      
      for (var lojaDoc in lojasSnapshot.docs) {
        final demandasSnapshot = await lojaDoc.reference.collection('demandas').get();
        
        for (var demandaDoc in demandasSnapshot.docs) {
          final data = demandaDoc.data();
          final barcode = data['barcode'] as String?;
          
          if (barcode == null || barcode.isEmpty) continue;

          // Se já existe no catálogo global, ignoramos
          if (barcodesGlobais.contains(barcode)) {
            if (!barcodesProcessados.contains(barcode)) {
              ignorados++;
              barcodesProcessados.add(barcode);
            }
            continue;
          }

          // Se não está no global e ainda não foi capturado nesta migração, adicionamos para gravar
          if (!novosProdutosMap.containsKey(barcode)) {
            novosProdutosMap[barcode] = {
              'barcode': barcode,
              'descricao': data['produtoDescricao'] ?? '',
              'imagemUrl': data['produtoImagemUrl'] ?? '',
              'marca': data['produtoMarca'] ?? '',
              'nome': data['produtoNome'] ?? '',
            };
          }
        }
      }

      // 3. Salvar os novos produtos em lotes (limite de 500 do Firestore)
      final listaParaGravar = novosProdutosMap.values.toList();
      print('Total de novos produtos a adicionar: ${listaParaGravar.length}');

      for (var i = 0; i < listaParaGravar.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < listaParaGravar.length) ? i + 500 : listaParaGravar.length;
        final chunk = listaParaGravar.sublist(i, end);

        try {
          for (var produto in chunk) {
            final docRef = _firestore.collection('produtos').doc(produto['barcode']);
            batch.set(docRef, produto);
          }
          await batch.commit();
          adicionados += chunk.length;
          print('Lote processado: $adicionados adicionados...');
        } catch (e) {
          print('Erro ao processar lote de migração: $e');
          falhas += chunk.length;
        }
      }

      print('Migração concluída!');
      print('Resumo: Adicionados: $adicionados, Ignorados: $ignorados, Falhas: $falhas');

    } catch (e) {
      print('Erro fatal na migração: $e');
      falhas++;
    }

    return {
      'adicionados': adicionados,
      'ignorados': ignorados,
      'falhas': falhas,
    };
  }
}

/// Função main para permitir execução direta via console (ex: flutter run -t lib/repositories/produto_repository.dart)
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('Inicializando Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final repository = ProdutoRepository();
  final resultado = await repository.migrarProdutosDasDemandas();

  print('-----------------------------------------');
  print('MIGRAÇÃO FINALIZADA');
  print('Novos produtos: ${resultado['adicionados']}');
  print('Produtos ignorados: ${resultado['ignorados']}');
  print('Falhas: ${resultado['falhas']}');
  print('-----------------------------------------');
}
